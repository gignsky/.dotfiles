# Security Analysis: Secrets Injection in NixOS VMs
**Date:** 2026-04-10  
**Analyst:** OpenCode Security Analysis Agent  
**Status:** COMPLETE  
**Classification:** Technical Security Assessment

---

## Executive Summary

This report analyzes the security implications of injecting host secrets into NixOS VMs built with `nixos-rebuild build-vm`. The analysis examines both the **currently implemented approach** (per-host VM age keys embedded via `environment.etc`) and potential alternatives.

**Key Findings:**
- ✅ **Current Implementation**: Reasonably secure for development/testing use cases
- ⚠️ **Nix Store Risk**: Significant - secrets in `/nix/store` become world-readable
- ⚠️ **Upstream Acceptance**: Unlikely without strong security controls
- ✅ **Mitigation Possible**: With proper implementation boundaries and documentation

**Recommendation:** Current implementation is acceptable for **local testing only**. Should NOT be submitted to nixpkgs upstream without substantial security hardening.

---

## 1. Threat Model

### 1.1 Actors and Access Levels

| Actor | Trust Level | Capabilities | Threat Potential |
|-------|-------------|--------------|------------------|
| **Physical Host Owner** | Trusted | Full system access, secret generation | Low (legitimate user) |
| **VM Guest Process** | Untrusted | Confined by QEMU, can read mounted filesystems | **HIGH** (malicious code in VM) |
| **Multi-User Host Users** | Semi-trusted | Can read `/nix/store`, may access running VMs | **MEDIUM** (local privilege escalation) |
| **Remote Attacker** | Untrusted | May compromise VM through network vulnerabilities | **HIGH** (lateral movement to host) |
| **Nix Build Process** | Semi-trusted | Reads config, builds derivations, no secret access at build time | **MEDIUM** (if compromised) |

### 1.2 Assets Being Protected

1. **Production Secrets** - Passwords, API keys, certificates (HIGH VALUE)
2. **Test Credentials** - Development database passwords (MEDIUM VALUE)
3. **VM Age Keys** - Encryption keys for VM secret decryption (MEDIUM VALUE)
4. **Host Age Keys** - Production host encryption keys (CRITICAL VALUE)
5. **Encrypted Secret Files** - SOPS-encrypted YAML files (LOW VALUE - already encrypted)

### 1.3 Trust Boundaries

```
┌─────────────────────────────────────────────────────────┐
│                     PHYSICAL HOST                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │  /nix/store (WORLD-READABLE)                     │  │ ← CRITICAL BOUNDARY
│  │  - Contains all derivations                      │  │
│  │  - Must NEVER contain secrets directly           │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  /home/gig/.config/sops/age/ (USER-RESTRICTED)   │  │ ← PROTECTED
│  │  - VM age keys (mode 0600)                       │  │
│  │  - Production age keys                           │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │           QEMU VM PROCESS                      │    │ ← TRUST BOUNDARY
│  │  ┌──────────────────────────────────────────┐  │    │
│  │  │  /etc/sops/age/vm-key.txt (mode 0400)    │  │    │ ← EVALUATED AT BUILD
│  │  │  Contains: builtins.readFile (host key)  │  │    │
│  │  └──────────────────────────────────────────┘  │    │
│  │                                                │    │
│  │  /nix/store (read-only mount via virtiofs)    │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

**Critical Observation:** The VM age key content is evaluated at **build time** using `builtins.readFile`, which means the key content **enters the Nix store** as part of the `/etc/sops/age/vm-key.txt` file creation.

---

## 2. Security Risk Analysis

### 2.1 CRITICAL: Secrets in /nix/store (Severity: **HIGH**)

#### Risk Description
The current implementation uses:
```nix
environment.etc."sops/age/vm-key.txt" = {
  mode = "0400";
  text = builtins.readFile vmKeyMap.${baseHostName};
};
```

**Problem:** `builtins.readFile` evaluates at **build time**, causing the VM age key content to be embedded in the derivation, which is stored in `/nix/store`.

#### Attack Vectors

**Vector 1: Multi-User Host Exposure**
```bash
# Any user on the host can read the VM key from the store
$ find /nix/store -name "etc-sops-age-vm*" -type f
/nix/store/abc123-etc-sops-age-vm-key.txt/sops/age/vm-key.txt

