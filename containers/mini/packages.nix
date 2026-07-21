# Mini Container Packages
# Base image packages for building Docker layered images. Ported from dot-spacedock.
# Requires the `nixos-generators` flake input to be present.

{
  inputs,
  lib,
  system,
}:

let
  pkgs = inputs.nixpkgs.legacyPackages.${system};

  # Import config components
  configVars = import ../../vars { inherit inputs lib; };
  configLib = import ../../lib { inherit lib; };
  overlays = import ../../overlays { inherit inputs; };

  outputs = {
    inherit overlays;
  };

  # Generate the mini base container using nixos-generators for a clean NixOS base
  miniContainer = inputs.nixos-generators.nixosGenerate {
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
    modules = [
      ./config.nix
    ];
    format = "docker";
  };

in
{
  # The base container image - use this as fromImage in dockerTools.buildLayeredImage
  mini-container = miniContainer;

  # Mini runner script for standalone usage
  mini = pkgs.writeShellScriptBin "mini" ''
    set -euo pipefail

    CONTAINER_NAME="mini-nixos"
    IMAGE_NAME="mini:latest"

    echo "🔬 Mini - NixOS Base Container"
    echo "============================="

    if ${pkgs.docker}/bin/docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
      echo "📦 Mini is already running!"
      echo "🚪 Entering mini container..."
      exec ${pkgs.docker}/bin/docker exec -it $CONTAINER_NAME bash
    fi

    if ${pkgs.docker}/bin/docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
      echo "🔄 Starting existing mini container..."
      ${pkgs.docker}/bin/docker start $CONTAINER_NAME
      echo "🚪 Entering mini container..."
      exec ${pkgs.docker}/bin/docker exec -it $CONTAINER_NAME bash
    fi

    echo "🏗️  Building mini base container..."
    if ! ${pkgs.docker}/bin/docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^$IMAGE_NAME$"; then
      echo "📦 Loading NixOS base container image..."
      ${pkgs.docker}/bin/docker load < ${miniContainer}/tarball/nixos-system-x86_64-linux.tar.xz
      ${pkgs.docker}/bin/docker tag mini:latest $IMAGE_NAME
    fi

    echo "🚀 Starting base container..."

    ${pkgs.docker}/bin/docker run -d \
      --name $CONTAINER_NAME \
      --hostname mini \
      $IMAGE_NAME \
      /bin/bash -c "while true; do sleep 3600; done"

    echo "⏳ Waiting for mini to be ready..."
    sleep 2

    echo "🚪 Entering mini container..."
    echo "Note: This is a base NixOS container - perfect for extending with dockerTools.buildLayeredImage"
    exec ${pkgs.docker}/bin/docker exec -it $CONTAINER_NAME bash
  '';

  # Mini cleanup utility
  mini-clean = pkgs.writeShellScriptBin "mini-clean" ''
    set -euo pipefail

    echo "🧹 Cleaning up mini container..."

    if ${pkgs.docker}/bin/docker ps -a --format "table {{.Names}}" | grep -q "^mini-nixos$"; then
      echo "🛑 Stopping and removing mini container..."
      ${pkgs.docker}/bin/docker stop mini-nixos || true
      ${pkgs.docker}/bin/docker rm mini-nixos || true
    fi

    if ${pkgs.docker}/bin/docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^mini:latest$"; then
      echo "🗑️  Removing mini image..."
      ${pkgs.docker}/bin/docker rmi mini:latest || true
    fi

    echo "✅ Mini cleanup complete!"
  '';

  # Mini status and info
  mini-status = pkgs.writeShellScriptBin "mini-status" ''
    echo "🔬 Mini Base Container Status"
    echo "============================"

    if ${pkgs.docker}/bin/docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "mini-nixos"; then
      echo "📦 Container: RUNNING"
      ${pkgs.docker}/bin/docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}" | grep mini-nixos
    elif ${pkgs.docker}/bin/docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "mini-nixos"; then
      echo "📦 Container: STOPPED"
      ${pkgs.docker}/bin/docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep mini-nixos
    else
      echo "📦 Container: NOT CREATED"
    fi

    if ${pkgs.docker}/bin/docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -q "^mini:latest"; then
      echo "🖼️  Base Image: EXISTS"
      echo "📏 Image Size:"
      ${pkgs.docker}/bin/docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | head -1
      ${pkgs.docker}/bin/docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "^mini:latest"
    else
      echo "🖼️  Base Image: NOT BUILT"
    fi

    echo ""
    echo "💡 Usage as base image:"
    echo "   Use mini-container as 'fromImage' in dockerTools.buildLayeredImage"
    echo "   Example: fromImage = inputs.self.packages.x86_64-linux.mini-container;"
  '';
}
