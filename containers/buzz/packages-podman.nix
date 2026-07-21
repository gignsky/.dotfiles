# Buzz Container Packages (Podman version)
# All buzz-related packages and utilities using Podman. Ported from dot-spacedock.
# Requires the `nixos-generators` flake input to be present.

{
  inputs,
  lib,
  system,
}:

let
  pkgs = inputs.nixpkgs.legacyPackages.${system};

  # Import config components needed for container generation
  configVars = import ../../vars { inherit inputs lib; };
  configLib = import ../../lib { inherit lib; };
  overlays = import ../../overlays { inherit inputs; };

  # Create a minimal outputs structure for buzz
  outputs = {
    inherit overlays;
  };

  # Podman can use the same OCI images as Docker
  buzzContainer = inputs.nixos-generators.nixosGenerate {
    inherit system;
    specialArgs = {
      inherit
        inputs
        lib
        system
        configVars
        configLib
        outputs
        ;
      nixpkgs = inputs.nixpkgs;
    };
    modules = [ ./config.nix ];
    format = "docker"; # OCI format works with both Docker and Podman
  };

in
{
  # The container image itself
  buzz-container = buzzContainer;

  # Main buzz runner (Podman version)
  buzz = pkgs.writeShellScriptBin "pbuzz" ''
    set -euo pipefail

    CONTAINER_NAME="buzz-spacedock"
    IMAGE_NAME="buzz:latest"

    echo "🐝 Buzz - Containerized Spacedock (Podman)"
    echo "=========================================="

    if ${pkgs.podman}/bin/podman ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
      echo "📦 Buzz is already running!"
      echo "🚪 Entering buzz container..."
      exec ${pkgs.podman}/bin/podman exec -it $CONTAINER_NAME bash
    fi

    if ${pkgs.podman}/bin/podman ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
      echo "🔄 Starting existing buzz container..."
      ${pkgs.podman}/bin/podman start $CONTAINER_NAME
      echo "🚪 Entering buzz container..."
      exec ${pkgs.podman}/bin/podman exec -it $CONTAINER_NAME bash
    fi

    echo "🏗️  Building buzz container..."
    if ! ${pkgs.podman}/bin/podman images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^$IMAGE_NAME$"; then
      echo "📦 Loading Fresh buzz container image..."
      ${pkgs.podman}/bin/podman load < ${buzzContainer}
      ${pkgs.podman}/bin/podman tag buzz:latest $IMAGE_NAME
    fi

    echo "🚀 Starting new buzz container..."

    mkdir -p ~/.local/share/buzz/{home,ssh}

    # Podman rootless run (more secure than Docker's privileged mode)
    ${pkgs.podman}/bin/podman run -d \
      --name $CONTAINER_NAME \
      --hostname buzz \
      --network host \
      --userns=keep-id \
      --security-opt label=disable \
      -v ~/.local/share/buzz/home:/home:Z \
      -v ~/.local/share/buzz/ssh:/etc/ssh:Z \
      -v /run/podman/podman.sock:/run/podman/podman.sock:Z \
      $IMAGE_NAME \
      /sbin/init

    echo "⏳ Waiting for buzz to be ready..."
    sleep 3

    echo "🚪 Entering buzz container..."
    exec ${pkgs.podman}/bin/podman exec -it $CONTAINER_NAME bash
  '';

  # Buzz cleanup utility (Podman version)
  buzz-clean = pkgs.writeShellScriptBin "pbuzz-clean" ''
    set -euo pipefail

    echo "🧹 Cleaning up buzz container (Podman)..."

    if ${pkgs.podman}/bin/podman ps -a --format "table {{.Names}}" | grep -q "^buzz-spacedock$"; then
      echo "🛑 Stopping and removing buzz container..."
      ${pkgs.podman}/bin/podman stop buzz-spacedock || true
      ${pkgs.podman}/bin/podman rm buzz-spacedock || true
    fi

    if ${pkgs.podman}/bin/podman images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^buzz:latest$"; then
      echo "🗑️  Removing buzz image..."
      ${pkgs.podman}/bin/podman rmi buzz:latest || true
    fi

    if [ -d ~/.local/share/buzz ]; then
      echo "🗑️  Removing persistent buzz data..."
      rm -rf ~/.local/share/buzz
    fi

    echo "✅ Buzz cleanup complete!"
  '';

  # Buzz status checker (Podman version)
  buzz-status = pkgs.writeShellScriptBin "pbuzz-status" ''
    echo "🐝 Buzz Container Status (Podman)"
    echo "================================="

    if ${pkgs.podman}/bin/podman ps --format "table {{.Names}}\t{{.Status}}" | grep -q "buzz-spacedock"; then
      echo "📦 Container: RUNNING"
      ${pkgs.podman}/bin/podman ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep buzz-spacedock
    elif ${pkgs.podman}/bin/podman ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "buzz-spacedock"; then
      echo "📦 Container: STOPPED"
      ${pkgs.podman}/bin/podman ps -a --format "table {{.Names}}\t{{.Status}}" | grep buzz-spacedock
    else
      echo "📦 Container: NOT CREATED"
    fi

    if ${pkgs.podman}/bin/podman images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^buzz:latest$"; then
      echo "🖼️  Image: EXISTS"
    else
      echo "🖼️  Image: NOT BUILT"
    fi

    echo ""
    echo "📊 Podman Info:"
    ${pkgs.podman}/bin/podman info --format "Rootless: {{.Host.Security.Rootless}}"
    ${pkgs.podman}/bin/podman info --format "Storage Driver: {{.Store.GraphDriverName}}"
  '';

  # Generate systemd service for buzz (Podman advantage)
  buzz-systemd = pkgs.writeShellScriptBin "pbuzz-systemd" ''
    set -euo pipefail

    echo "🔧 Generating systemd service for buzz container..."

    ${pkgs.podman}/bin/podman generate systemd \
      --new \
      --files \
      --name buzz-spacedock \
      --restart-policy=always || {
      echo "⚠️  Container must be running to generate systemd unit"
      echo "Run 'nix run .#buzz' first to create the container"
      exit 1
    }

    echo "✅ Systemd unit files generated!"
    echo "📁 Files created in current directory:"
    ls -la container-*.service 2>/dev/null || echo "No service files found"

    echo ""
    echo "To install as user service:"
    echo "  mkdir -p ~/.config/systemd/user/"
    echo "  cp container-*.service ~/.config/systemd/user/"
    echo "  systemctl --user daemon-reload"
    echo "  systemctl --user enable container-buzz-spacedock.service"
  '';
}
