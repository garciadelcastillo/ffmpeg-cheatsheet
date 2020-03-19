# ffmpeg-cheatsheet

Common operations with ffmpeg. Unless otherwise noted, these commands assume Windows + Powershell.

Check [this guide](https://nono.ma/ffmpeg-and-imagemagick-guide) by [@nonoesp](https://github.com/nonoesp) for other cool tricks.

### Extract frames from video

    ffmpeg -i input.mp4 frames/frame_%05d.png

This will take an input video, and export all frames to a folder in the video's native fps. Please note that the folder must exist.

### Video from frames

    ffmpeg -framerate 30 -i frame_%05d.png output.mp4

`-framerate 30` sets the rate for the *input stream*.  
`frame_%05d.png` assumes a filename with a suffix of 5 padded digits.

If setting a different fps, force `ffmpeg` to not drop frames by matching the *input* and *output* streams reates:

    ffmpeg -framerate 15 -i frame_%05d.png -r 15 output.mp4

Alternatively, a video can be "accelerated" by purposedly dropping frames, setting different *input* and *output* streams reates. This example accelerates the video by x10, still creating it at `30fps`:

    ffmpeg -framerate 300 -i frame_%05d.png -r 30 output.mp4

### GIF from frames with single palette

This creates a lightweight, optimized GIF file with one palette. Useful when color is consistent across frames. 

    ffmpeg -y -i frame_%05d.png -vf palettegen palette.png
    
This generates a palette file from the *first frame* of the sequence.

GIF can then be generated from files:

    ffmpeg -r 5 -y -i frame_%05d.png -i palette.png -filter_complex "paletteuse" animation.gif

`-r` defines the fps rate for the GIF.
`-y` auto-overwrites previous existing files.

### GIF from frames with multiple palettes

When color varies significantly across frames in the input, it is better to create one palette per frame; better quality GIF, heavier file.

    ffmpeg -r 5 -i frame_%05d.png -filter_complex "\[0:v] split [a\][b];\[a] palettegen=stats_mode=single [p];[b\][p] paletteuse=new=1" animation.gif

Taken from this [article](https://medium.com/@Peter_UXer/small-sized-and-beautiful-gifs-with-ffmpeg-25c5082ed733).

### Speeding video up

    ffmpeg -i input.mp4 -an -filter:v "setpts=0.1*PTS" output.mp4

`0.1` accelerates x10 by dropping frames, `0.01` would accelerate x100 and so on.
`-an` removes audio.

### Lossless cropping/trimming

    ffmpeg -i input.mp4 -ss 00:00:00 -to 01:30:15 -c:v copy -c:a copy output.mp4

Omit the `-to` parameter to trim till the end. Use `-t` parameter instead to specify duration (not end time). 

### Downscaling 4k video

    ffmpeg -i input.mp4 -vf scale=1920:1080 -c:v libx264 smaller.mp4
    
Taken from [here](https://reiners.io/downscaling-4k-video-with-ffmpeg/).

### Reversing video (and audio)
    
    ffmpeg -i input.mp4 -vf reverse -af areverse reversed.mp4

Apparently, this buffers the entire clip, so for long ones, chop it, reverse them and concat. 

### Concat video: from the same source

Concattenating a list of videos from the same source (same format and codecs) can be done fast with the [concat demuxer](https://trac.ffmpeg.org/wiki/Concatenate#demuxer) without needing to reencode them. 

First, create a `playlist.txt` file with the names of the files to `concat` (PS): 

    foreach ($i in Get-ChildItem .\*.mp4) {echo "file '$i'" >> playlist.txt}

If using CMD:

    (for %i in (*.mp4) do @echo file '%i') > playlist.txt
    
Files can now be stitched:

    ffmpeg -f concat -i playlist.txt -c copy D:\output.mp4

### Concat video: from different sources

If videos come from different sources and/or have different formats/codecs, it is necessary to [reencode them](https://trac.ffmpeg.org/wiki/Concatenate#differentcodec). For three files, it would look like this:

    ffmpeg -i 01.mp4 -i 02.mp4 -i 03.mp4 -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0][2:v:0][2:a:0]concat=n=3:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" output.mp4
    
Unfortunately, there is no way a `playlist.txt` file can be fed as input for longer lists; the whole call must be programmatically generated. Also, PowerShell has a 8191 char max limit... 

This repo contains `concat_generator` a Processing sketch that points to a folder, and generates a `concat.bat` file with a bash call to concat all video files in that folder. Remember to change the allowed extensions in the Processing file.
