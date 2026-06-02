{
  pkgs,
  config,
  configLib, # <-- This argument is now assumed to come from specialArgs via the module system
  ...
}:
{
  # Contribution to the internal configuration option we defined in default.nix.
  # This makes the 'runPiholeAdHoc' package available under the final, flat package set.
  config.dotspacedock.packages.container-packages.runPiholeAdHoc =
    pkgs.writeShellScriptBin "run-pihole-adhoc" ''
      #!/usr/bin/env bash
      set -euo pipefail

      # NOTE: It is best practice to pass the necessary configuration values
      # as environment variables or constants to the derivation, rather than 
      # accessing external attributes (configLib) during the script's creation.
      # However, given your current structure, we keep the Nix interpolation:

      # Extract the podman command strings
      podman_volumes="${(configLib.container-config.pihole).podmanVolumes}"
      podman_ports="${(configLib.container-config.pihole).podmanPorts}"
      podman_env="${(configLib.container-config.pihole).podmanEnv}"
      podman_extra_options="${(configLib.container-config.pihole).podmanExtraOptions}"
      podman_image="${(configLib.container-config.pihole).image}"

      echo "--- Running Ad-Hoc Pi-hole Container: $podman_image ---"

      # Construct and execute the full podman run command
      sudo ${pkgs.podman}/bin/podman run --rm -it \
        --name pihole-adhoc \
        $podman_volumes \
        $podman_ports \
        $podman_env \
        $podman_extra_options \
        $podman_image

      echo "--- Ad-Hoc Container Exited ---"
    ''
    // {
      passthru = {
        buildInputs = with pkgs; [
          podman
        ];
        tests.scriptIntegrity =
          pkgs.runCommand "test-pihole-script"
            {
              # CRITICAL: Explicitly set the source derivation to be the package output itself.
              src = config.dotspacedock.packages.container-packages.runPiholeAdHoc;
            }
            ''
                # Test that the script contains the 'sudo' command as intended
              if grep -q "sudo ${pkgs.podman}/bin/podman run" $src/bin/run-pihole-adhoc; then
                echo "Test passed: sudo is correctly embedded." >&2
                touch $out
              else
                echo "Test failed: sudo command is missing or malformed." >&2
                exit 1
              fi
            '';
      };
    };
}