$ cat /nix/store/abc123-etc-sops-age-vm-key.txt/sops/age/vm-key.txt
# AGE-SECRET-KEY-XXXXXXXXX... ← EXPOSED!
```

**Vector 2: Binary Cache Leakage**
If the NixOS configuration is built by Hydra or another binary cache service, the VM age key content **may be uploaded to the binary cache**, making it publicly accessible.

**Vector 3: Nix Store Garbage Collection Delay**
Even after removing the VM configuration, the derivation containing the key remains in `/nix/store` until garbage collection runs. This provides a window for unauthorized access.

**Vector 4: Git Repository Contamination**
If a developer accidentally runs:
```bash
nix build .#nixosConfigurations.merlin.config.system.build.etc
# Result symlink points to /nix/store with embedded key
git add result  # ← ACCIDENTALLY COMMITS SYMLINK POINTING TO STORE
```

While the symlink itself doesn't leak the key, it reveals the store path structure.

#### Exploitation Scenario

1. **Attacker gains local user access** to the physical host (via SSH, compromised service, etc.)
2. **Searches /nix/store** for files matching `vm-key.txt` pattern
3. **Extracts VM age key** from world-readable store file
4. **Clones nix-secrets repository** (if accessible or leaked)
5. **Decrypts all VM-accessible secrets** using stolen VM age key
6. **Lateral movement:** Uses decrypted credentials to access other systems

**CVSS Score Estimate:** 7.8 (HIGH)
- Attack Vector: Local (AV:L)
- Attack Complexity: Low (AC:L)
- Privileges Required: Low (PR:L)
- User Interaction: None (UI:N)
- Scope: Unchanged (S:U)
- Confidentiality: High (C:H)
- Integrity: High (I:H)
- Availability: High (A:H)

### 2.2 VM Escape to Host (Severity: **MEDIUM**)

#### Risk Description
If a malicious actor compromises the VM environment, could they access the host's secrets?

#### Current Mitigations
✅ **QEMU Isolation:** Strong hardware virtualization boundary  
✅ **Read-Only Nix Store:** VM cannot modify host `/nix/store`  
✅ **No Direct Host Key Access:** VM does NOT have access to `/var/lib/sops-nix/key.txt` (host's production key)  
✅ **Separate Key Architecture:** VM uses dedicated `*-vm.txt` keys, not production keys

#### Remaining Risks
⚠️ **Kernel Vulnerabilities:** QEMU escape exploits (rare but possible)  
⚠️ **Shared Filesystem Bugs:** virtiofs/9P implementation vulnerabilities  
⚠️ **Information Leakage:** VM could potentially read its own store derivation to extract the embedded key (same as Vector 1)

**CVSS Score Estimate:** 6.5 (MEDIUM)

### 2.3 Upstream Nixpkgs Rejection Risk (Severity: **HIGH** for project goals)

#### Why Nixpkgs Would Likely Reject This

**Precedent: Existing Nixpkgs Warnings**
Multiple nixpkgs modules explicitly warn against store secrets:

```nix
# services/web-apps/pleroma.nix
secretConfigFile = mkOption {
  description = ''
    DO NOT POINT THIS OPTION TO THE NIX STORE, the store being 
    world-readable, it'll compromise all your secrets
  '';
};

