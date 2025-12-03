# FIXME: _**GITLAB** Extra Seat_ is being charged to my account, I need to fix this issue immediately

## Black Friday / Cyber Monday Shopping...

1. Ultrawide Monitor?
2. Split-Keyboard
3. Sound Upgrade

# Interesting Github repo

[Here](https://github.com/nix-gui/nix-gui)

## Information about flake templates

[Here](https://mulias.github.io/blog/nix-flakes-templates-good-actually/)

## Bugs to fix...

1. The following packaging error in dnsenum (Idk if I even want to use this
   program but its broke), error follows:

   ```zsh
    ➜ nix run nixpkgs#dnsenum
   Can't locate Net/IP.pm in @INC (you may need to install the Net::IP module) (@INC entries checked: /nix/store/nxw1xxfxkd6bm570nb6gv0g6pghp7i4c-perl-5.40.0/lib/perl5/site_perl/5.40.0/x86_64-linux-thread-multi /nix/store/nxw1xxfxkd6bm570nb6gv0g6pghp7i4c-perl-5.40.0/lib/perl5/site_perl/5.40.0 /nix/store/nxw1xxfxkd6bm570nb6gv0g6pghp7i4c-perl-5.40.0/lib/perl5/5.40.0/x86_64-linux-thread-multi /nix/store/nxw1xxfxkd6bm570nb6gv0g6pghp7i4c-perl-5.40.0/lib/perl5/5.40.0) at /nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2/bin/dnsenum line 55.
   BEGIN failed--compilation aborted at /nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2/bin/dnsenum line 55.
   ```

   then if one builds with a log they get the following output:

   ```zsh
     gig in 🌐 spacedock in dot-spacedock on  main [$⇡]
     > nix build nixpkgs#dnsenum --print-build-logs --verbose --impure --dry-run

    gig in 🌐 spacedock in dot-spacedock on  main [$⇡]
     > nix eval nixpkgs#dnsenum --print-build-logs --verbose --impure --dry-run
    error: unrecognised flag '--dry-run'
    Try '/run/current-system/sw/bin/nix --help' for more information.

    gig in 🌐 spacedock in dot-spacedock on  main [$⇡]
     ➜ nix eval nixpkgs#dnsenum --print-build-logs --verbose --impure
    «derivation /nix/store/ah3f0lcdprwnjbm1khsj76ya944rwmm8-dnsenum-1.2.4.2.drv»

    gig in 🌐 spacedock in dot-spacedock on  main [$⇡]
     > nix log /nix/store/ah3f0lcdprwnjbm1khsj76ya944rwmm8-dnsenum-1.2.4.2.drv
    Running phase: unpackPhase
    unpacking source archive /nix/store/25mbxzn5mqg78af9krin4m3h5nzqvn8b-source
    source root is source
    Running phase: patchPhase
    Running phase: updateAutotoolsGnuConfigScriptsPhase
    Running phase: configurePhase
    no configure script, doing nothing
    Running phase: buildPhase
    no Makefile or custom buildPhase, doing nothing
    Running phase: installPhase
    install: creating directory '/nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2'
    install: creating directory '/nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2/bin'
    'dnsenum.pl' -> '/nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2/bin/dnsenum'
    install: creating directory '/nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2/share'
    'dns.txt' -> '/nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2/share/dns.txt'
    Running phase: fixupPhase
    shrinking RPATHs of ELF executables and libraries in /nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2
    checking for references to /build/ in /nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2...
    patching script interpreter paths in /nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2
    /nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2/bin/dnsenum: interpreter directive changed from "#!/usr/bin/perl" to "/nix/store/nxw1xxfxkd6bm5>
    stripping (with command strip and flags -S -p) in  /nix/store/i5qljn09445jw1kdfv08ci5pmy79zlg2-dnsenum-1.2.4.2/bin
   ```

## Things to do...

- Read following pages:
  - [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  - [AGENTS.md](https://agents.md/)
- add octo to gigvim for prs and merges
- NixPkgs RFC Suggestion, allowing for systemwide or flake-wide of flake inputs
  with custom headers? i.e. `giglib:` in place of `github:`
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
- pihole things to block:
  - reddit ads / promotions
  - mobile ads
  - _youtube shorts_
- research native website surfacing on search engines to require minimal effort
  other than producing content for sites
- _gscript_ needs some work, basically I think I should start with the following
  few steps:
  1. learn how to write a vimPlugin so that a `.gscript` file can be viewed and
     edited at least in the plainest of text.
  2. Begin on the greater project `gwriter` a typewriter for the terminal that
     save files in the propritary `.gscript` that is simply a plain-text file
     with a bit of metadata stored in there somewhere
     - functions include things like, when backspacing over a character the
       imprint of the old character remains; or if you copy the file the copy
       has a yellow background with different imperfections since it's
       'carbon-paper' lol
     - the program should be completely backwards compaitible with simply
       scanning a typewritten page and adding metadata but it's purpose is to
       bring the permanance and history of a text's life up to date with the
       modern era.
     - would be cool if somehow there was integration with an LLM to sprinkle in
       some nice glyphs and clipart throughout
       - if something is pasted into the document it should have some kind of
         effect around it to indicate the it was literally 'pasted' onto the
         paper.
- Patch bug in opencode drv to requires bun
- package opencode.nvim for nixpkgs
- create superset of nixpkgs
- things to do for ganosLal:
  - configure nvidia GPU to be primary
  - switch right monitor top with bottom, since the top is currently connected
    to the RTX card
  - make sure nvidia drivers are up to date
- research more functionality with opencode relating to expanding
  [sops-nix](https://github.com/Mic92/sops-nix) support
- when using opencode to plan nixconf converstion to a better template make sure
  to also have opencode help clean up old branches and create a list of tasks
  from those branches that might need to be restarted.
- write a package that basically wraps messages in lolcat but also has some
  special logic that determines if a message is an error, warning, etc. and
  assigns a color and maybe an emoji based on the contents
- spin up an ntp server (ideally, highly available -- but not really nececcary)
- deal with some load balancing and spread some services across the two servers
  (memory-alpha/spacedock)
- configure the layer 3 switch to be a router -- if possible; if not, then
  configure a highly available router container on both spacedock/memory-alpha
  in an attempt at a stable network
- configure ddns on spacedock, so that it is written as code rather than a gui
  config
  - this should also be done for the nginx server methinks
- **A Good thing for _Scotty_ to help with!** : _It would be a nice way to learn
  how to manually use an sqlite3 database by creating a database that stores
  information regarding my purchased domains and their details (including their
  intended uses) -- while a new agent might be nice to help me learn about the
  sqlite interactions -- Scotty or another in charge of larger organization
  should be aware of the database and the current state of the websites._
  - This would also lead towards the eventual goal of managing all possible
    cloudflare configuration settings via a nix flake and program like
    _ddnsupdater_ to keep cloudflare and the local (& future remote) proxies
    synced properly
  - Also **IMPORTANT TO FIX SOON _(MAKE NOTE OF ME SCOTTY IF YOU SEE THIS)_**: I
    need to find a proper solution to managing mass emails coming form different
    domains for the long term, ideally with a minimal nix-built docker container
    I could host remotely to keep from having issues with reliability
- It would be wise to setup a redirection machine as described somewhere else in
  this file to deal with all the future projects
- deterministic uptime detector -- find a good name for this and get the domain,
  would of course be written in Nix! (& maybe a bit of rust -- maybe, with
  nushell-binary-engine integration!?)
- need to move spacedock over to this repo instead of seperate one -- ideally I
  need to stabilize both first then merge the best bits, this might mean I
  should reorganize the dotfiles first but I feel as though that might be a
  waste of time
- need to work on gigvim's folding _this is important, for workflow speed_
  **AUTOFOLDING** must come!!
- opencode expansion:
  - it seems there might be 'server' sessions of sorts that can be launched, it
    would be kinda cool to have scotty working on tasks that I add to a queue
    file, that he works on then opens MRs for the changes (this likely requires
    gitlab working -- but that is another issue)
- pretty 'echo' package, maybe called 'whisp' (short for whisper, which even
  though spoken quietly often says the loudest things, thus the lolcat color and
  possible ai enhancement with emojis)
- On `spacedock` when running `just om show` in this repo I get the error:
  ```zsh
  > just om show
  nix run github:juspay/omnix -- show
  warning: ignoring untrusted substituter 'https://cache.nixos.asia/oss', you are not
  a trusted user.
  Run 'man nix.conf' for more information on the 'substituters' configuration
  option.
  ```
- I should figure out how to make it so `nix flake show` shows details of custom
  outputs in this repo and others for outputs like 'homeConfigurations' or
  'nixosTest's
- Task for scotty more than anything:
  - Help me figure out what the current rfc version of nixpkgs is calle din
    unstable and make sure that this flake and others are up to date using the
    proper version
  - revert to 25.11 now that november is over
- A simple addition to gigvim that adds a shortcut to toggle bools true/false --
  I'm sure someone out there has done this, if not then I must!
- Might be a good idea to learn how to 'properly' wrap a package with a
  different name, see (supernote/supernotes in pkgs/ for example of one that
  needs doing!)
- check to see if a bunch of man pages are being lost because they are generated
  for all the posix shells but not ported to nushell (opencode might be a place
  to start), if this is an issue write a package to help!
- write a rust interpreter for nix lang, that will allow for rich rust compilor
  errors as a byproduct
- two new gigvim versions -- each with themes seperate from the regular gigvim:
  1. _marking_, used to update markdown files only and minimal in every other
     way (update the supernote program and the `just sops-secrets` etc., items)
  2. _differ_, used exclusviely as a diff-tool for things like lazygit and
     general diffing (need to update git rules for this one)
- hire _Uhura_ for git expertise, since shes a commons officer after all, but
  then again I could hire _Hoshi_ I think I like that more :)
- Write a agent that will go through and reword old commit messages at
  reasonable times (possibly before merges -- with squashes or else) adding more
  detail to them.
- temp credit cards on _privacy.com_, @dotunwrap says those guys are gigachads.
- SCOTTY HERE -- lets add a '/consult' command where an agent who is called with
  the /consult command will act as a 'rouge' agent making an analysis of the
  repo that it is called in but attempting to continue to keep good logs in the
  home ~/.dotfiles repo (ideally in a worktree or something that is temporarily
  created as to hope not to interfer with work that is in progress in that
  branch/path that may be ongoing) -- but the agent should at all times for ALL
  agents attempt to keep record of it's experinces for later review.
