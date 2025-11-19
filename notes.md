# Interesting Github repo

[Here](https://github.com/nix-gui/nix-gui)

## Information about flake templates

[Here](https://mulias.github.io/blog/nix-flakes-templates-good-actually/)

## Things to do...

- Tape Archival Research [Gemini](https://gemini.google.com/share/4a8aba01628f)
- nixpkgs git cloning helper
  [Gemini](https://gemini.google.com/share/37aa93598977) -- note, this could be
  good use for the started but never finished project in
  [this repo](https://git.gignsky.com/nushell-binary-engine)
- Expand Nvim git dev to allow to search a list of public (and private for
  owner's with keys) repos and select one to inspect.
- Fix up dns and billing deatils (personal v. business) for all cloudflare
  domains
- Add new domains to ddnsupdater, and send them to
  [redirectarr](https://git.gignsky.com/redirectarr)
- Write a flake repo that contacts cloudflare's api and configures DDNS updater
  for dns records and also acts as a central point of truth for internal routing
  in a generated nginx configuration.

  This repo should output container images that can be pulled automatically
  either by other nixos machines and run or pushed to a registry so that truenas
  can pull the updates to the configuration.
- Fix up samba mounts to use the user's proper UID and GID based on lib/vars
  set.
- Write some nushell functions (maybe using the
  [nushell-binary-engine](https://git.gignsky.com/nushell-binary-engine)) to do
  various things easier than they are normally -- current ideas include:
  - Fixing super copy and super move to work properly
    - also making it so that `cp ./path/to/source/file.ext` simply pastes that
      source file in the current directory i.e. it would be equivilent to:
      `cp ./path/to/source/file.ext .`
  - a basic fzf enabled queary tui that can be backed into scripts or by being
    called with before or after a pipe.
  - writing a plugin to go along with the nushell-binary-engine that allows
    nushell to call rust functions explicitly
  - More to come as I think of them...
  - Use nushell-binary-engine to create a similar function to
    lib.mkShellScriptBin in nixpkgs
- Update spacedock container configuration to allow for adhoc scripts to be
  standardized and overridden when needed, also allow for the adhoc script to be
  interactive, maybe using rust and the nushell-binary-engine to select if the
  user would like to repull the images or do other things like clearing
  configured data directories etc.
  - additionally, update the container organization to allow for the funtions
    used in the nginx configuration to be standardized across all the containers
- configure tdarr and other arr (mentioned in private notes) containers on
  spacedock
- write a little git pre checker to check for configurable keywords and prevent
  merges in the case it find them. i.e. check a branch for commits marked
  'REVERT ME' and verify they have been Reverted before allowing the merge to
  succeed.
- don't forget to keep fixing the git.gignsky.com proxy stuff
- modify monolisa and personal fancy-fonts to output items for windows as well
  - see if there is a way to set window's default monospace font
- gigvim improvements:
  - [just-lsp](https://github.com/terror/just-lsp)
  - add rust-debugging
  - add nvim-bacon
  - add gitlab plugin
  - look to see if any opencode plugins exist for nvim
- Look into IPTV section on archer to see if I can get IPTV for plex
- REMEMBER you exposed spacedock as a DMZ on archer
- Look into a openWRT router