# services/misc/gitlab/default.nix
database.passwordFile = mkOption {
  description = ''
    File containing the database password. Should be a string,
    not a path. Nix paths are copied into the world-readable 
    Nix store.
  '';
};
```

**Nixpkgs Philosophy on Secrets:**
1. **Build-time purity:** Secrets should NEVER be available at build time
2. **Runtime provisioning:** Secrets should be injected at activation/runtime only
3. **Explicit user responsibility:** Users must consciously provision secrets outside Nix

**Why This Patch Violates Philosophy:**

| Principle | Violation |
|-----------|-----------|
| **Purity** | `builtins.readFile` introduces impurity by reading host filesystem |
| **Reproducibility** | Different hosts produce different derivations (different VM keys) |
| **Security-by-default** | Enables easy secret leakage via `/nix/store` |
| **Least privilege** | Gives VMs more access than they need for testing |

### 2.4 Secret Scope Creep (Severity: **MEDIUM**)

#### Risk Description
Once VM secret access is normalized, developers may:
- Accidentally use production secrets in VMs (not just test credentials)
- Expand VM key permissions to decrypt sensitive production data
- Create automated CI/CD pipelines that build VMs with production secrets

#### Current Mitigation
⚠️ **Limited:** The architecture *allows* production secrets to be VM-accessible if `.sops.yaml` is configured that way.

**Current `.sops.yaml` configuration:**
```yaml
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
    - age:
      - *admin_gig
      - *server_wsl
      - *vm_wsl        # ← Can decrypt EVERYTHING
      - *server_merlin
      - *vm_merlin     # ← Can decrypt EVERYTHING
```

**Problem:** VM keys can decrypt **all** secrets, not just a designated testing subset.

---

## 3. Comparison to Alternative Approaches

### 3.1 Existing NixOS VM Secret Mechanisms

#### Option 1: `virtualisation.credentials` (Systemd Credentials)
**Status:** Available in nixpkgs since 2023

```nix
virtualisation.credentials = {
  database-password = {
    text = "test-password";  # ← NOT from host secrets
  };
  ssl-cert = {
    source = "./cert.pem";   # ← Explicit file, not sops-decrypted
  };
};
```

**Security Properties:**
- ✅ Secrets passed at **runtime** via QEMU mechanisms (fw_cfg, smbios)
- ✅ Secrets do NOT enter `/nix/store` during build
- ✅ User explicitly provides test credentials (conscious decision)
- ❌ Does NOT integrate with sops-nix (requires separate credential management)

**Verdict:** More secure than current implementation, but lacks sops-nix integration.

#### Option 2: `boot.initrd.secrets`
**Status:** Available in nixpkgs

```nix
boot.initrd.secrets = {
  "/etc/secret" = "/path/to/secret";
};
```

**Security Properties:**
- ⚠️ If `boot.loader.supportsInitrdSecrets = false`, secrets **are copied to /nix/store**
- ⚠️ If `true`, secrets are appended to initrd at activation time (not build time)
- ❌ Not suitable for VM testing (initrd focus)

**Verdict:** Similar risks to current implementation if improperly used.

### 3.2 How Other VM Systems Handle Secrets

#### Docker/Podman Secrets
```bash
docker run --secret id=mysecret,src=/path/to/secret myimage
```
- Secrets mounted as tmpfs in container
- Never in image layers
- Runtime-only injection

#### Vagrant
```ruby
config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "/home/vagrant/.ssh/"
```
- Explicit file provisioning (user must specify)
- Not part of Vagrantfile (which is version-controlled)

#### Terraform (for cloud VMs)
```hcl
resource "aws_instance" "example" {
  user_data = data.aws_secretsmanager_secret.db_password.secret_string
}
```
- Secrets fetched from external secret manager
- Never in Terraform state files (sensitive=true)

**Common Pattern:** Secrets are **runtime-injected**, not **build-embedded**.

---

## 4. Required Security Controls for Safe Implementation

If this feature were to be made acceptable for upstream nixpkgs, the following controls would be **mandatory**:

### 4.1 Build-Time Purity (CRITICAL)

**Problem:** Current implementation uses `builtins.readFile` at build time.

**Solution:** Use `systemd.credentials` or similar runtime injection:

```nix
# SECURE ALTERNATIVE IMPLEMENTATION
{ config, lib, pkgs, ... }:
let
  isVM = config.virtualisation ? qemu;
  baseHostName = lib.removeSuffix "-vm" config.networking.hostName;
  
  vmKeyMap = {
    "wsl" = "/home/gig/.config/sops/age/wsl-vm.txt";
    "merlin" = "/home/gig/.config/sops/age/merlin-vm.txt";
    # ...
  };
