# VM Sops Secrets Implementation Plan
**Date:** 2026-04-02  
**Commander:** Una  
**Lead Engineer:** Chief Engineer Montgomery Scott  
**Assistant Engineer:** Rom (via Scotty's guidance)  
**Branch:** `vm/1-attempt-vm-secrets-import`

---

## Mission Objective

Implement **Solution #2 (Per-Host VM Keys)** from Library Computer's research report to enable full sops secrets access in ephemeral NixOS VMs without per-VM key management overhead.

**Success Criteria:**
- ✅ VMs can decrypt all sops secrets (passwords, cifs-creds, etc.)
- ✅ No individual key management for each VM instance
- ✅ Automatic VM detection and key selection
- ✅ Private keys never committed to git repositories
- ✅ Works for all hosts: wsl, merlin, ganoslal, spacedock

---

## Implementation Strategy

### Phase 1: Generate Per-Host VM Keys
**Assigned to:** Scotty (with Rom's assistance)  
**Location:** Local filesystem (`~/.config/sops/age/`)  
**Security:** Private keys stay local, only public keys go to nix-secrets

**Tasks:**
1. Create VM age keys for each physical host:
   ```bash
   # On merlin (or any host with sops access)
   mkdir -p ~/.config/sops/age
   
   # Generate VM keys
   age-keygen -o ~/.config/sops/age/wsl-vm.txt
   age-keygen -o ~/.config/sops/age/merlin-vm.txt
   age-keygen -o ~/.config/sops/age/ganoslal-vm.txt
   age-keygen -o ~/.config/sops/age/spacedock-vm.txt
   ```

2. Extract public keys for each:
   ```bash
   cat ~/.config/sops/age/wsl-vm.txt | age-keygen -y       # Copy output
   cat ~/.config/sops/age/merlin-vm.txt | age-keygen -y    # Copy output
   cat ~/.config/sops/age/ganoslal-vm.txt | age-keygen -y  # Copy output
   cat ~/.config/sops/age/spacedock-vm.txt | age-keygen -y # Copy output
   ```

3. Verify keys created correctly:
   ```bash
   ls -lh ~/.config/sops/age/*-vm.txt
   # Should show 4 files: wsl-vm.txt, merlin-vm.txt, ganoslal-vm.txt, spacedock-vm.txt
   ```

4. Document public keys for next phase
   - Create temporary file with all 4 public keys
   - Label each clearly (wsl, merlin, ganoslal, spacedock)

**Expected Output:**
- 4 private key files in `~/.config/sops/age/`
- 4 public keys ready for sops.yaml configuration
- Keys verified and documented

---

### Phase 2: Update nix-secrets Configuration
**Assigned to:** Scotty  
**Location:** `~/nix-secrets/`  
**Repository:** Private git repo

**Tasks:**
1. Update `~/nix-secrets/.sops.yaml` with VM public keys:
   ```yaml
   keys:
     # Existing keys...
     - &admin_gig age1...existing...
     - &server_wsl age1...existing...
     - &server_merlin age1...existing...
     - &server_ganoslal age1...existing...
     - &server_spacedock age1...existing...
     
     # NEW: VM keys for testing
     - &vm_wsl age1xxxxxxxxxx...from...step1
     - &vm_merlin age1xxxxxxxxxx...from...step1
     - &vm_ganoslal age1xxxxxxxxxx...from...step1
     - &vm_spacedock age1xxxxxxxxxx...from...step1
   
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

2. Re-encrypt all secrets with new VM keys:
   ```bash
   cd ~/nix-secrets
   sops updatekeys secrets.yaml
   sops updatekeys notes.md  # If applicable
   ```

3. Verify re-encryption succeeded:
   ```bash
   # Should show all 8+ age recipients (4 servers + 4 VMs + admin)
   head -20 ~/nix-secrets/secrets.yaml
   ```

4. Test decryption with one VM key:
   ```bash
   SOPS_AGE_KEY_FILE=~/.config/sops/age/merlin-vm.txt sops -d secrets.yaml
   # Should successfully decrypt
   ```

5. Commit changes to nix-secrets:
   ```bash
   cd ~/nix-secrets
   git add .sops.yaml secrets.yaml
   git commit -m "feat(sops): add per-host VM age keys for testing

   - Added VM-specific age keys for wsl, merlin, ganoslal, spacedock
   - Re-encrypted secrets to include VM keys
   - Enables full secrets access in nixos-rebuild build-vm testing
   
   Private keys stored locally in ~/.config/sops/age/ (not in repo)"
   git push
   ```

**Expected Output:**
- `.sops.yaml` updated with 4 new VM public keys
- All secrets re-encrypted with VM keys included
- Changes committed and pushed to nix-secrets repo
- VM keys verified to decrypt secrets

---

### Phase 3: Update NixOS Configuration
**Assigned to:** Scotty (implementation) + Rom (testing)  
**Location:** `~/.dotfiles/hosts/common/core/sops.nix`  
**Branch:** `vm/1-attempt-vm-secrets-import`

**Tasks:**
1. Update `hosts/common/core/sops.nix` with VM detection logic:
   ```nix
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
     
     # Extract base hostname (VMs may have -vm suffix)
     baseHostName = lib.removeSuffix "-vm" hostName;
   in
   {
     imports = [
       inputs.sops-nix.nixosModules.sops
     ];
   
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
         gig-password = {
           neededForUsers = true;
         };
         root-password = {
           neededForUsers = true;
         };
         cifs-creds = {
           path = "/etc/samba/cifs-creds";
         };
       };
     };
   }
   ```

2. Update nix-secrets flake input:
   ```bash
   cd ~/.dotfiles
   nix flake update nix-secrets --commit-lock-file
   ```

3. Run flake check to verify configuration:
   ```bash
   just check
   # Should pass without errors
   ```

4. Commit configuration changes:
   ```bash
   git add hosts/common/core/sops.nix flake.lock
   git commit -m "feat(sops): implement per-host VM key detection

   - Added VM detection logic to automatically use VM-specific age keys
   - VMs now use ~/.config/sops/age/<hostname>-vm.txt for decryption
   - Physical hosts continue using /var/lib/sops-nix/key.txt
   - Enables full sops secrets access in VMs for testing
   
   Implements Solution #2 from Library Computer research
   See: .tmp-oc-logs/vm-secrets-research-report.md"
   ```

**Expected Output:**
- `hosts/common/core/sops.nix` updated with VM detection
- Flake check passes
- Configuration committed to branch

---

### Phase 4: Testing & Validation
**Assigned to:** Rom (supervised by Scotty)  
**Location:** `~/.dotfiles/` on merlin host  
**Branch:** `vm/1-attempt-vm-secrets-import`

**Test Plan:**

#### Test 1: Build VM
```bash
cd ~/.dotfiles
just vm-build merlin
# Expected: Build succeeds without sops errors
```

#### Test 2: Verify VM Can Access Secrets
```bash
# Start VM
just vm merlin

