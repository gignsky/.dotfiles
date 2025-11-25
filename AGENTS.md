# NixOS Configuration Repository Guidelines

## Agent Instructions
- **Keep this file current**: Agents should frequently suggest modifications to this AGENTS.md file when they discover changes that make it inaccurate or require updates to keep it current with the codebase.

## Build Commands
- **System rebuild**: `just rebuild` or `scripts/system-flake-rebuild.sh [HOST]`
- **Home Manager**: `just home` or `scripts/home-manager-flake-rebuild.sh [HOST]`
- **Full rebuild**: `just rebuild-full` (system + home)
- **Test rebuild**: `just rebuild-test`
- **Build packages**: `just build [TARGET]` or `nix build .#[package]`
- **Flake check**: `just check` or `nix flake check --keep-going`
- **Pre-commit**: `just pre-commit` or `pre-commit run --all-files`

## Code Style Guidelines
- **File naming**: Use kebab-case for .nix files (e.g., `hardware-configuration.nix`)
- **Imports**: Use relative paths with `./` prefix for local imports
- **Formatting**: Run `nixfmt-rfc-style` via pre-commit hooks
- **Comments**: Use `#` for comments, avoid inline comments on imports
- **Function params**: Use destructuring `{ pkgs, lib, ... }:` pattern
- **Packages**: Define in `home.packages = with pkgs; [ ... ];` lists
- **String interpolation**: Use `"${variable}"` syntax
- **Attributes**: Use dot notation for nested attributes where possible
- **Line length**: Keep lines reasonable, break long attribute lists
- **Error handling**: Use `lib.mkDefault` for overridable defaults
- **Documentation**: Include brief comments for complex configurations
