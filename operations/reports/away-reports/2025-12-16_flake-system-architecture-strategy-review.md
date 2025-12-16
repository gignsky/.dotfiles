# Engineering Review: Flake System Architecture Strategy

**TO:** Captain **FROM:** Scotty, Engineering **DATE:** 2025-12-16 **SUBJECT:**
Analysis of `flake-utils` for Standardizing Multi-System Flake Outputs

## 1. Executive Summary

This review analyzes solutions for the boilerplate and complexity arising from
managing multi-system outputs in our Nix flakes, specifically within
`dot-spacedock` and in anticipation of its merge with the primary `~/.dotfiles`
repository.

The core problem is the repetitive and error-prone nature of defining outputs
for each architecture (e.g., `packages.x86_64-linux`, `packages.aarch64-linux`).
After reviewing the available tooling, this report makes the following
recommendations:

1. **Immediate (`dot-spacedock`):** As per your directive, we will implement a
   manual `forAllSystems` pattern (Option 3) to resolve the immediate undefined
   `system` issue without adding new dependencies.
2. **Short-Term (Post-Merge):** Adopt **`flake-utils`** for the merged
   `dotfiles` flake. Its `eachDefaultSystem` function provides a low-overhead,
   dependency-light solution that significantly cleans up boilerplate.
3. **Long-Term (`dotfiles` evolution):** Plan a future migration to
   **`flake-parts`**. It offers a more robust, modular framework that will be
   better suited for the high complexity of our multi-host, multi-user
   `dotfiles` configuration, though it comes with a steeper learning curve.

## 2. Introduction & Problem Statement

Our current `flake.nix` in `dot-spacedock` suffers from an undefined `system`
variable. This is a symptom of a larger architectural issue: the lack of a
standardized pattern for defining flake outputs across multiple system
architectures. Manually managing this with constructs like `packages.${system}`
is brittle and requires passing `system` explicitly through many layers of our
configuration.

As we plan to merge `dot-spacedock` into the main `dotfiles` repo
([gignsky/dotfiles](https://github.com/gignsky/dotfiles)), which supports
multiple hosts and architectures, adopting a scalable solution is critical.

## 3. Analysis of `flake-utils`

[flake-utils](https://github.com/numtide/flake-utils) is a lightweight, pure Nix
library designed specifically to reduce boilerplate in flakes. It does not
depend on `nixpkgs`.

#### Key Feature: `eachDefaultSystem`

The primary benefit of `flake-utils` is its `eachDefaultSystem` function. It
iterates over a curated list of the most common systems (`x86_64-linux`,
`aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`) and applies a user-provided
function to each.

**Without `flake-utils` (Manual approach):**

```nix
let
  systems = [ "x86_64-linux", "aarch64-linux" ];
  forAllSystems = lib.genAttrs systems;
in {
  packages = forAllSystems (system:
    let pkgs = import nixpkgs { inherit system; };
    in {
      default = pkgs.hello;
    }
  );
}
```

**With `flake-utils`:**

```nix
{
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.hello;
      }
    );
}
```

#### Benefits:

- **Reduced Boilerplate:** Eliminates the need for manual `lib.genAttrs` and
  system list management.
- **Simplicity & Readability:** Flake outputs become much cleaner and declare
  intent more directly.
- **Low Overhead:** It's a small, focused library, not a heavy framework.

## 4. Comparison with Alternatives

### A. Manual `forAllSystems` (Our "Option 3")

This is the traditional, dependency-free approach.

- **Pros:**
  - No external dependencies.
  - Explicit and gives full control over the systems list.
- **Cons:**
  - Verbose and repetitive.
  - The boilerplate we are actively trying to eliminate.

This is a perfectly valid, if simple, solution. It is suitable for our immediate
need in `dot-spacedock` as a self-contained fix.

### B. `flake-parts`

[flake-parts](https://github.com/hercules-ci/flake-parts) is a more
comprehensive and opinionated framework for building flakes. It introduces a
module system, similar to NixOS modules, for defining flake outputs.

- **Pros:**
  - **Highly Modular:** Excellent for managing complexity. Instead of one giant
    `outputs` function, you write small, self-contained modules for `packages`,
    `devShells`, etc.
  - **Implicit `system`:** The module system handles passing `system` and `pkgs`
    for you, making modules cleaner.
  - **Scalability:** This is its greatest strength. For a configuration as
    complex as our main `dotfiles` repo, `flake-parts` would enforce a clean,
    maintainable structure.
- **Cons:**
  - **Higher Learning Curve:** It's a full framework, not just a utility
    library.
  - **Opinionated:** It imposes a specific structure on your flake, which can
    feel restrictive initially.
  - (Note: My query to DeepWiki for `divnix/flake-parts` failed, indicating it
    may not be indexed yet. This analysis is based on general community
    knowledge.)

## 5. Recommendation & Path Forward

1. **Immediate Action:** We will proceed with your directive to use the manual
   `forAllSystems` pattern to fix the `flake.nix` in `dot-spacedock`. This is a
   sound tactical decision that resolves the immediate problem without
   introducing new dependencies before the merge.

2. **Strategic Adoption:** For the eventual merge into `dotfiles`, `flake-utils`
   presents the best balance of simplicity and power. It directly solves our
   boilerplate problem with minimal friction.

3. **Future Vision:** The `dotfiles` repo is the heart of our operations and its
   complexity will only grow. `flake-parts` is the correct long-term strategic
   choice for it. We should plan to migrate from `flake-utils` to `flake-parts`
   once the merged configuration begins to stabilize.

This phased approach allows us to solve today's problem efficiently while
setting a clear, scalable path for the future of our core infrastructure.
