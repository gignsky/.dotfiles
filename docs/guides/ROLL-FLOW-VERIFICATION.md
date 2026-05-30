# Roll Flow Promotion Verification System

## What It Does

The `just roll-promote` command now **automatically verifies** that all hosts have been tested before promoting `rolling` → `main`.

## How It Works

### 1. Finds the Latest Roll Merge
```bash
# Searches for the most recent merge commit like:
# "Merge branch 'roll/5-roll-flow-init' into rolling"
```

### 2. Checks for Rebuild Commits After That Merge

For each host in your config, it looks for TWO types of commits:

**NixOS rebuild commits:**
```
merlin: generation 203 (switch)
ganoslal: generation 42 (boot)
wsl: generation 15 (switch)
wsl@ganoslal: generation 184 (switch)
wsl@merlin: generation 92 (switch)
```

**Home-manager rebuild commits:**
```
gig@merlin: 2026-05-30 18:19 : id 187 -> /nix/store/...
gig@ganoslal: 2026-05-30 12:00 : id 150 -> /nix/store/...
gig@wsl: 2026-05-30 14:30 : id 200 -> /nix/store/...
gig@wsl@ganoslal: 2026-05-12 15:23 : id 298 -> /nix/store/...
gig@wsl@merlin: 2026-05-13 10:00 : id 150 -> /nix/store/...
```

### 3. Verifies ALL Hosts Are Tested

**For promotion to succeed**, EVERY host must have:
- ✅ At least one NixOS rebuild commit after the latest roll merge
- ✅ At least one home-manager rebuild commit after the latest roll merge

**Additionally**, for physical hosts (ganoslal, merlin):
- ⚠️  Checks if WSL instances exist (wsl@hostname)
- ⚠️  If they exist, warns if they haven't been rebuilt

### 4. Blocks Promotion if Missing

If any host is missing rebuilds, promotion is **blocked** with helpful instructions.

## Example Output

### ✅ Success Case
```
Promoting rolling to main

Verifying all hosts have been tested with actual rebuilds...

Latest roll merge: 05ff1bd1

Checking for rebuild commits after this merge...

Checking ganoslal...
  ✓ NixOS: ganoslal: generation 185 (switch)
  ✓ Home:  gig@ganoslal: 2026-05-30 20:15 : id 151 -> /nix/store/...

Checking merlin...
  ✓ NixOS: merlin: generation 203 (switch)
  ✓ Home:  gig@merlin: 2026-05-30 18:19 : id 187 -> /nix/store/...
  ✓ WSL@merlin NixOS: wsl@merlin: generation 93 (switch)
  ✓ WSL@merlin Home:  gig@wsl@merlin: 2026-05-30 18:25 : id 151 -> /nix/store/...

Checking wsl...
  ✓ NixOS: wsl: generation 16 (switch)
  ✓ Home:  gig@wsl: 2026-05-30 14:30 : id 200 -> /nix/store/...

✓ All hosts verified!
All configured hosts have rebuild commits after the latest roll.

Proceed with promotion to main? (yes/no):
```

### ❌ Failure Case
```
Promoting rolling to main

Verifying all hosts have been tested with actual rebuilds...

Latest roll merge: 05ff1bd1

Checking for rebuild commits after this merge...

Checking ganoslal...
  ✗ Missing NixOS rebuild for ganoslal
  ✗ Missing home-manager rebuild for ganoslal

Checking merlin...
  ✓ NixOS: merlin: generation 203 (switch)
  ✓ Home:  gig@merlin: 2026-05-30 18:19 : id 187 -> /nix/store/...

Checking wsl...
  ✓ NixOS: wsl: generation 16 (switch)
  ✗ Missing home-manager rebuild for wsl

✗ Verification failed!

Some hosts are missing rebuild commits after the latest roll merge.
This means they haven't been tested with the changes in rolling.

To fix this:
  1. SSH to each host: ssh <host>
  2. Checkout rolling: cd ~/.dotfiles && git checkout rolling && git pull
  3. Rebuild NixOS: just rebuild
  4. Rebuild home-manager: just home
  5. Come back here and try promote again
```

## Why This Matters

### Before This Feature
You could promote to main after:
- ✅ Testing on merlin (your current host)
- ❌ NOT testing on ganoslal
- ❌ NOT testing on wsl

Result: Main branch breaks for untested hosts!

### With This Feature
Promotion is blocked until:
- ✅ Tested on merlin (has rebuild commits)
- ✅ Tested on ganoslal (has rebuild commits)
- ✅ Tested on wsl (has rebuild commits)
- ✅ Even WSL instances checked!

Result: Main branch guaranteed to work everywhere!

## The Rebuild Commit Pattern

Your `just rebuild` and `just home` commands create these commits automatically:

### NixOS Rebuild
Creates a commit like:
```
merlin: generation 203 (switch)
```

### Home-Manager Rebuild  
Creates a commit like:
```
gig@merlin: 2026-05-30 18:19 : id 187 -> /nix/store/j42qwjhgy2lkfhmg6fa0aavpqhydyv2k-home-manager-generation (current)
```

These commits serve as **proof** that you actually rebuilt on that host.

## Special WSL Handling

Physical hosts (ganoslal, merlin) can have WSL instances running inside them:
- **wsl@ganoslal** = WSL running on ganoslal machine
- **wsl@merlin** = WSL running on merlin machine

The verification:
1. Checks if WSL instances exist (by looking for commits)
2. If they exist, warns you to test them too
3. Doesn't block promotion (warning only) since WSL instances are optional

## How to Use

### Normal Workflow
```bash
# 1. Graduate your roll
just roll-graduate

# 2. Test on each host
ssh ganoslal
cd ~/.dotfiles
git checkout rolling
git pull
just rebuild  # Creates NixOS commit
just home     # Creates home-manager commit
exit

ssh merlin
# ... same process ...

ssh wsl
# ... same process ...

# 3. Promote with confidence
just roll-promote  # Automatic verification!
```

### If Verification Fails

Follow the on-screen instructions:
1. SSH to the missing host
2. Check out rolling branch
3. Run rebuilds
4. Try promote again

The verification will pass once all hosts have rebuild commits.

## Configuration

Hosts to check are defined in `~/.config/roll-flow/config.nuon`:
```nushell
{
  hosts: [ganoslal, merlin, wsl],
  username: "gig"
}
```

Change these if you add/remove hosts.

---

**Chief Engineer Montgomery Scott**  
**Stardate 2026-05-30**

*"This verification system is like a pre-flight checklist for the entire fleet! Ye' can't take all the ships to warp until ye've verified EVERY engine has been properly tested. No exceptions!"* 🚀✅
