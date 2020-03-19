# ffmpeg-cheatsheet
Common operations with ffmpeg

Unless otherwise noted, these commands assume Windows + Powershell.

### GIF from frames with single palette

This creates a lightweight, optimized GIF file with one palette. Useful when color is consistent across frames. 

    ffmpeg -y -i frames_%05d.png -vf palettegen palette.png
    
This generates a palette file from the *first frame* of the sequence.

GIF can then be generated from files:

    ffmpeg -r 6 -y -i frames_%05d.png -i palette.png -filter_complex "paletteuse" animation.gif

`-r` defines the fps rate for the GIF.
`-y` auto-overwrites previous existing files.
`frames_%05d.png` assumes a filename with a suffix of 5 padded digits.

### Speeding video up

    ffmpeg -i input.mp4 -an -filter:v "setpts=0.1*PTS" output.mp4

`0.1` accelerates x10 by dropping frames, `0.01` would accelerate x100 and so on.
`-an` removes audio.

### Lossless cropping/trimming

    ffmpeg -i input.mp4 -ss 00:00:00 -to 01:30:15 -c:v copy -c:a copy output.mp4

Omit the `-to` parameter to trim till the end. Use `-t` parameter instead to specify duration (not end time). 