in
{
  # Use systemd credentials to pass VM key at runtime
  systemd.services.sops-nix = lib.mkIf isVM {
    serviceConfig = {
      LoadCredential = "vm-age-key:${vmKeyMap.${baseHostName}}";
    };
  };
  
  # Point sops-nix to the credential (not /etc)
  sops.age.keyFile = lib.mkIf isVM 
    "\${CREDENTIALS_DIRECTORY}/vm-age-key";  # ← NOT in /nix/store
}
```

**Benefit:** Key never enters `/nix/store`, only available in systemd credential directory (`/run/credentials/`).

### 4.2 Explicit Opt-In (REQUIRED)

**Problem:** Current implementation automatically enables VM secret access for all VMs.

**Solution:** Require explicit configuration:

```nix
virtualisation.injectHostSecrets = {
  enable = lib.mkEnableOption "Allow VMs to access host secrets (INSECURE for production)";
  
  keyFile = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = ''
      Path to age key file on HOST for VM secret decryption.
      
      WARNING: This key will be accessible inside the VM.
      Only use test credentials, never production secrets.
    '';
  };
  
  warningAcknowledged = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Set to true to acknowledge security risks";
  };
};

# Implementation with safety check
config = lib.mkIf config.virtualisation.injectHostSecrets.enable {
  assertions = [
    {
      assertion = config.virtualisation.injectHostSecrets.warningAcknowledged;
      message = ''
        VM secret injection is enabled but you have not acknowledged the security risks.
        Set virtualisation.injectHostSecrets.warningAcknowledged = true to proceed.
        
        SECURITY WARNING:
        - VMs will have access to secrets encrypted with the specified key
        - Compromise of VM = compromise of those secrets
        - Only use test credentials, never production secrets
        - Consider using virtualisation.credentials instead
      '';
    }
  ];
  
  # ... rest of implementation
};
```

### 4.3 Secret Segregation (REQUIRED)

**Problem:** VM keys can currently decrypt all secrets.

**Solution:** Enforce separate secret files in `.sops.yaml`:

```yaml
# Recommended .sops.yaml structure
keys:
  - &admin_gig age1...
  - &server_wsl age1...
  - &server_merlin age1...
  - &vm_testing age1...  # SINGLE shared VM key for ALL VMs
  
creation_rules:
  # Production secrets - NO VM keys
  - path_regex: secrets/production\.yaml$
    key_groups:
    - age:
      - *admin_gig
      - *server_wsl
      - *server_merlin
      # VM keys explicitly EXCLUDED
  
  # Testing secrets - VM keys allowed
  - path_regex: secrets/testing\.yaml$
    key_groups:
    - age:
      - *admin_gig
      - *vm_testing  # ← Only test credentials
```

**NixOS Configuration:**
```nix
sops.defaultSopsFile = 
  if isVM 
  then "${secretspath}/testing.yaml"  # ← Restricted secret set
  else "${secretspath}/production.yaml";
```

### 4.4 Audit Logging (RECOMMENDED)

```nix
# Log VM secret access for security auditing
environment.etc."vm-secret-access.log".text = lib.mkIf isVM ''
  VM Secret Access Enabled
  Timestamp: ${builtins.currentTime}
  Host: ${config.networking.hostName}
  VM Key: ${baseHostName}-vm.txt
  Secrets File: ${config.sops.defaultSopsFile}
  
  WARNING: This VM has access to encrypted secrets.
  Any compromise of this VM may expose those secrets.
'';

# Alert user during VM activation
system.activationScripts.warnVMSecrets = lib.mkIf isVM ''
  echo "⚠️  WARNING: This VM has access to host secrets!"
  echo "⚠️  Only use test credentials in this environment."
  cat /etc/vm-secret-access.log
