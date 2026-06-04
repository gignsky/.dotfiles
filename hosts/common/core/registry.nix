{
  inputs,
  config,
  lib,
  ...
}:
{
  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes recursive-nix";
        # Opinionated: disable global registry
        # flake-registry = "https://github.com/NixOS/flake-registry/blob/master/flake-registry.json"; # the default is better than empty
        flake-registry = ""; # the default is better than empty
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;
        trusted-users = [
          "gig"
          "root"
        ];

        # Documentation found [here](https://nix.dev/manual/nix/2.34/command-ref/conf-file) the
        # nixConfig flake output is very lightly documented, maybe I should add that to my TODOs
        abort-on-warn = true; # default: false
        allow-dirty = true; # default: true
        allow-dirty-locks = true; # default: false (this could cause an issue if there is a dirty file flake input)
        allow-new-privileges = false; # default: false
        always-allow-substitutes = true; # default: false
        auto-optimise-store = true; # default: false

        # Build Hook:
        # The path to the helper program that executes remote builds.
        # Nix communicates with the build hook over stdio using a custom protocol to request builds that cannot be performed directly by the Nix daemon. The default value is the internal Nix binary that implements remote building.
        # Important
        # Change this setting only if you really know what you’re doing.
        build-hook = ""; # default: *empty* -- This allows for remote build execution, would be great once spacedock is up and running TODO
        # builders = "@/dummy/machines"; #default: @/dummy/machines #LINK: https://nix.dev/manual/nix/2.34/command-ref/conf-file.html#conf-builders
        # builders-use-substitutes=false; #default: false
        # There is also mention of an external-builders function. HERE: https://nix.dev/manual/nix/2.34/command-ref/conf-file.html#conf-external-builders

        commit-lockfile-summary = "";

        debugger-on-trace = true; # default: false
        debugger-on-warn = true; # default: false -- must be on for abort-on-warn to be enabled
        diff-hook = pkgs.nix-diff;
        run-diff-hook = true;

        download-attempts = 10;
        eval-profiler = pkgs.flamegraph;
        fallback = true; # allows nix to build from source if binary fails
        fsync-metadata = false; # default: true -- (if database is corrupted FIX with: `nix-store --verify --check-contents --repair`)
        fsync-store-paths = false; # default: false -- same note as above
        hashed-mirrors = "https://tarballs.nixos.org/"; # default: *empty*
        http-connections = 0; # default: 25 -- 0 means NO LIMIT

        # this will save space by getting rid of lower deps, but will require more rebuilds
        keep-derivations = false; # default: true

        #this will keep from having to rebuild everything after a failure
        keep-failed = true; # default: false

        keep-going = true; # default: false -- will keep build going when derivations fail

        #this will 'increase' used disk space, but will keep the outputs of derivations that are
        #'not-garbage' in the store
        keep-outputs = true; # default: false

        lint-absolute-path-literals = "warn"; # default: "ignore"
        lint-short-path-literals = "warn"; # default: "ignore"
        lint-url-literals = "warn"; # default: "ignore"

        max-jobs = "auto"; # default: 1
        max-silent-time = 15; # default: 0 (no timeout)

        # this would allow for auto-commits of build progress, etc.
        # post-build-hook=""; #default: *empty*

        pure-eval = true; # default: false -- this could cause issues (maybe FIXME)
        trace-import-from-derivation = true; # default: false

        # use-cgroups=true; #default: false (FIXME AFTER WATCHING VIDEO)
      };

      # Opinionated: disable channels
      channel.enable = false;

      # Opinionated: make flake registry and nix path match flake inputs
      # registry.nixpkgs.to={type="path";path=pkgs.path;};
      # registry = lib.mkForce (lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs);
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };
}
