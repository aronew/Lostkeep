# Crypt stone after Y: first drafts (CY1 to CY5, and a seven-piece masses sheet)

Unchanged originals from the generator. Not in the game yet.

Judged against the fade rule (`FADE_RULE` in Book 1):

| Sheet | Fades into the dark? |
|---|---|
| CY1 floor and ceiling | Yes: lit cap row, lit courses, then darker courses brick by brick, ragged edge |
| CY2 wall and corners | **No**: the wall is lit evenly across its width and stops on a straight line; the four corners are thin L strips of evenly lit brick with no fade. Card rewritten (wall fades sideways, each corner a solid mass fading inward); regenerate |
| CY3 dark masonry | The fill: dark throughout, as asked |
| CY4 stairs, arcade, pier | To check when imported |
| CY5 ledges and broken ends | Yes on the big broken ends; small ledges are thin, which is fine |
| Seven-piece masonry | Yes: the best fades of the set (islands and broken piers) |

The canvases are not the sizes the cards ask for (e.g. CY1 2172 × 724, not
3072 × 1024), so their pixel scale has to be measured before they are reduced.

## CY2, second draft (`CY2_wall_and_corners_draft2.png`)

Fades now. The wall band fades sideways from its quoins into the dark, ragged
brick by brick (keep it). The outer floor corner (top left) and inner floor
corner (bottom left) are solid masses fading inward (keep them). Not right yet:
the top-right piece is a floor with a one-column pillar standing on it (no
mass behind the pillar), and the bottom-right piece is a wall with a ledge
jutting from it instead of an inner ceiling corner. There is no outer ceiling
corner. The ceiling corners are what to regenerate (or try the floor corners
flipped upside down in the game first).

## CY2b, the ceiling corners (`CY2b_ceiling_corners.png`)

Right first time. Outer ceiling corner (left cell: mass in the upper-left
quarter) and inner ceiling corner (right cell: open lower-right quarter), both
meeting at their cell's centre, both fading brick by brick toward the far
inside, moss hanging down. A true 8x grid (2048 x 1024 reduces losslessly to
256 x 128). Cut the corners close around the centre: the right cell's far
right edge has a column of quoins above the ceiling that a corner piece
should not include.

Before the set goes in, CY1 and CY2's wall band need the same clean 8x grid
(their drafts are resampled, not on whole pixels).
