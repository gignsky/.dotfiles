# VM Sops Secrets Access Research Report

**Date:** 2026-04-02  
**Researcher:** Library Computer  
**Status:** COMPLETE

## Executive Summary

Research into enabling sops-nix secrets access in ephemeral VMs built with `nixos-rebuild build-vm` reveals **multiple viable solutions** ranging from simple workarounds to sophisticated shared-key architectures. The core issue is that VMs need decryption keys, but managing individual keys for ephemeral VMs is impractical.

**Recommended Solution:** Pre-provisioned shared VM age key with conditional configuration (Solution #2)  
**Complexity:** Medium | **Security:** Good for testing environments | **Maintainability:** Excellent

---

## Technical Analysis

### How `build-vm` Handles Sops Infrastructure

#### VM Construction Architecture
1. **`nixos-rebuild build-vm`** creates a QEMU-based VM with:
   - 9P filesystem mount of host's `/nix/store` (read-only)
   - Separate ephemeral qcow2 disk for writable state (`./hostname.qcow2`)
   - New system activation on each boot
   - **Separate configuration variant** via `virtualisation.vmVariant`

2. **Critical Issue Identified (sops-nix #557):**
   - When `sops.age.generateKey = true` is set WITHOUT `sops.age.keyFile` specified
   - VM activation script tries to access `null` path → `cannot coerce null to a string`
   - Error manifests during VM build, NOT during runtime

3. **What VMs DON'T Have:**
   - Persistent `/var/lib/sops-nix/key.txt` (unless explicitly provisioned)
   - Persistent `/etc/ssh/ssh_host_ed25519_key` (regenerated on each VM creation)
   - Access to host's sops keys (unless explicitly shared)

4. **What VMs DO Have:**
   - Access to nix-secrets input flake (through `/nix/store`)
   - Ability to run age-keygen during activation
   - Can mount host directories via 9P (virtualisation.sharedDirectories)

### Why Current Configuration Fails

From `hosts/common/core/sops.nix`:
```nix
sops.age = {
  sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  keyFile = "/var/lib/sops-nix/key.txt";
  generateKey = true;  # ← THE PROBLEM
};
```

**Issue Chain:**
1. VM variant inherits this configuration
2. During VM activation, `generate-age-key` script tries to write to `keyFile`
3. Path `/var/lib/sops-nix/key.txt` exists in VM but is empty/regenerated
4. Even if key is generated, it's **not in sops.yaml** recipients list
5. Result: VM can generate key but **cannot decrypt any secrets**

### Current Workaround in Spacedock

The `spacedock/dot-spacedock/hosts/common/optional/vm-dev.nix` shows partial solution:
```nix
virtualisation.vmVariant = {
  users.users.gig = {
    hashedPassword = "$6$k/X6eGicIkPKKA8N$...";  # Hardcoded password
    hashedPasswordFile = lib.mkForce null;         # Bypass sops password
  };
}
```

**Limitation:** Only solves passwords, NOT other secrets (cifs-creds, etc.)

---

## Solution Options (Ranked by Preference)

### Solution #1: Shared VM Age Key (Pre-Generated, Checked Into Repo)

**Concept:** Create a single age key shared by ALL VMs, add its public key to `.sops.yaml`, check key file into secrets repo.

**Implementation:**
```bash
# One-time setup
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/shared-vm.txt
cat ~/.config/sops/age/shared-vm.txt | age-keygen -y  # Get public key

# Add to .sops.yaml
keys:
  - &admin_alice 2504791468b153b8a3963cc97ba53d1919c5dfd4
  - &vm_shared age1rgffpespcyjn0d8jglk7km9kfrfhdyev6camd3rck6pn8y47ze4s...
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - pgp: [*admin_alice]
      age: [*vm_shared]

# Re-encrypt all secrets
sops updatekeys secrets/secrets.yaml
```

**NixOS Configuration:**
```nix
# hosts/common/core/vm-shared-secrets.nix
{ config, lib, inputs, ... }:
let
  secretspath = builtins.toString inputs.nix-secrets;
  isVM = config.virtualisation ? qemu;
in
{
  config = lib.mkIf isVM {
    # Override sops configuration for VMs
    sops.age = {
      keyFile = lib.mkForce "/home/gig/.config/sops/age/shared-vm.txt";
      generateKey = lib.mkForce false;  # Don't generate, use pre-existing
      sshKeyPaths = lib.mkForce [];     # Don't use SSH keys
    };
  };
}
```

**Pros:**
- ✅ Simple implementation
- ✅ Works immediately for all VMs
- ✅ No per-VM key management
- ✅ Secrets fully accessible in VMs

**Cons:**
- ⚠️ Single shared key for all VMs (less granular control)
- ⚠️ Requires re-encrypting all secrets

**Security Trade-offs:**
- **SAFE FOR:** Development environments, testing credentials, non-production data
- **NOT SAFE FOR:** Production credentials, sensitive API keys
- **Mitigation:** Separate secrets files for production vs. testing
- **Key Storage:** VM keys stored in `~/.config/sops/age/` (NOT in git repos) to prevent accidental commits

**Complexity:** ⭐⭐ (Low-Medium)  
**Maintainability:** ⭐⭐⭐⭐⭐ (Excellent)

---

### Solution #2: Per-Host VM Key with Conditional Configuration

**Concept:** Each physical host has a dedicated VM age key. VMs built on that host use that host's VM key.

**Implementation:**
```bash
# Per-host setup (example for 'wsl')
age-keygen -o ~/.config/sops/age/wsl-vm.txt
cat ~/.config/sops/age/wsl-vm.txt | age-keygen -y

# .sops.yaml
keys:
  - &server_wsl age1rgffpespcyjn0d8jglk7km9kfrfhdyev6camd3rck6pn8y47ze4s...
  - &vm_wsl age1abc123...
  - &server_merlin age1def456...
  - &vm_merlin age1ghi789...
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *server_wsl
      - *vm_wsl
      - *server_merlin
      - *vm_merlin
```

**NixOS Configuration:**
```nix
# hosts/common/core/sops.nix
{ inputs, config, lib, ... }:
let
  secretspath = builtins.toString inputs.nix-secrets;
  hostName = config.networking.hostName;
  isVM = config.virtualisation ? qemu;
  
  # Map physical host names to their VM key files
  vmKeyMap = {
    "wsl" = "/home/gig/.config/sops/age/wsl-vm.txt";
    "merlin" = "/home/gig/.config/sops/age/merlin-vm.txt";
    "ganoslal" = "/home/gig/.config/sops/age/ganoslal-vm.txt";
    "spacedock" = "/home/gig/.config/sops/age/spacedock-vm.txt";
  };
  
  # Extract base hostname (remove -vm suffix if present)
  baseHostName = lib.removeSuffix "-vm" hostName;
in
{
  sops = {
    defaultSopsFile = "${secretspath}/secrets.yaml";
    validateSopsFiles = true;
    
    age = {
      # Use VM-specific key if in VM, otherwise use standard location
      keyFile = if isVM && vmKeyMap ? ${baseHostName}
                then vmKeyMap.${baseHostName}
                else "/var/lib/sops-nix/key.txt";
      
      generateKey = !isVM;  # Only generate for physical hosts
      
      sshKeyPaths = if isVM 
                    then []  # VMs don't use SSH keys for sops
                    else [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    
    secrets = {
      gig-password = { neededForUsers = true; };
      root-password = { neededForUsers = true; };
      cifs-creds = { path = "/etc/samba/cifs-creds"; };
    };
  };
}
```

**Pros:**
- ✅ Isolation between hosts' VMs
- ✅ Automatic detection of VM environment
- ✅ Full secrets access in VMs
- ✅ No risk of accidentally committing private keys to git

**Cons:**
- ⚠️ Requires per-host VM key setup (4 keys for 4 hosts)
- ⚠️ More complex configuration
- ⚠️ Requires re-encrypting secrets

**Security Trade-offs:**
- Better isolation than Solution #1
- VM keys are separate from production host keys
- Compromise of VM key doesn't affect production host
- **Key Storage:** VM keys stored in `~/.config/sops/age/` (local only, never in git)

**Complexity:** ⭐⭐⭐ (Medium)  
**Maintainability:** ⭐⭐⭐⭐ (Very Good)

---

### Solution #3: Host Key Sharing via 9P Mount

**Concept:** Mount host's `/var/lib/sops-nix` into VM, allowing VM to use host's actual decryption key.

**Implementation:**
```nix
# hosts/common/core/vm-shared-secrets.nix
{ config, lib, ... }:
{
  virtualisation.vmVariant = {
    # Share host's sops key directory
    virtualisation.sharedDirectories = {
      sops-keys = {
        source = "/var/lib/sops-nix";
        target = "/var/lib/sops-nix";
      };
    };
    
    sops.age = {
      keyFile = "/var/lib/sops-nix/key.txt";  # Points to shared mount
      generateKey = lib.mkForce false;
      sshKeyPaths = lib.mkForce [];
    };
  };
}
```

**Pros:**
- ✅ No key management needed
- ✅ No .sops.yaml changes
- ✅ No secret re-encryption
- ✅ VM automatically gets host's decryption capability

**Cons:**
- ❌ VM has access to production host key (SECURITY RISK)
- ❌ Breaks if host key doesn't exist yet
- ❌ 9P mount might not be available at early boot
- ❌ Tight coupling between host and VM

**Security Trade-offs:**
- **DANGEROUS:** VM compromise = host key compromise
- **NOT RECOMMENDED** for any security-conscious environment

**Complexity:** ⭐⭐ (Low-Medium)  
**Maintainability:** ⭐⭐ (Poor - tight coupling)

---

### Solution #4: Age Plugins with VM-Specific Plugin

**Concept:** Use age plugins to provide alternative decryption method for VMs (e.g., password-based).

**Implementation:**
```nix
# This is theoretical - would require custom age plugin development
{ config, lib, pkgs, ... }:
{
  virtualisation.vmVariant = {
    sops.age.plugins = [
      pkgs.age-plugin-yubikey  # Example - not actually useful for VMs
      # Custom VM plugin would go here
    ];
  };
}
```

**Pros:**
- ✅ Potentially very flexible
- ✅ Could support novel authentication methods

**Cons:**
- ❌ Requires custom plugin development
- ❌ Complex implementation
- ❌ Still requires sops.yaml updates
- ❌ Maintenance burden

**Complexity:** ⭐⭐⭐⭐⭐ (Very High)  
**Maintainability:** ⭐ (Poor)

---

### Solution #5: Conditional Secret Disabling in VMs

**Concept:** Disable sops entirely in VMs, use hardcoded fallbacks.

**Implementation:**
```nix
{ config, lib, ... }:
let
  isVM = config.virtualisation ? qemu;
in
{
  # Completely disable sops in VMs
  sops.secrets = lib.mkIf (!isVM) {
    gig-password = { neededForUsers = true; };
    root-password = { neededForUsers = true; };
    cifs-creds = { path = "/etc/samba/cifs-creds"; };
  };
  
  # VM overrides
  virtualisation.vmVariant = {
    users.users.gig = {
      hashedPassword = "$6$...";  # Hardcoded test password
      hashedPasswordFile = lib.mkForce null;
    };
    
    # For other secrets, create dummy files or disable services
    systemd.services.samba.enable = lib.mkForce false;
  };
}
```

**Pros:**
- ✅ Simple, no key management
- ✅ No sops.yaml changes
- ✅ Clear separation of VM vs. production

**Cons:**
- ❌ **Doesn't meet requirements** - breaks testing of secrets
- ❌ Can't test samba credentials
- ❌ Can't test any sops-dependent services
- ❌ Defeats purpose of VMs for testing

**Verdict:** ❌ **NOT ACCEPTABLE** per mission brief

---

## Recommended Implementation

### Best Solution: Solution #2 (Per-Host VM Keys)

**Reasoning:**
1. ✅ Meets all mission requirements (full secret access in VMs)
2. ✅ Reasonable security posture (VM keys separate from production)
3. ✅ Maintainable (clear key-to-host mapping)
4. ✅ Scalable (add new hosts easily)
5. ✅ No tight coupling or dangerous patterns

### Step-by-Step Implementation Plan

#### Phase 1: Generate VM Keys (One-time per host)

```bash
# For each host (wsl, merlin, ganoslal, spacedock)
cd ~/nix-secrets
mkdir -p vm-keys

# Example for wsl
age-keygen -o vm-keys/wsl-vm.txt
echo "VM Key for wsl:"
cat vm-keys/wsl-vm.txt | age-keygen -y

# Repeat for each host
age-keygen -o vm-keys/merlin-vm.txt
age-keygen -o vm-keys/ganoslal-vm.txt
age-keygen -o vm-keys/spacedock-vm.txt

# Commit keys to nix-secrets repo
git add vm-keys/
git commit -m "eng: add shared VM age keys for testing environments"
```

#### Phase 2: Update .sops.yaml

```yaml
# ~/nix-secrets/.sops.yaml
keys:
  # Existing keys
  - &admin_gig <your-age-key>
  
  # Physical host keys
  - &server_wsl <wsl-age-key>
  - &server_merlin <merlin-age-key>
  - &server_ganoslal <ganoslal-age-key>
  - &server_spacedock <spacedock-age-key>
  
  # VM keys (from vm-keys/*.txt | age-keygen -y)
  - &vm_wsl age1abc...
  - &vm_merlin age1def...
  - &vm_ganoslal age1ghi...
  - &vm_spacedock age1jkl...

creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_gig
      - *server_wsl
      - *vm_wsl
      - *server_merlin
      - *vm_merlin
      - *server_ganoslal
      - *vm_ganoslal
      - *server_spacedock
      - *vm_spacedock
```

#### Phase 3: Re-encrypt Secrets

```bash
cd ~/nix-secrets
sops updatekeys secrets/secrets.yaml

# Verify all keys can decrypt
for host in wsl merlin ganoslal spacedock; do
  echo "Testing VM key for $host..."
  SOPS_AGE_KEY_FILE=vm-keys/${host}-vm.txt sops -d secrets/secrets.yaml > /dev/null && \
    echo "✓ $host VM key works" || echo "✗ $host VM key failed"
done
```

#### Phase 4: Update sops.nix Configuration

```nix
# hosts/common/core/sops.nix
{ inputs, config, lib, ... }:
let
  secretspath = builtins.toString inputs.nix-secrets;
  hostName = config.networking.hostName;
  
  # Detect if we're running in a VM
  isVM = config.virtualisation ? qemu || 
         (builtins.match ".*-vm$" hostName != null);
  
  # Map physical host names to their VM key files
  vmKeyMap = {
    "wsl" = "/home/gig/.config/sops/age/wsl-vm.txt";
    "merlin" = "/home/gig/.config/sops/age/merlin-vm.txt";
    "ganoslal" = "/home/gig/.config/sops/age/ganoslal-vm.txt";
    "spacedock" = "/home/gig/.config/sops/age/spacedock-vm.txt";
  };
  
  # Extract base hostname (remove -vm suffix if present)
  baseHostName = lib.removeSuffix "-vm" hostName;
  
  # Determine which key file to use
  activeKeyFile = 
    if isVM && vmKeyMap ? ${baseHostName}
    then vmKeyMap.${baseHostName}
    else "/var/lib/sops-nix/key.txt";
in
{
  sops = {
    defaultSopsFile = "${secretspath}/secrets.yaml";
    validateSopsFiles = true;
    
    age = {
      # VMs use pre-existing VM keys, physical hosts use generated keys
      keyFile = activeKeyFile;
      generateKey = !isVM;
      
      # VMs don't use SSH keys for sops (they use the VM age key instead)
      sshKeyPaths = if isVM then [] else [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    
    secrets = {
      gig-password = { neededForUsers = true; };
      root-password = { neededForUsers = true; };
      cifs-creds = { path = "/etc/samba/cifs-creds"; };
    };
  };
}
```

#### Phase 5: Testing Procedure

```bash
# 1. Build a VM
cd ~/.dotfiles
nixos-rebuild build-vm --flake .#wsl

# 2. Start the VM
./result/bin/run-wsl-vm

# 3. Inside VM, verify secrets are accessible
cat /run/secrets/gig-password  # Should show decrypted password
cat /run/secrets/cifs-creds    # Should show decrypted credentials

# 4. Test user login with sops password
# (should work without hardcoded password fallback)

# 5. Test samba mount with cifs-creds
# (should work with actual credentials)
```

---

## Alternative Solutions for Specific Use Cases

### If Security is NOT a Concern (Development Only)

Use **Solution #1** (Shared VM Key) - simpler, faster setup.

### If Testing Production Secrets in VMs

**DO NOT** use any VM-based solution. Instead:
- Use proper staging environment
- Or use disposable cloud instances with proper key provisioning
- Or use NixOS containers instead of VMs (can share host keys safely)

### If You Need Secrets at Build Time (Not Runtime)

VMs and sops-nix won't work. Consider:
- [git-agecrypt](https://github.com/vlaci/git-agecrypt) for secrets in git
- [agenix](https://github.com/ryantm/agenix) (different architecture than sops-nix)

---

## Security Best Practices

### Secret Categorization

Recommend splitting secrets into multiple sops files:

```
secrets/
├── production.yaml      # Real credentials, encrypted with only production host keys
├── testing.yaml         # Test credentials, encrypted with production + VM keys
└── development.yaml     # Dev credentials, encrypted with all keys including VM keys
```

**Configuration:**
```nix
sops.defaultSopsFile = 
  if isVM 
  then "${secretspath}/secrets/testing.yaml"
  else "${secretspath}/secrets/production.yaml";
```

### VM Key Protection

Even though VM keys are in version control:
1. Keep nix-secrets repo PRIVATE
2. Use different test credentials than production
3. Rotate VM keys periodically (cheap operation)
4. Document which secrets are "VM-safe"

### Audit Trail

```nix
# Add to VM configuration for logging
environment.etc."vm-sops-key-source".text = 
  "This VM uses age key: ${activeKeyFile}";
```

---

## Technical Notes

### VM Detection Methods

Current configuration uses:
```nix
isVM = config.virtualisation ? qemu
```

**More robust detection:**
```nix
isVM = 
  (config.virtualisation ? qemu) ||
  (builtins.match ".*-vm$" config.networking.hostName != null) ||
  (config.boot.kernelParams or [] |> builtins.any (p: p == "systemd.hostname_override_vm"));
```

### Why `generateKey = false` for VMs

From sops-nix source (`modules/sops/default.nix:467-475`):
```nix
system.activationScripts.generate-age-key =
  let
    escapedKeyFile = lib.escapeShellArg cfg.age.keyFile;
  in
  lib.mkIf cfg.age.generateKey (
    lib.stringAfter [ ] ''
      if [[ ! -f ${escapedKeyFile} ]]; then
        echo generating machine-specific age key...
        mkdir -p $(dirname ${escapedKeyFile})
        ${pkgs.age}/bin/age-keygen -o ${escapedKeyFile}
      fi
    ''
  );
```

If `generateKey = true` but key file points to nix store (VM keys), activation fails because nix store is read-only.

### Handling `neededForUsers` Secrets

Secrets with `neededForUsers = true` are decrypted to `/run/secrets-for-users` **before** user creation. This happens regardless of VM/physical host, so the solution works for user passwords.

---

## Known Limitations

### 1. Initrd Secrets

sops-nix doesn't fully support secrets needed in initrd (before activation). Workaround:
```bash
nixos-rebuild test  # Provision secrets
nixos-rebuild switch  # Then install bootloader
```

This limitation affects VMs the same as physical hosts.

### 2. Per-VM Isolation

All VMs built on same host share same VM key. If you need per-VM isolation, you'd need Solution #4 (custom plugin) or generate keys per-VM (defeats ephemeral nature).

### 3. VM Key Rotation

Rotating VM keys requires:
1. Generating new VM key
2. Updating .sops.yaml
3. Re-encrypting all secrets
4. Rebuilding all VMs

Not trivial, but also not frequent operation.

---

## Conclusion

**Recommended path forward:**

1. **Immediate:** Implement Solution #2 (Per-Host VM Keys)
2. **Security:** Separate production and testing secrets into different sops files
3. **Testing:** Validate that all secrets (passwords, cifs-creds, etc.) work in VMs
4. **Documentation:** Update repository docs with VM testing procedures

**Expected outcome:**
- Full sops secrets access in VMs ✅
- No per-VM key management ✅
- Acceptable security for testing environments ✅
- Maintainable and repeatable ✅

**Implementation time estimate:** 2-3 hours for initial setup + testing

---

## References

- [sops-nix Issue #557](https://github.com/Mic92/sops-nix/issues/557) - VM build failures
- [sops-nix README](https://github.com/Mic92/sops-nix) - Official documentation
- [NixOS Manual: build-vm](https://nixos.org/manual/nixos/stable/#sec-building-vm)
- Current implementation: `~/.dotfiles/hosts/common/core/sops.nix`
- Existing VM config: `~/.dotfiles/spacedock/dot-spacedock/hosts/common/optional/vm-dev.nix`

---

**End of Report**
