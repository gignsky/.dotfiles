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
- Write some nushell functions (maybe using the
  [nushell-binary-engine](https://git.gignsky.com/nushell-binary-engine)) to do
  various things easier than they are normally -- current ideas include:
  - Fixing super copy and super move to work properly
    - also making it so that `cp ./path/to/source/file.ext` simply pastes that
      source file in the current directory i.e. it would be equivilent to:
      `cp ./path/to/source/file.ext .`
  - writing a plugin to go along with the nushell-binary-engine that allows
    nushell to call rust functions explicitly
  - More to come as I think of them...
