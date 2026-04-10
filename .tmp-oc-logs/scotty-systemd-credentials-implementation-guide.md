# Chief Engineer's Implementation Guide: Systemd Credentials for VM Sops Passwords

**Stardate:** 2026-04-10  
**Engineer:** Chief Engineer Montgomery Scott  
**Captain:** Lord Gig  
**Mission:** Implement systemd credentials approach for VM secrets access

---

## Executive Summary

Captain, this guide will walk ye through implementin' systemd's native credentials system to pass yer sops-encrypted passwords to VMs. It's a cleaner, more secure approach than our previous VM key attempt - no secrets in `/nix/store`, no `--impure` flags needed, and it's already built into nixpkgs!

**What We're Implementin':**
- `virtualisation.credentials` to pass sops secrets into VMs
- User password configuration to read from credentials
- Full secrets access within VMs for testin'

**Time Estimate:** 1-2 hours (implementation + testing)

---

## Part 1: Understanding Systemd Credentials

### How It Works

1. **Host Side:** NixOS configuration declares credentials with `virtualisation.credentials`
2. **QEMU Handoff:** Credentials passed to VM via firmware (fw_cfg on ARM, SMBIOS on x86)
3. **VM Side:** systemd reads credentials during boot from `/sys/firmware/`
4. **Service Access:** Available to services at `$CREDENTIALS_DIRECTORY/<credential-name>`

