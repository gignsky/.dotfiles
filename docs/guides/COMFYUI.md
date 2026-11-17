# ComfyUI on ganoslal

ComfyUI runs as a system service on ganoslal and renders on the RTX 3060 Ti.
Open <http://localhost:8188> in a browser on that host; nothing is exposed
to the LAN.

| Piece | Where |
|---|---|
| Module (package override, service, models) | `hosts/common/optional/comfyui.nix` |
| Host wiring + GPU pin | `hosts/ganoslal/default.nix` |
| State: models, custom nodes, inputs, outputs, database | `/var/lib/comfyui/` |
| Generated images | `/var/lib/comfyui/output/` (readable by `gig` via the `comfyui` group) |
| Logs | `journalctl -u comfyui -f` |

## How it is built

Stable nixpkgs has no ComfyUI, so the package and the `services.comfyui`
module both come from the nixpkgs-unstable tree that gigpkgs pins. The
Python environment swaps torch for the prebuilt CUDA 13 wheel (`torch-bin`)
rather than compiling torch from source, and CUDA kernels in the rest of the
closure (NCCL) are compiled for the 3060 Ti's compute capability only.

CUDA 13 does not support the Maxwell GTX 970, so the service is pinned to
the 3060 Ti by GPU UUID with `CUDA_VISIBLE_DEVICES`. ComfyUI never sees the
older card.

Expect the first `just rebuild` after enabling it to take a while: it
downloads about 24 GB of model weights and builds the CUDA library closure
locally (unfree, so cache.nixos.org does not carry it).

## Models

Declared in the module and symlinked into `/var/lib/comfyui/models/checkpoints/`
at service start:

| File | What it is | Fits in 8 GB VRAM? |
|---|---|---|
| `sd_xl_base_1.0_0.9vae.safetensors` | SDXL 1.0 base, fp16, fixed VAE | Yes, comfortably |
| `flux1-schnell-fp8.safetensors` | FLUX.1 schnell, fp8, text encoders + VAE included | No, runs in low-VRAM offload mode (slower, works) |

To add a model, append an entry to `services.comfyui.models` with a pinned
HuggingFace `resolve/<commit>/<file>` URL. The SRI hash comes from the LFS
pointer without downloading the weights:

```bash
curl -sL https://huggingface.co/<repo>/raw/main/<file>
```

```bash
nix hash convert --hash-algo sha256 --to sri <oid-hex>
```

Files copied into `models/` by hand are left alone, but that needs `sudo`
since the directory belongs to the `comfyui` user.

## First image

1. Open <http://localhost:8188>. The default workflow (Load Checkpoint, CLIP
   Text Encode x2, KSampler, VAE Decode, Save Image) is what you want.
2. In **Load Checkpoint** pick `sd_xl_base_1.0_0.9vae.safetensors` for a
   fast first pass, or the Flux checkpoint for better composition and text.
3. SDXL settings that work: 1024x1024 latent, 25-30 steps, CFG 6-7, sampler
   `dpmpp_2m` with `karras`. Flux schnell: 1024x1024, 4 steps, CFG 1.0,
   sampler `euler`, scheduler `simple`.
4. Write the prompt, queue it. The output lands in
   `/var/lib/comfyui/output/` and in the Save Image node; right-click the
   image to save it anywhere.

Flux is the better bet when the image needs legible lettering; SDXL will
mangle words. For icon or avatar work, ask for a flat vector style, a single
subject, and a plain background, then upscale or trace the result.

## Custom nodes

ComfyUI Manager is in the environment, so nodes can be browsed and installed
from the UI; they land in `/var/lib/comfyui/custom_nodes/`. Nodes that need
extra Python packages cannot pip-install them (the environment is a read-only
Nix store path). Add those packages through `services.comfyui.extraPackages`
in the module instead.