'';
```

### 4.5 Documentation Requirements (REQUIRED for Upstream)

If submitting to nixpkgs, would need:

1. **Security Advisory in Module Documentation**
   ```nix
   # nixos/modules/virtualisation/qemu-vm-secrets.nix
   meta.doc = ''
     WARNING: This module enables VMs to access host secrets.
     
     SECURITY IMPLICATIONS:
     - Secrets may be exposed if VM is compromised
     - Only suitable for local testing with non-production credentials
     - NOT recommended for CI/CD or shared environments
     
     SAFER ALTERNATIVES:
     - Use virtualisation.credentials for explicit secret passing
     - Use hardcoded test passwords in VM variant
     - Provision secrets via cloud-init or other runtime mechanisms
   '';
   ```

2. **NixOS Manual Section**
   - Dedicated chapter on "VM Secret Management"
   - Clear threat model explanation
   - Step-by-step secure configuration guide
   - Common pitfalls and anti-patterns

3. **Example Configurations**
   - Secure testing setup
   - Secret segregation patterns
   - Integration with CI/CD (with caveats)

---

## 5. Assessment: Upstream Acceptance Likelihood

### 5.1 Acceptability for Nixpkgs Upstream

**Verdict:** ❌ **UNLIKELY to be accepted in current form**

**Reasoning:**

| Criterion | Current Status | Required for Acceptance |
|-----------|----------------|-------------------------|
| **Build Purity** | ❌ Uses `builtins.readFile` at build time | ✅ Must use runtime injection only |
| **Store Safety** | ❌ Keys enter `/nix/store` | ✅ Must never write secrets to store |
| **Security-by-Default** | ❌ Auto-enables for VMs | ✅ Must require explicit opt-in |
| **Documentation** | ❌ None in nixpkgs | ✅ Comprehensive security warnings |
| **Alternatives** | ⚠️ `virtualisation.credentials` exists | ✅ Must justify why not sufficient |
| **Scope Control** | ❌ No secret segregation | ✅ Must enforce test vs. prod separation |

### 5.2 Hardened Version Acceptability

**Verdict:** ⚠️ **POSSIBLY acceptable** with all controls from Section 4

**Conditions for Acceptance:**
1. ✅ Implement systemd credentials (Section 4.1)
2. ✅ Require explicit opt-in with warning acknowledgment (Section 4.2)
3. ✅ Document secret segregation best practices (Section 4.3)
4. ✅ Add comprehensive security warnings to module documentation (Section 4.5)
5. ✅ Provide safer alternatives in examples
6. ✅ Restrict to local testing use cases only (no binary cache support)

**Precedent:** Similar to how nixpkgs includes `services.openssh.permitRootLogin = "yes"` (insecure) but:
- Defaults to `"prohibit-password"` (secure default)
- Documented with security warnings
- User must explicitly enable risky behavior

### 5.3 Alternative: Local-Only Overlay

**Recommendation for Lord Gig:**

Instead of upstreaming, maintain as a **local overlay** with:
```nix
# overlays/vm-secrets.nix
self: super: {
  # Local-only VM secret injection
  # NOT for upstream nixpkgs
  # USE ONLY WITH TEST CREDENTIALS
  
  nixosModules.vm-secrets = { config, lib, ... }: {
    # Current implementation
  };
}
```

**Benefits:**
- ✅ No upstream rejection risk
- ✅ Full control over security posture
- ✅ Can iterate rapidly
- ✅ Clear ownership and responsibility
- ✅ Can use `builtins.readFile` if acceptable for local use

**Trade-offs:**
- ❌ No community review (less security scrutiny)
- ❌ Maintenance burden on Lord Gig's fleet
- ❌ Not available to wider NixOS community
- ✅ But that's okay for specialized testing workflows!

---

## 6. Recommendations

### 6.1 For Current Implementation (Local Use)

**Status:** ✅ **ACCEPTABLE for local testing** with caveats

**Required Actions:**

1. **Immediate: Secret Segregation**
   ```bash
   # In nix-secrets repository
   cd ~/nix-secrets
   
   # Create separate testing secrets file
   cp secrets.yaml testing.yaml
   
   # Update .sops.yaml (per Section 4.3)
   
   # Update nixos config to use testing.yaml for VMs
   ```

2. **Short-term: Documentation**
   ```markdown
   # Create docs/vm-testing-security.md
   
   # VM Testing Security Guidelines
   
   ## WARNING
   VMs built with `just vm <host>` have access to secrets from 
   `testing.yaml`. These secrets are decrypted using VM-specific
   age keys stored in `~/.config/sops/age/*-vm.txt`.
   
   ## DO NOT
   - Store production credentials in testing.yaml
   - Use production API keys or certificates in VMs
   - Share VM age keys outside the physical host
   - Upload VM derivations to public binary caches
   
   ## Safe Usage
   - Only use test database credentials
   - Use dummy API keys for development services
   - Rotate VM age keys if compromised
   - Run VMs only on trusted single-user hosts
   ```

3. **Medium-term: Monitoring**
   ```bash
   # Add to .gitignore
   echo "result*" >> .gitignore  # Prevent accidental store path commits
   
   # Add pre-commit hook
   #!/usr/bin/env bash
   # .git/hooks/pre-commit
   if git diff --cached --name-only | grep -q "^result"; then
     echo "ERROR: Attempting to commit 'result' symlink (may expose nix store paths)"
     exit 1
   fi
   ```

### 6.2 For Upstream Submission (If Desired)

**Recommendation:** ❌ **DO NOT submit current implementation to nixpkgs**

**Alternative Path:**

1. **Option A: Submit Feature Request Issue**
   - Open nixpkgs issue: "Support for VM secret injection in build-vm"
   - Present use case (testing configurations with sops-nix)
   - Ask for community input on secure implementation
   - Reference `virtualisation.credentials` as potential model
   - Gauge maintainer interest before investing in PR

2. **Option B: Enhance `virtualisation.credentials`**
   - Submit PR to make `virtualisation.credentials` sops-nix-aware
   - Use runtime credential injection (systemd LoadCredential)
   - Keep secrets out of `/nix/store` entirely
   - More likely to be accepted (extends existing secure feature)

   ```nix
   # Proposed enhancement to nixpkgs
   virtualisation.credentials = {
     sops-vm-key = {
       sopsSecret = "vm-age-key";  # ← New option
       sopsFile = ./testing.yaml;
     };
   };
   ```

3. **Option C: NixOS RFC**
   - Write formal RFC for VM secret management
   - Define threat model and security requirements
   - Propose multiple implementation strategies
   - Seek consensus before implementation
   - Timeline: 3-6 months for RFC process

### 6.3 For Lord Gig's Realm

**Final Recommendation:** ✅ **Continue using current implementation locally**

**Rationale:**
- ✅ Meets immediate testing needs
- ✅ Low risk in single-user, physically controlled environment
- ✅ Can iterate quickly without upstream constraints
- ✅ VM keys are separate from production keys (good isolation)
- ⚠️ Risk acceptable given:
  - Lord Gig is sole user of physical hosts
  - No multi-user environment concerns
  - No binary cache uploads
  - Testing credentials only (no production secrets in VMs)

**Action Items:**
1. ✅ Document security boundaries in fleet documentation
2. ✅ Ensure `.sops.yaml` separates production and testing secrets
3. ✅ Add warning to VM build justfile commands
4. ⚠️ Do NOT attempt to upstream in current form
5. ✅ Monitor for QEMU/KVM vulnerabilities affecting VM escape

---

## 7. Conclusion

### 7.1 Summary of Findings

The current implementation of VM secret injection:

**Strengths:**
- ✅ Functionally works for local testing
- ✅ Isolates VM keys from production keys
- ✅ Automatic detection and configuration
- ✅ Meets Lord Gig's immediate workflow needs

**Weaknesses:**
- ❌ VM age keys enter `/nix/store` (world-readable)
- ❌ No secret segregation enforcement
- ❌ Uses build-time impurity (`builtins.readFile`)
- ❌ Would likely be rejected by nixpkgs upstream

**Risk Level:**
- **For Local Single-User Testing:** 🟡 **MEDIUM** (acceptable with mitigations)
- **For Multi-User Hosts:** 🔴 **HIGH** (not recommended)
- **For Upstream Nixpkgs:** 🔴 **HIGH** (would be rejected)
- **For Production Use:** 🔴 **CRITICAL** (absolutely not acceptable)

### 7.2 Final Verdict

**Question:** Should this be submitted to nixpkgs upstream?

**Answer:** ❌ **NO** - Not in current form

**Question:** Is current implementation acceptable for Lord Gig's local use?

**Answer:** ✅ **YES** - With documented security boundaries

**Question:** Could this be made acceptable for upstream?

**Answer:** ⚠️ **MAYBE** - But would require substantial redesign:
- Replace `builtins.readFile` with `systemd.credentials`
- Add explicit opt-in with security warnings
- Enforce secret segregation at module level
- Provide comprehensive documentation
- Justify why `virtualisation.credentials` is insufficient

**Estimated effort to make upstream-worthy:** 40-80 hours (RFC + implementation + documentation + review cycles)

### 7.3 Recommended Next Steps

**For Lord Gig:**

1. ✅ **Continue using current implementation** for local testing
2. ✅ **Document security boundaries** in fleet operational manual
3. ✅ **Segregate secrets** (create `testing.yaml` separate from `production.yaml`)
4. ✅ **Add warnings** to justfile VM commands
5. ❌ **Do not submit** to nixpkgs upstream without major redesign
6. ⚠️ **Monitor** this analysis for any changes if multi-user hosts are added to fleet

**For Future Consideration:**

If upstreaming becomes desired:
1. Open nixpkgs feature request issue first (gauge interest)
2. Research systemd credential integration with sops-nix
3. Write NixOS RFC for comprehensive secret management in VMs
4. Prototype secure implementation using runtime injection
5. Seek code review from nixpkgs security team

---

## 8. References

### 8.1 Internal Documentation
- `~/.dotfiles/.tmp-oc-logs/scotty-vm-sops-engineering-log.md` - Implementation log
- `~/.dotfiles/.tmp-oc-logs/vm-sops-implementation-plan.md` - Original implementation plan
- `~/.dotfiles/.tmp-oc-logs/vm-secrets-research-report.md` - Library Computer's research
- `~/.dotfiles/hosts/common/core/sops.nix` - Current implementation

### 8.2 NixOS/Nixpkgs Documentation
- [NixOS VM Testing Documentation](https://nixos.org/manual/nixos/stable/#sec-building-vm)
- [nixos/modules/virtualisation/qemu-vm.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/qemu-vm.nix)
- [sops-nix Issue #557](https://github.com/Mic92/sops-nix/issues/557) - VM build failures
- [nixos/tests/qemu-vm-store.nix](https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/qemu-vm-store.nix)

### 8.3 Security Research
- [QEMU Security Documentation](https://www.qemu.org/docs/master/system/security.html)
- [Systemd Credentials Documentation](https://systemd.io/CREDENTIALS/)
- [CVSS v3.1 Specification](https://www.first.org/cvss/v3.1/specification-document)

### 8.4 Comparable Implementations
- Docker Secrets: https://docs.docker.com/engine/swarm/secrets/
- Terraform Sensitive Variables: https://developer.hashicorp.com/terraform/language/values/variables#sensitive
- Vault Agent Injector: https://developer.hashicorp.com/vault/docs/platform/k8s/injector

---

**Report compiled by:** OpenCode Security Analysis Agent  
**Stardate:** 2026-04-10  
**Classification:** Internal Technical Analysis  
**Distribution:** Lord Gig's Realm Fleet Officers

*"Security is not a product, but a process."* - Bruce Schneier
