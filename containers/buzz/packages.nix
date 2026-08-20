# Buzz Container Packages (Docker version)
# All buzz-related packages and utilities. Ported from dot-spacedock.
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

  # Generate the buzz container image with proper specialArgs
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
      inherit (inputs) nixpkgs;
    };
    modules = [ ./config.nix ];
    format = "docker";
  };

in
{
  # The container image itself
  buzz-container = buzzContainer;

  # Main buzz runner
  buzz = pkgs.writeShellScriptBin "buzz" ''
    set -euo pipefail

    CONTAINER_NAME="buzz-spacedock"
    IMAGE_NAME="buzz:latest"

    echo "🐝 Buzz - Containerized Spacedock"
    echo "=================================="

    # Check if container is already running
    if ${pkgs.docker}/bin/docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
      echo "📦 Buzz is already running!"
      echo "🚪 Entering buzz container..."
      exec ${pkgs.docker}/bin/docker exec -it $CONTAINER_NAME bash
    fi

    # Check if container exists but is stopped
    if ${pkgs.docker}/bin/docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
      echo "🔄 Starting existing buzz container..."
      ${pkgs.docker}/bin/docker start $CONTAINER_NAME
      echo "🚪 Entering buzz container..."
      exec ${pkgs.docker}/bin/docker exec -it $CONTAINER_NAME bash
    fi

    # Build fresh container if needed
    echo "🏗️  Building buzz container..."
    if ! ${pkgs.docker}/bin/docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^$IMAGE_NAME$"; then
      echo "📦 Loading Fresh buzz container image..."
      ${pkgs.docker}/bin/docker load < ${buzzContainer}/tarball/nixos-system-x86_64-linux.tar.xz
    fi

    # Create and start new container
    echo "🚀 Starting new buzz container..."

    # Create persistent data directories
    mkdir -p ~/.local/share/buzz/{home,ssh}

    ${pkgs.docker}/bin/docker run -d \
      --name $CONTAINER_NAME \
      --hostname buzz \
      --privileged \
      --network host \
      -v ~/.local/share/buzz/home:/home \
      -v ~/.local/share/buzz/ssh:/etc/ssh \
      -v /var/run/docker.sock:/var/run/docker.sock \
      $IMAGE_NAME \
      /sbin/init

    # Wait for container to be ready
    echo "⏳ Waiting for buzz to be ready..."
    sleep 3

    echo "🚪 Entering buzz container..."
    exec ${pkgs.docker}/bin/docker exec -it $CONTAINER_NAME bash
  '';

  # Buzz cleanup utility
  buzz-clean = pkgs.writeShellScriptBin "buzz-clean" ''
    set -euo pipefail

    echo "🧹 Cleaning up buzz container..."

    if ${pkgs.docker}/bin/docker ps -a --format "table {{.Names}}" | grep -q "^buzz-spacedock$"; then
      echo "🛑 Stopping and removing buzz container..."
      ${pkgs.docker}/bin/docker stop buzz-spacedock || true
      ${pkgs.docker}/bin/docker rm buzz-spacedock || true
    fi

    if ${pkgs.docker}/bin/docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^buzz:latest$"; then
      echo "🗑️  Removing buzz image..."
      ${pkgs.docker}/bin/docker rmi buzz:latest || true
    fi

    if [ -d ~/.local/share/buzz ]; then
      echo "🗑️  Removing persistent buzz data..."
      rm -rf ~/.local/share/buzz
    fi

    echo "✅ Buzz cleanup complete!"
  '';

  # Buzz status checker
  buzz-status = pkgs.writeShellScriptBin "buzz-status" ''
    echo "🐝 Buzz Container Status"
    echo "======================="

    if ${pkgs.docker}/bin/docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "buzz-spacedock"; then
      echo "📦 Container: RUNNING"
      ${pkgs.docker}/bin/docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep buzz-spacedock
    elif ${pkgs.docker}/bin/docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "buzz-spacedock"; then
      echo "📦 Container: STOPPED"
      ${pkgs.docker}/bin/docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep buzz-spacedock
    else
      echo "📦 Container: NOT CREATED"
    fi

    if ${pkgs.docker}/bin/docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^buzz:latest$"; then
      echo "🖼️  Image: EXISTS"
    else
      echo "🖼️  Image: NOT BUILT"
    fi
  '';
}
