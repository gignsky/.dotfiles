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