**Key Advantages:**
- ✅ Secrets never enter `/nix/store` (passed at runtime)
- ✅ Read-only, non-swappable memory backing (when supported)
- ✅ Proper access control (only service's UID + root)
- ✅ Native nixpkgs feature (no patches needed)

### How systemd.exec Works with Credentials

```bash
# In a systemd service:
[Service]
LoadCredential=gig-password

# At runtime, environment variable is set:
echo $CREDENTIALS_DIRECTORY
# /run/credentials/my-service.service

# Credential file available:
cat $CREDENTIALS_DIRECTORY/gig-password
# <actual-decrypted-password>
```

---

## Part 2: Implementation Steps

### Step 1: Create VM Secrets Module

Create a new module specifically for VM secrets handling.

**File:** `hosts/common/core/vm-secrets.nix`

```nix
{ config, lib, ... }:

let
  isVM = config.virtualisation ? qemu;
in
{
  config = lib.mkIf isVM {
    # Pass all sops secrets as VM credentials
    virtualisation.credentials = lib.mapAttrs' (name: secret:
      lib.nameValuePair name {
        # Use the decrypted secret path from host
        source = secret.path;
      }
    ) config.sops.secrets;
    
    # Override user password configuration for VMs
    # We need to read password from systemd credentials instead of sops
    users.users.gig = {
      # In VMs, we'll handle password differently - see Step 3
      hashedPasswordFile = lib.mkForce null;
    };
    
    users.users.root = {
      hashedPasswordFile = lib.mkForce null;
    };
  };
}
```

**What This Does:**
- Detects when runnin' in a VM
- Takes all yer `config.sops.secrets` and passes them as VM credentials
- The `source = secret.path` uses the already-decrypted secret from the **host**
- Disables normal password files (we'll set passwords differently)

### Step 2: Import the Module

**File:** `hosts/common/core/default.nix`

Add the import:

```nix
{
  imports = [
    ./sops.nix
    ./vm-secrets.nix  # Add this line
    # ... other imports
  ];
}
```

### Step 3: Handle User Passwords in VMs

This is the tricky part, Captain. The problem is that `hashedPasswordFile` expects a file path, but systemd credentials are only available **inside service context** via `$CREDENTIALS_DIRECTORY`. 

**Option A: Use a Wrapper Script (RECOMMENDED)**

Create an activation script that reads the credential and sets the password:

**Add to `hosts/common/core/vm-secrets.nix`:**

```nix
{ config, lib, pkgs, ... }:

let
  isVM = config.virtualisation ? qemu;
in
{
  config = lib.mkIf isVM {
    # Pass all sops secrets as VM credentials
    virtualisation.credentials = lib.mapAttrs' (name: secret:
      lib.nameValuePair name {
        source = secret.path;
      }
    ) config.sops.secrets;
    
    # Create early boot service to set passwords from credentials
    systemd.services.vm-set-passwords = {
      description = "Set user passwords from VM credentials";
      wantedBy = [ "multi-user.target" ];
      before = [ "getty@.service" "display-manager.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredential = [
          "gig-password"
          "root-password"
        ];
      };
      
      script = ''
        # Read passwords from credentials
        GIG_PASS=$(cat $CREDENTIALS_DIRECTORY/gig-password)
        ROOT_PASS=$(cat $CREDENTIALS_DIRECTORY/root-password)
        
        # Set passwords (these are already hashed from sops)
        echo "gig:$GIG_PASS" | ${pkgs.shadow}/bin/chpasswd -e
        echo "root:$ROOT_PASS" | ${pkgs.shadow}/bin/chpasswd -e
        
        echo "VM passwords set from credentials"
      '';
    };
    
    # Clear password files since we're handling passwords via service
    users.users.gig.hashedPasswordFile = lib.mkForce null;
    users.users.root.hashedPasswordFile = lib.mkForce null;
  };
}
```

**How This Works:**
1. Service runs early in boot (before getty/display-manager)
2. `LoadCredential=` makes credentials available to the service
3. Script reads credentials and uses `chpasswd -e` to set hashed passwords
4. `-e` flag tells chpasswd the passwords are already hashed

**Option B: Pre-Stage Password Files (SIMPLER)**

If the activation script feels too complex, we can stage password files during VM boot:

```nix
{ config, lib, pkgs, ... }:

let
  isVM = config.virtualisation ? qemu;
in
{
  config = lib.mkIf isVM {
    virtualisation.credentials = lib.mapAttrs' (name: secret:
      lib.nameValuePair name {
        source = secret.path;
      }
    ) config.sops.secrets;
    
    # Create tmpfiles that copy credentials to expected locations
    systemd.tmpfiles.settings."10-vm-passwords" = {
      "/run/vm-secrets/gig-password" = {
        C = {
          type = "C";
          argument = "/run/credentials/systemd-tmpfiles-setup.service/gig-password";
          mode = "0400";
          user = "root";
          group = "root";
        };
      };
      "/run/vm-secrets/root-password" = {
        C = {
          type = "C";
          argument = "/run/credentials/systemd-tmpfiles-setup.service/root-password";
          mode = "0400";
          user = "root";
          group = "root";
        };
      };
    };
    
    # Point users to the tmpfiles locations
    users.users.gig.hashedPasswordFile = lib.mkForce "/run/vm-secrets/gig-password";
    users.users.root.hashedPasswordFile = lib.mkForce "/run/vm-secrets/root-password";
  };
}
```

**Problem with Option B:** The `systemd-tmpfiles-setup.service` might not have the credentials loaded. This won't work cleanly.

**Captain's Recommendation:** Use **Option A** (the activation service). It's more explicit and reliable.

### Step 4: Handle Other Secrets (CIFS credentials, etc.)

For non-password secrets that are used by services, this is much simpler:

**Example: Samba with CIFS credentials**

**In your samba configuration module:**

```nix
{ config, lib, ... }:

let
  isVM = config.virtualisation ? qemu;
in
{
  systemd.services.samba = lib.mkIf isVM {
    serviceConfig = {
      # Load the credential into this service
      LoadCredential = "cifs-creds";
    };
    
    # Override the ExecStart to point to credential location
    environment = {
      CIFS_CREDS_FILE = "$CREDENTIALS_DIRECTORY/cifs-creds";
    };
  };
  
  # For physical hosts, keep using sops path
  systemd.services.samba = lib.mkIf (!isVM) {
    environment = {
      CIFS_CREDS_FILE = config.sops.secrets.cifs-creds.path;
    };
  };
}
```

---

## Part 3: Complete Implementation

Here's the full module, Captain:

**File:** `hosts/common/core/vm-secrets.nix`

```nix
{ config, lib, pkgs, ... }:

let
  isVM = config.virtualisation ? qemu;
in
{
  config = lib.mkIf isVM {
    # ========================================
    # Pass all sops secrets as VM credentials
    # ========================================
    virtualisation.credentials = lib.mapAttrs' (name: secret:
      lib.nameValuePair name {
        # The host's decrypted secret path
        source = secret.path;
      }
    ) config.sops.secrets;
    
    # ========================================
    # Set user passwords from credentials
    # ========================================
    systemd.services.vm-set-passwords = {
      description = "Set user passwords from VM credentials";
      wantedBy = [ "multi-user.target" ];
      before = [ "getty@.service" "display-manager.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredential = [
          "gig-password"
          "root-password"
        ];
      };
      
      script = ''
        # Read hashed passwords from credentials
        GIG_PASS=$(cat $CREDENTIALS_DIRECTORY/gig-password)
        ROOT_PASS=$(cat $CREDENTIALS_DIRECTORY/root-password)
        
        # Set passwords (already hashed from sops)
        echo "gig:$GIG_PASS" | ${pkgs.shadow}/bin/chpasswd -e
        echo "root:$ROOT_PASS" | ${pkgs.shadow}/bin/chpasswd -e
        
        echo "✓ VM user passwords set from credentials"
      '';
    };
    
    # Don't use password files in VMs (handled by service above)
    users.users.gig.hashedPasswordFile = lib.mkForce null;
    users.users.root.hashedPasswordFile = lib.mkForce null;
    
    # ========================================
    # Make credentials available to services
    # ========================================
    # Services can now use LoadCredential= to access secrets
    # Example: systemd.services.myservice.serviceConfig.LoadCredential = "cifs-creds";
  };
}
```

---

## Part 4: Testing Procedure

### Test 1: Build the VM

```bash
cd ~/.dotfiles
just vm-build merlin
```

**Expected:** Build succeeds without errors. No `--impure` flag needed!

**If Build Fails:** Check error messages carefully. Most likely issues:
- Module import path wrong
- Syntax error in vm-secrets.nix

### Test 2: Boot and Test Login

```bash
cd ~/.dotfiles
./result/bin/run-merlin-vm
```

**In the VM console:**

1. **Wait for boot to complete** (you'll see login prompt)
2. **Try to log in as `gig`** with your normal password
3. **Check service status:**
   ```bash
   systemctl status vm-set-passwords
   ```
   Should show "active (exited)" with success message

**Expected:** Login works with your sops-encrypted password

**If Login Fails:**
```bash
# On the VM console (if you can't login):
# Press Ctrl+Alt+F2 to switch to another TTY
# Or use recovery mode

# Check if credentials were passed:
sudo ls -la /run/credentials/vm-set-passwords.service/
# Should show: gig-password, root-password

# Check service logs:
sudo journalctl -u vm-set-passwords
# Look for errors in the script execution

# Manually check credential content:
sudo cat /run/credentials/vm-set-passwords.service/gig-password
# Should show your hashed password
```

### Test 3: Verify Other Secrets

**Check cifs-creds (if you have samba configured):**

```bash
# In VM, check if credential is available
sudo ls -la /run/credentials/

# If samba service is running:
systemctl status samba
sudo cat /run/credentials/samba.service/cifs-creds
```

### Test 4: Verify Physical Host Unaffected

```bash
# Exit VM, back on merlin
sudo nixos-rebuild test --flake .#merlin
```

**Expected:** Host rebuilds normally, uses sops as usual (not credentials system)

---

## Part 5: Troubleshooting

### Issue: "cannot access sops secret path"

**Symptom:** Build error referencing `secret.path`

**Cause:** Trying to access sops secret path before sops has initialized

**Solution:** The `source = secret.path` works because on the **host** where we're building the VM, sops-nix has already decrypted secrets to `/run/secrets/*`. The VM build process reads these decrypted files and embeds them into VM credentials.

### Issue: "credentials not found in VM"

**Symptom:** `/run/credentials/vm-set-passwords.service/` doesn't exist

**Cause:** systemd might not have credential support, or credentials weren't passed correctly

**Debugging:**
```bash
# Check if systemd supports credentials:
systemd --version
# Look for "credentials" in feature list

# Check VM startup for QEMU arguments:
# (From host, before starting VM)
cat ./result/bin/run-merlin-vm | grep -i fw_cfg
# Should show fw_cfg or smbios credential arguments
```

### Issue: "chpasswd fails"

**Symptom:** `vm-set-passwords` service fails with chpasswd error

**Cause:** Password from sops might not be in correct format

**Solution:** Verify your `secrets.yaml` has hashed passwords:
```bash
# On host:
cat /run/secrets/gig-password
# Should start with $6$ or similar (hashed password format)
```

If it's plaintext, you need to hash it first in secrets.yaml or change the script to:
```bash
echo "gig:$GIG_PASS" | ${pkgs.shadow}/bin/chpasswd  # No -e flag for plaintext
```

---

## Part 6: Alternative Approach (If Above Doesn't Work)

If the credentials system proves troublesome, here's a fallback:

**Shared Directory with Runtime Copy:**

```nix
{ config, lib, ... }:

let
  isVM = config.virtualisation ? qemu;
in
{
  config = lib.mkIf isVM {
    # Mount host's /run/secrets into VM
    virtualisation.sharedDirectories.secrets = {
      source = "/run/secrets";
      target = "/mnt/host-secrets";
      securityModel = "none";
    };
    
    # Copy secrets to VM's /run/secrets at boot
    systemd.services.vm-copy-secrets = {
      description = "Copy secrets from host mount";
      wantedBy = [ "multi-user.target" ];
      before = [ "getty@.service" ];
      
      script = ''
        mkdir -p /run/secrets
        cp -L /mnt/host-secrets/gig-password /run/secrets/gig-password
        cp -L /mnt/host-secrets/root-password /run/secrets/root-password
        cp -L /mnt/host-secrets/cifs-creds /run/secrets/cifs-creds || true
        chmod 400 /run/secrets/*
        chown root:root /run/secrets/*
      '';
    };
    
    # Users can use normal sops paths
    # (no changes needed to user configuration)
  };
}
```

This approach:
- Uses 9P to share `/run/secrets` from host to VM
- Copies them during boot
- Works exactly like sops on physical host

---

## Part 7: Validation Checklist

Before considerin' this complete, verify:

- [ ] VM builds successfully (`just vm-build merlin`)
- [ ] VM boots without errors
- [ ] Can login as `gig` with sops password
- [ ] Can login as `root` with sops password
- [ ] `systemctl status vm-set-passwords` shows success
- [ ] Other services can access their credentials
- [ ] Physical host rebuild still works normally
- [ ] No secrets visible in `/nix/store`

---

## Engineering Notes

**Why This Approach is Superior:**

1. **Security:** Secrets passed at runtime, not build time
2. **Purity:** No `--impure` flags needed
3. **Upstream:** Using official nixpkgs features
4. **Maintainability:** No VM-specific keys to manage
5. **Simplicity:** Single module, clear purpose

**Performance Impact:** Negligible - credentials are small (KB range) and passed once at VM startup.

**Limitations:**
- Credentials are per-service (need `LoadCredential=` in each service that needs them)
- Password handling requires custom activation service

---

## Summary

Captain, this implementation gives ye full sops secrets access in yer VMs using systemd's native credentials system. It's secure, maintainable, and requires no patches to nixpkgs.

The key insight is that `virtualisation.credentials` with `source = secret.path` reads the **host's** already-decrypted sops secrets and passes them to the VM at runtime. No VM-specific keys needed!

**Next Steps:**
1. Create `hosts/common/core/vm-secrets.nix` with the full implementation
2. Import it in `hosts/common/core/default.nix`
3. Test with `just vm-build merlin`
4. Boot VM and verify login works

I'm standin' by if ye need any adjustments or run into issues, Captain!

**Chief Engineer Montgomery Scott**  
**USS Enterprise Engineering**  
**Stardate 2026-04-10T20:00:00**

*"The right tool for the right job - and systemd credentials is the right tool for this one!"*
