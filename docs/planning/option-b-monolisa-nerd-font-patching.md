# Option B: MonoLisa Nerd Font Patching Plan

**Status:** Deferred - Option A (JetBrains Mono) sufficient for now  
**Date Created:** 2026-02-27  
**Created By:** First Officer Una  
**Context:** Font glyph rendering issues - glyphs now working with JetBrains Mono Nerd Font

---

## Current State (Option A - Deployed)

- **WezTerm Font:** JetBrains Mono Nerd Font Mono (single font, no fallbacks)
- **System Fonts:** Cartograph CF (monospace/sans), Artifex CF (serif)
- **Status:** Glyphs rendering correctly
- **Branch:** fixing-fucked-fonts
- **Generation:** Home-Manager 145, NixOS 137

---

## Future Enhancement: Option B

### Goal
Create "MonoLisa Nerd Font" - MonoLisa with ALL Nerd Font glyphs properly embedded.

### Why This Matters
- MonoLisa is Lord Gig's preferred terminal font aesthetically
- MonoLisa doesn't natively include Nerd Font glyphs (file icons, git symbols, etc.)
- Current workaround: Using JetBrains Mono which has glyphs but different aesthetics
- Solution: Patch MonoLisa to add Nerd Font glyphs while preserving its beauty

---

## Implementation Strategy

### Phase 1: Setup (5 min)
1. Navigate to `~/local_repos/fancy-fonts/`
2. Create new package directory: `pkgs/monolisa-nerd/`
3. Create Nix derivation that patches existing MonoLisa

### Phase 2: Create Nerd Font Patcher Derivation (15 min)

**File:** `~/local_repos/fancy-fonts/pkgs/monolisa-nerd/default.nix`

```nix
{ lib
, stdenvNoCC
, nerd-font-patcher
, monolisa  # Your existing MonoLisa package
}:

stdenvNoCC.mkDerivation {
  pname = "monolisa-nerd-font";
  version = monolisa.version;

  src = monolisa;

  nativeBuildInputs = [ nerd-font-patcher ];

  buildPhase = ''
    # Extract MonoLisa fonts to temporary directory
    mkdir -p fonts
    cp -r ${monolisa}/share/fonts/truetype/* fonts/ || true
    cp -r ${monolisa}/share/fonts/opentype/* fonts/ || true
    
    # Patch each font file
    mkdir -p patched
    for font in fonts/*.ttf fonts/*.otf; do
      if [ -f "$font" ]; then
        echo "Patching $font"
        nerd-font-patcher \
          --mono \
          --complete \
          --careful \
          --outputdir patched \
          "$font"
      fi
    done
  '';

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp patched/*.ttf $out/share/fonts/truetype/ 2>/dev/null || true
    cp patched/*.otf $out/share/fonts/truetype/ 2>/dev/null || true
  '';

  meta = with lib; {
    description = "MonoLisa patched with Nerd Font glyphs";
    license = monolisa.meta.license or licenses.unfree;
    platforms = platforms.all;
  };
}
```

**Patcher Options Explained:**
- `--mono`: Create monospace variant (for terminals)
- `--complete`: Include all Nerd Font glyph sets (~3,000+ icons)
- `--careful`: Preserve existing glyphs, don't overwrite MonoLisa's characters
- `--outputdir patched`: Where to put the patched fonts

### Phase 3: Expose in Flake (5 min)

**File:** `~/local_repos/fancy-fonts/flake.nix`

```nix
# In outputs.packages
packages.${system} = {
  monolisa = callPackage ./pkgs/monolisa { };
  monolisa-nerd = callPackage ./pkgs/monolisa-nerd { };  # ADD THIS
  cartograph = callPackage ./pkgs/cartograph { };
  artifex = callPackage ./pkgs/artifex { };
};
```

### Phase 4: Update Dotfiles Configuration (5 min)

**File:** `~/.dotfiles/hosts/common/core/fonts.nix`

```nix
fonts.packages = with inputs; with pkgs; [
  fancy-fonts.packages.${system}.cartograph
  fancy-fonts.packages.${system}.artifex
  fancy-fonts.packages.${system}.monolisa-nerd  # Changed from monolisa
  nerd-fonts.jetbrains-mono  # Can keep as backup
  times-newer-roman
];
```

**File:** `~/.dotfiles/home/gig/common/core/wezterm.nix`

```lua
config.font = wezterm.font({
  family = "MonoLisa Nerd Font Mono",  -- The patched version!
  weight = "Regular",
  harfbuzz_features = {
    "calt=1", "liga=1", "dlig=1",
    "ss01=1", "ss02=1", "ss03=1", "ss04=1", "ss05=1"
  },
})

-- Or if MonoLisa Variable is patched:
-- family = "MonoLisa Variable Nerd Font Mono"
```

### Phase 5: Build & Deploy (10 min)

```bash
# In fancy-fonts repo
cd ~/local_repos/fancy-fonts
git add pkgs/monolisa-nerd/
git commit -m "feat(fonts): add MonoLisa Nerd Font patched variant"
git push

# In dotfiles repo
cd ~/.dotfiles
nix flake lock --update-input fancy-fonts
just rebuild-full  # System + Home-Manager

# Restart WezTerm to pick up new font
```