# Inside VM (after boot):
# 1. Check if sops key is accessible
ls -la /home/gig/.config/sops/age/merlin-vm.txt

# 2. Try to login as user 'gig'
# Login should succeed using sops-decrypted password

# 3. Check if other secrets are accessible
sudo ls -la /etc/samba/cifs-creds
# Should exist if VM properly decrypted secrets
```

#### Test 3: Verify Physical Host Unaffected
```bash
# Exit VM, back on merlin host
sudo nixos-rebuild test --flake .#merlin
# Expected: Rebuild succeeds, uses /var/lib/sops-nix/key.txt (not VM key)

# Verify host still uses correct key
cat /etc/systemd/system/sops-nix.service | grep -i key
# Should reference /var/lib/sops-nix/key.txt
```

#### Test 4: Test Other Hosts' VMs
```bash
just vm-build wsl
just vm-build ganoslal
just vm-build spacedock
# All should build successfully with appropriate VM keys
```

**Validation Checklist:**
- [ ] VM builds without sops-related errors
- [ ] Can log into VM with sops-encrypted password
- [ ] VM can access all sops secrets (cifs-creds, etc.)
- [ ] Physical host rebuild still works normally
- [ ] Host continues using correct key file
- [ ] All 4 hosts' VMs build successfully

**Expected Output:**
- All tests pass
- VMs have full secret access
- Physical hosts unaffected
- Test results documented

---

### Phase 5: Documentation & Cleanup
**Assigned to:** Scotty  
**Location:** Various

**Tasks:**
1. Move research report to permanent location:
   ```bash
   mkdir -p docs/guides/vm-testing
   mv .tmp-oc-logs/vm-secrets-research-report.md docs/guides/vm-testing/
   mv .tmp-oc-logs/vm-sops-implementation-plan.md docs/guides/vm-testing/
   ```

2. Create quick reference guide:
   ```bash
   # Create docs/guides/vm-testing/quick-start.md
   # Document:
   # - How to test configurations with `just vm <host>`
   # - What secrets are accessible
   # - How to add new VM keys for new hosts
   # - Troubleshooting common issues
   ```

3. Update AGENTS.md if needed:
   ```bash
   # Add note about VM testing workflow
   # Reference vm-testing documentation
   ```

4. Create engineering log entry:
   ```bash
   # Scotty's log documenting:
   # - Implementation process
   # - Any issues encountered
   # - Final validation results
   # - Lessons learned
   ```

5. Final commit and merge preparation:
   ```bash
   git add docs/
   git commit -m "docs(vm): add VM sops implementation guides

   - Moved research report to permanent location
   - Created quick-start guide for VM testing
   - Documented VM secrets architecture
   
   Engineering-Log: Scotty <$(date -Iseconds)>"
   
   # Don't merge yet - await Lord Gig's review
   ```

**Expected Output:**
- Complete documentation set
- Engineering logs updated
- Branch ready for review and merge

---

## Risk Management

### Potential Issues & Mitigations

**Issue 1: VM key files not accessible in VM**
- **Symptom:** VM can't find `~/.config/sops/age/merlin-vm.txt`
- **Cause:** Path is relative to host, not VM filesystem
- **Mitigation:** May need to use `virtualisation.sharedDirectories` to mount `~/.config/sops/age/` into VM
- **Alternative:** Place VM keys in `/nix/store` via Nix configuration

**Issue 2: Hostname mismatch in VM**
- **Symptom:** VM hostname doesn't match expected base hostname
- **Debugging:** Check `config.networking.hostName` inside VM
- **Mitigation:** Adjust `baseHostName` extraction logic if needed

**Issue 3: Re-encryption fails**
- **Symptom:** `sops updatekeys` errors
- **Cause:** Invalid public key format or .sops.yaml syntax
- **Mitigation:** Validate public keys, check YAML indentation

**Issue 4: Physical host rebuild breaks**
- **Symptom:** Host can't find sops keys after config change
- **Cause:** Incorrect conditional logic in sops.nix
- **Mitigation:** Test host rebuild BEFORE testing VMs
- **Rollback:** Revert sops.nix changes, rebuild

---

## Timeline Estimate

- **Phase 1 (Key Generation):** 15 minutes
- **Phase 2 (nix-secrets Update):** 30 minutes
- **Phase 3 (NixOS Config):** 45 minutes
- **Phase 4 (Testing):** 60 minutes
- **Phase 5 (Documentation):** 30 minutes

**Total Estimated Time:** 3 hours

---

## Success Metrics

1. **Functional:** All 4 hosts can build VMs with full sops access
2. **Security:** Private VM keys never committed to git
3. **Maintainability:** Adding new hosts requires only one new VM key
4. **Documentation:** Complete guides for future reference
5. **Code Quality:** Flake check passes, no warnings

---

## Next Steps After Completion

1. Test VM workflow with actual configuration changes
2. Validate cifs-creds and other non-password secrets in VM
3. Consider implementing Solution #1 (shared VM key) as fallback
4. Document backup/recovery procedure for VM keys
5. Create automated tests for VM sops access

---

## References

- **Research Report:** `.tmp-oc-logs/vm-secrets-research-report.md`
- **sops-nix Docs:** https://github.com/Mic92/sops-nix
- **Issue Reference:** sops-nix #557 (generateKey in VMs)
- **VM Builder Docs:** nixos.org/manual/nixos/stable/index.html#sec-building-vm

---

## Sign-Off

**Implementation Plan Approved By:**
- Commander Una Chin-Riley (Plan Author)
- Awaiting: Chief Engineer Montgomery Scott (Implementation Lead)
- Awaiting: Lord Gig (Final Authorization)

**Status:** READY FOR IMPLEMENTATION  
**Priority:** HIGH (Blocks VM testing workflow)  
**Complexity:** MEDIUM (Well-researched, clear path forward)
