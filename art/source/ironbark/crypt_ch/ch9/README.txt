Lost Keep — terrain bands

3072x2048 RGBA; logical grid 384x256; every cell exactly 8x8.
All alpha values are 0 or 255. See atlas.json for exact piece rectangles.
Three full-width bands are 3072x512, separated by transparent 64px gutters.
Two step pieces are 512x320; each transition is 128px.
Repeat each band by its full 3072px width. Repeat-boundary cells match.
The native 384x256 companion is identical cell data for direct import.

Artwork began with image generation and was rebuilt onto the native grid: edge geometry, alpha, palette and periodic joins were corrected. This is not an untouched native-size image-generator export. Palette limitation and grid reduction simplify fine details compared with the room mockup.
