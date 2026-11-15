# Lost Keep — Shrine Hall

Eight new sheets based on the attached hall mockup X and palette B. Stone uses the region-specific pale blue-grey direction; the later instruction for muted brick roots takes precedence over the repeated generic ban. There are no live characters. Hooded figures are carved statues.

## Export checks

Exact requested canvas sizes. SH1–SH7 use flat8×8 colour blocks aligned top-left; SH8 uses4×4. SH1–SH7 have binary cutout transparency; SH8 is opaque. SH1 floor starts at y64 and its transparent gutter is y448–576; ceiling decorations end at1024. SH3 is placed on a nominal1920px-wide region with a top line at y640. Component isolation prevents adjacent cutouts bleeding into one another. Manifest rectangles describe exported piece bounds.

SH1 and SH8 opposite edge pixels match; SH2 wall first/last rows match. This boundary check is not a visual guarantee of seamless tiling.

## Remaining art work

Generated drafts, not certified production tiles. Exact corner mating and centre locations, four tones per material, statue height, fully straight collision silhouettes,192+96px shadow contours and seamless repeating block patterns need an artist pass. Some assets retain extra relief ornament, small top-plane cues, or a different block density from X. Cutout rectangles preserve requested nominal dimensions, but protruding foliage, pots and roots can reduce the walking span. SH3 architectural proportions differ from the requested640px statue. Shadow hearts are opaque void in SH1/SH2; shrine undersides still expose more lit masonry than specified.

Technical exports were normalized with nearest-neighbour sampling, which reduces source detail and is not hand-placed pixel authorship. The prompts and source-generation mode are included in prompts.json.
