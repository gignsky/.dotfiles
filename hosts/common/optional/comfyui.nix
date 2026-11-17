# ComfyUI -- node-graph image generation (Stable Diffusion / Flux), run as a
# hardened systemd service and served on http://localhost:8188.
#
# Why this is wired the way it is:
#
# * Stable nixpkgs (26.05) carries neither the `comfyui` package nor the
#   `services.comfyui` NixOS module. Both live in nixpkgs-unstable, which
#   gigpkgs pins as its own `nixpkgs` input. The module file is imported
#   straight out of that unstable checkout, and `pkgs.comfyui` is overlaid so
#   the module's own `package` default and `meta.maintainers` resolve against
#   the stable `pkgs` it is evaluated with.
#
# * The stock package builds torch for CPU only. Compiling torch with CUDA for
#   this card is a multi-hour, uncached build, so the Python env swaps in the
#   prebuilt `torch-bin` / `torchvision-bin` wheels (CUDA 13) instead. They find
#   the driver's libcuda through /run/opengl-driver at runtime, which
#   `hardware.graphics` already provides on every GPU host.
#
# * Those wheels still pull nixpkgs' CUDA libraries in, and NCCL among them is
#   compiled from source for every capability in the list. gigpkgs' shared
#   `pkgs.unstable` fixes that list at the default ten generations, so this
#   module imports its own unstable instance with only the card we have.
#
# * CUDA 13 dropped Maxwell. On ganoslal that means ComfyUI only sees the
#   RTX 3060 Ti (8 GB); the GTX 970 is hidden from it outright by the
#   CUDA_VISIBLE_DEVICES pin in hosts/ganoslal/default.nix. This loads
#   nvidia_uvm for real work -- see the Discord/NVENC freeze notes in
#   hosts/ganoslal if the machine locks up mid-render.
#
# * The service runs as its own `comfyui` user with state in /var/lib/comfyui
#   (models/, custom_nodes/, input/, output/). The unit's StateDirectory mode
#   is loosened to 0750 and the main user is added to the `comfyui` group so
#   generated images can be read without sudo. The web UI also serves them.
#
# Models are declared below and fetched at build time as fixed-output
# derivations (pinned HuggingFace revision URLs, sha256 from the LFS pointer),
# then symlinked into models/<dir>/. Anything dropped into models/ by hand is
# left alone. Both models here are ungated downloads.
{
  inputs,
  lib,
  configVars,
  ...
}:
let
  # gigpkgs is a wrapper flake; its `nixpkgs` input is the real nixpkgs-unstable tree.
  unstableNixpkgs = inputs.nixpkgs-unstable.inputs.nixpkgs;

  # Compute capabilities to compile CUDA kernels for. Add to this when the
  # module is imported on a host with a different card.
  cudaCapabilities = [
    "8.6" # RTX 3060 Ti (Ampere)
  ];

  # HuggingFace sources, pinned to the repo revision that was current when added.
  hf =
    repo: rev: file:
    "https://huggingface.co/${repo}/resolve/${rev}/${file}";
in
{
  imports = [ "${unstableNixpkgs}/nixos/modules/services/misc/comfyui.nix" ];

  nixpkgs.overlays = [
    (
      final: _prev:
      let
        unstable = import unstableNixpkgs {
          inherit (final.stdenv.hostPlatform) system;
          config = {
            allowUnfree = true;
            inherit cudaCapabilities;
          };
        };
      in
      {
        comfyui = unstable.comfyui.override {
          python3 = unstable.python3.override {
            packageOverrides = _: prev: {
              torch = prev.torch-bin;
              torchvision = prev.torchvision-bin;
            };
          };
        };
      }
    )
  ];

  services.comfyui = {
    enable = true;

    # ComfyUI Manager: browse/install custom nodes from the UI. Node repos land
    # in /var/lib/comfyui/custom_nodes; anything needing extra pip packages has
    # to be added through `extraPackages` here instead, the env is read-only.
    extraPackages = ps: [ ps.comfyui-manager ];

    extraArgs = [
      "--preview-method=auto" # live latent previews while sampling
    ];

    models = [
      # SDXL 1.0 base, fp16 with the fixed 0.9 VAE baked in (~6.9 GB). Fits the
      # 3060 Ti's 8 GB outright; the dependable first choice for logos/icons.
      {
        name = "sd_xl_base_1.0_0.9vae.safetensors";
        url =
          hf "stabilityai/stable-diffusion-xl-base-1.0" "462165984030d82259a11f4367a4eed129e94a7b"
            "sd_xl_base_1.0_0.9vae.safetensors";
        hash = "sha256-5rueqFu/e/ZHinxtGLcSRvIuldQbzdgO1AqiEsM8/v8=";
        installPaths = "checkpoints";
      }
      # FLUX.1 schnell, fp8 all-in-one checkpoint from Comfy-Org (~17 GB; UNet,
      # both text encoders and VAE in one file, so the plain "Load Checkpoint"
      # node works). Much better at composition and legible text than SDXL,
      # 4 steps per image. Over 8 GB of VRAM it runs in ComfyUI's low-VRAM
      # offload mode -- slower, but it works with the 46 GB of system RAM here.
      {
        name = "flux1-schnell-fp8.safetensors";
        url =
          hf "Comfy-Org/flux1-schnell" "d31e04067066d92c55ece2b01748dcc337725d7a"
            "flux1-schnell-fp8.safetensors";
        hash = "sha256-6tQmJ4tJAw6dpd+GKZTyXOlKsu5N84tVbd3bPbCTv3I=";
        installPaths = "checkpoints";
      }
    ];
  };

  # Let the main user read generated images straight from /var/lib/comfyui/output.
  systemd.services.comfyui.serviceConfig.StateDirectoryMode = lib.mkForce "0750";
  users.users.${configVars.username}.extraGroups = [ "comfyui" ];
}
