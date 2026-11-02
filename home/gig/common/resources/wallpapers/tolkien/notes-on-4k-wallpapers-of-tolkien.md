# The wonderful 4k wallpapers of Tolkien's world:

These items were found The desktop wallpapers are NOT 4k, I am awaiting a
response from the OG poster to download those versions as of 2/6/2026
[here](https://www.reddit.com/r/lotr/comments/1gyvtbs/4k_the_lord_of_the_rings_wallpapers_horizontal/)

## Upscaled stand-ins

Until the real 4K versions arrive, `desktop/upscaled/` holds 4x AI upscales of
the 1080x607 originals (4320x2428), made with Real-ESRGAN
(`nix shell nixpkgs#realesrgan-ncnn-vulkan`, model `realesrgan-x4plus-anime`,
which kept edges and ember detail better than `realesrgan-x4plus` or Lanczos)
and saved as webp q92. Replace them with the genuine 4K art when available.

    realesrgan-ncnn-vulkan -i in.png -o out.png -n realesrgan-x4plus-anime -s 4