---

## What You'll Get

✅ **MonoLisa aesthetics** - The beautiful font you love  
✅ **All ligatures working** - ss01-ss05 stylistic sets preserved  
✅ **All Nerd Font glyphs** - 3,000+ icons for git, files, powerline, etc.  
✅ **Single font, no fallbacks** - Clean, simple WezTerm config  
✅ **Nix-managed & reproducible** - Part of your flake infrastructure  
✅ **System-wide** - Works in all applications, not just WezTerm

---

## Font Name Changes After Patching

The `nerd-font-patcher` will rename the font family:

```
Before:  MonoLisa Variable       → After: MonoLisa Variable Nerd Font Mono
Before:  MonoLisa Regular        → After: MonoLisa Nerd Font Mono
Before:  MonoLisa Bold           → After: MonoLisa Nerd Font Mono Bold
Before:  MonoLisa Italic         → After: MonoLisa Nerd Font Mono Italic
```

Check actual names after patching with:
```bash
fc-list | grep -i "monolisa.*nerd"
```

---

## Technical Details

### What nerd-font-patcher Does

1. **Adds Glyph Sets:**
   - Powerline symbols (U+E0A0-U+E0A2, U+E0B0-U+E0B3)
   - Font Awesome (U+F000-U+F2E0)
   - Material Design Icons (U+F0001-U+F1AF0)
   - Weather Icons (U+E300-U+E3EB)
   - Octicons (U+F400-U+F4A9, U+2665, U+26A1)
   - Devicons (U+E700-U+E7C5)
   - Codicons (U+EA60-U+EBEB)
   - And many more...

2. **Preserves:**
   - All existing MonoLisa glyphs
   - Ligatures (calt, liga, dlig)
   - Stylistic sets (ss01-ss05)
   - Font metrics and spacing
   - Hinting and rendering quality

3. **Updates Metadata:**
   - Font family name (adds "Nerd Font")
   - Unicode coverage tables (correctly advertises new glyphs)
   - Character map (so fontconfig finds the icons)

### Unicode Private Use Area

Nerd Fonts use Unicode Private Use Area (U+E000-U+F8FF and extended ranges) for icons. This won't conflict with existing characters because:
- Standard text uses U+0000-U+FFFF (Basic Multilingual Plane)
- MonoLisa doesn't use Private Use Area
- Applications explicitly request icon glyphs by their Unicode codepoints

---

## Alternative: Manual Testing Before Nix Integration

If you want to test the patching process manually first:

```bash
# Enter nix shell with patcher
nix-shell -p nerd-font-patcher

# Create test directory
mkdir ~/test-monolisa-patch
cd ~/test-monolisa-patch

# Find MonoLisa font files
find ~/.nix-profile/share/fonts -name "*MonoLisa*.ttf" -o -name "*MonoLisa*.otf"

# Copy one for testing
cp /path/to/MonoLisaVariable.ttf .

# Patch it
nerd-font-patcher --mono --complete --careful MonoLisaVariable.ttf

# Install to local fonts for testing
mkdir -p ~/.fonts
cp *Nerd*.ttf ~/.fonts/
fc-cache -fv

# Test in WezTerm by manually setting font name
# Edit wezterm.nix temporarily to use the test font
```

---

## Estimated Time Investment

- **With guidance:** 30-45 minutes total
- **With automation:** 15 minutes (just review derivation & rebuild)
- **First build:** May take 5-10 minutes (patching all font variants)
- **Subsequent builds:** Cached by Nix (instant)

---

## Why Not Use Pre-Patched Fonts?

You might ask: "Why not just use JetBrains Mono Nerd Font permanently?"

**Answer:**
- MonoLisa has unique aesthetic qualities Lord Gig prefers
- MonoLisa has specific ligatures and stylistic alternates tuned for code
- Consistency: Lord Gig has chosen MonoLisa as his terminal font
- This approach gives you **your chosen font** + **the glyphs you need**

---

## Related Documentation

- **Library Computer Analysis:** Consulted 2026-02-27 (session `ses_35ec49858ffe3E7qy0eUTEYqHk`)
- **Scotty's Engineering Logs:**
  - `operations/logs/rebuilds/2026-02-27_merlin-gen144.md` (Option A fallback attempt)
  - `operations/logs/rebuilds/2026-02-27_merlin-gen145.md` (JetBrains Mono deployment)
- **Previous Font Investigations:**
  - `~/local_repos/annex/crew-logs/scotty/engineering-logs/2026-02/2026-02-27-font-configuration-investigation.md`
  - `~/local_repos/annex/crew-logs/scotty/engineering-logs/2026-02/2026-02-18-ganoslal-font-system-investigation.log`

---

## Decision Log

**2026-02-27:** Option A (JetBrains Mono) deployed and deemed "good enough for now"  
**Status:** Option B deferred until Lord Gig requests MonoLisa restoration  
**Next Action:** File awaits future activation when aesthetics become priority

---

**Filed by:** First Officer Una  
**Stardate:** 2026-02-27.1720  
**Authority:** Lord Gig's directive - "file this away for later this is good enough for now"
