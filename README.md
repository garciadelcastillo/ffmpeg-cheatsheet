# ffmpeg-cheatsheet

Common operations with [ffmpeg](https://www.ffmpeg.org/). For the love of me, I can never remember them off the top of my head... :sweat_smile:

Unless otherwise noted, these commands assume `Windows` + `Powershell`.

Check [this guide](https://nono.ma/ffmpeg-and-imagemagick-guide) by [@nonoesp](https://github.com/nonoesp) for other cool tricks. [This guide](https://github.com/uclaconditional/video-and-image-cli) is also good for advanced compression commands. 

Check out my other [ImageMagick cheatsheet](https://github.com/garciadelcastillo/imagemagick-cheatsheet) too.

### Extract frames from video

    ffmpeg -i input.mp4 frames/frame_%05d.png

This will take an input video, and export all frames to a folder in the video's native fps. Please note that the folder must exist.

Frames can be rescaled on the fly, and image quality controlled. This example will downsample to `1024` px width and scale the height proportionally, and set jpeg quality to best ([2 best-32 worst range](https://stackoverflow.com/a/10234065)):

    ffmpeg -i input.mp4 -vf scale=1024:-1 -qscale:v 2 frames/frame_%05d.jpg

### Video from frames

    ffmpeg -framerate 30 -i frame_%05d.png output.mp4

`-framerate 30` sets the rate for the *input stream*.  
`frame_%05d.png` assumes a filename with a suffix of 5 padded digits.

To force a particular codec, use `-vf format=`:

    ffmpeg -framerate 30 -i frame_%05d.png -vf format=yuv420p output.mp4

If setting a different fps, force `ffmpeg` to not drop frames by matching the *input* and *output* streams rates:

    ffmpeg -framerate 15 -i frame_%05d.png -r 15 output.mp4

Frames can also be duplicated by setting faster output fps (IG won't let me publish videos at 5fps 😭😭):

    ffmpeg -r 5 -i frame_%05d.png -r 30 -vf format=yuv420p output.mp4 

Alternatively, a video can be "accelerated" by purposedly dropping frames, setting different *input* and *output* streams rates. This example accelerates the video by x10, still creating it at `30fps`:

    ffmpeg -framerate 300 -i frame_%05d.png -r 30 output.mp4

### GIF from frames with single palette

This creates a lightweight, optimized GIF file with one palette. Useful when color is consistent across frames. 

    ffmpeg -y -i frame_%05d.png -vf palettegen palette.png
    
The above generates a palette file from the *first frame* of the sequence.

GIF can then be generated from files:

    ffmpeg -r 5 -y -i frame_%05d.png -i palette.png -filter_complex "paletteuse" animation.gif

`-r` defines the fps rate for the GIF.
`-y` auto-overwrites previous existing files.

### GIF from frames with multiple palettes

When color varies significantly across frames in the input, it is better to create one palette per frame; better quality GIF, heavier file:

    ffmpeg -r 5 -i frame_%05d.png -filter_complex "[0:v] split [a][b];[a] palettegen=stats_mode=single [p];[b][p] paletteuse=new=1" animation.gif

Taken from this [article](https://medium.com/@Peter_UXer/small-sized-and-beautiful-gifs-with-ffmpeg-25c5082ed733).

### GIF from video

Similarly to before, GIFs can be created directly from video. 

    ffmpeg -i input.mp4 -vf "fps=10,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 output.gif

See [more options here](https://superuser.com/a/556031).

### Speeding video up

    ffmpeg -i input.mp4 -an -filter:v "setpts=0.1*PTS" output.mp4

`0.1` accelerates x10 by dropping frames, `0.01` would accelerate x100 and so on.
`-an` removes audio.

New frames can be added using motion interpolation via `minterpolate`:

    ffmpeg -i input_30fps.mp4 -filter:v minterpolate -r 60 outut_60fps.mp4

This can work too when creating a video from frames, but if they are not related, result is wonky:

    ffmpeg -r 4 -i .\frame_%05d.png -filter:v minterpolate -r 30 output.mp4

Alternatively, [Butterflow](https://github.com/dthpham/butterflow) is also an option...

### Extreme video compression

Sometimes, it is useful to compress a video to a very lossy output, like when editing very HQ files.

    ffmpeg -i input.mp4 -c:v libx264 -crf 51 -preset veryslow -c:a copy -r 30 ouptut.mp4

This example sets quality to terrible (`-crf` from `0` best quality to `51` worst),  and drops frames to 30fps. Remove the `-preset` to trade speed of a few extra bytes. 

### Lossless cropping/trimming

    ffmpeg -i input.mp4 -ss 00:00:00 -to 01:30:15 -c:v copy -c:a copy output.mp4

Omit the `-to` parameter to trim till the end. Use `-t` parameter instead to specify duration (not end time). 
@RamyAydarous notes that this method [doesn't start the trim from the previous keyframe](https://github.com/mifi/lossless-cut/pull/13), and therefore generates an initial static frame that extends into the next keyframe. Switch the order of `-ss` and `-i` parameters to force trim from previous keyframe (see [here](https://trac.ffmpeg.org/wiki/Seeking) end of the page).

### Changing video size

    ffmpeg -i input.mp4 -vf scale=960:540 -c:v libx264 smaller.mp4
    
Taken from [here](https://reiners.io/downscaling-4k-video-with-ffmpeg/).

### Reversing video (and audio)
    
    ffmpeg -i input.mp4 -vf reverse -af areverse reversed.mp4

Apparently, this buffers the entire clip, so for long ones, chop it, reverse them and concat. 

### Looping video

A video can be looped by "multiplying" the input stream:

    ffmpeg -stream_loop 2 -i frame_%03d.png landscape_loop.mp4
    
The above will generate a video with the frames repeating 3 times (the regular one + `-stream_loop 2`). 

You can create _boomerang_ effect by applying `reverse` and `loop` filters:

    ffmpeg -framerate 30 -i Frame_%05d.png -filter_complex "[0]reverse[r];[0][r]concat,loop=2:244,setpts=N/30/TB" output.mp4

Where `30` is the fps, and `2:224` is the `number of extra loops:2 * frames per video`. 

Simpler 1-loop boomerang `gif` with `palette`:

    ffmpeg -framerate 30 -i Frame_%05d.png -filter_complex "[0]reverse[r];[0][r]concat,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" boomerang_palette.gif



### Concat video: from the same source

Concattenating a list of videos from the same source **(same format and codecs)** can be done fast with the [concat demuxer](https://trac.ffmpeg.org/wiki/Concatenate#demuxer) without needing to reencode them. 

Concat all `*.mp4` (same dimensions & codecs) into a single file (bash/sh):

    ffmpeg -f concat -safe 0 -i <(for f in ./*.mp4; do echo "file '$PWD/$f'"; done) -c copy output.mp4

Alternatively, create a `playlist.txt` file with the names of the files to `concat` (PS): 

    foreach ($i in Get-ChildItem .\*.mp4) {echo "file '$i'" >> playlist.txt}

If using CMD:

    (for %i in (*.mp4) do @echo file '%i') > playlist.txt
    
Files can now be stitched:

    ffmpeg -f concat -i playlist.txt -c copy output.mp4

### Concat video: from different sources

If videos come from different sources and/or have different formats/codecs, it is necessary to [reencode them](https://trac.ffmpeg.org/wiki/Concatenate#differentcodec). For three files, it would look like this:

    ffmpeg -i 01.mp4 -i 02.mp4 -i 03.mp4 -filter_complex "[0:v:0][0:a:0][1:v:0][1:a:0][2:v:0][2:a:0]concat=n=3:v=1:a=1[outv][outa]" -map "[outv]" -map "[outa]" output.mp4
    
Unfortunately, there is no way a `playlist.txt` file can be fed as input for longer lists; the whole call must be programmatically generated. Also, PowerShell has a 8191 char max limit... 

This repo contains `concat_generator` a Processing sketch that points to a folder, and generates a `concat.bat` file with a bash call to concat all video files in that folder. Remember to change the allowed extensions in the Processing file.

### Batch process a bunch of files in a folder

Say you want to reencode a bunch of `mp4` files in a folder. `Powershell` doesn't take `-pattern_type glob`... So, a possible batch process could be this:

    foreach ($i in Get-ChildItem .\*.mp4) {ffmpeg -i $i.Name $i.Name.Replace(".mp4","_lite.mp4")}

Takes al `mp4` files in a folder, and reencodes them with a suffix. I know, this is hideous, but it works! :sweat_smile:

### Creating a mosaic/montage/collage of images

For this one, use Imagemagick :)

    magick montage *.png -geometry 224x224 -tile 27x14 montage.png

Creates a 27x14 collage with the stills. Margins can be added to the `geometry` parameter, as well as background and borders:

    magick montage *.png -geometry 256x128>+10+5 -tile 12x10 -background white -border 1 -bordercolor lightgray montage.png

The `>` operator reduces images only bigger than `256x128`.

### Creating a mosaic/montage/collage of videos

The following code produces a 3x3 collage of videos at 1920x1080:

    ffmpeg -i .\videos\01.mp4 -i .\videos\02.mp4 -i .\videos\03.mp4 -i .\videos\04.mp4 -i .\videos\05.mp4 -i .\videos\06.mp4 -i .\videos\07.mp4 -i .\videos\08.mp4 -i .\videos\09.mp4 -filter_complex " [0:v] setpts=PTS-STARTPTS, scale=640:320 [a0]; [1:v] setpts=PTS-STARTPTS, scale=640:320 [a1]; [2:v] setpts=PTS-STARTPTS, scale=640:320 [a2]; [3:v] setpts=PTS-STARTPTS, scale=640:320 [a3]; [4:v] setpts=PTS-STARTPTS, scale=640:320 [a4]; [5:v] setpts=PTS-STARTPTS, scale=640:320 [a5]; [6:v] setpts=PTS-STARTPTS, scale=640:320 [a6]; [7:v] setpts=PTS-STARTPTS, scale=640:320 [a7]; [8:v] setpts=PTS-STARTPTS, scale=640:320 [a8]; [a0][a1][a2][a3][a4][a5][a6][a7][a8]xstack=inputs=9:layout=0_0|w0_0|w0+w1_0|0_h0|w0_h0|w0+w1_h0|0_h0+h1|w0_h0+h1|w0+w1_h0+h1[out]" -map "[out]" -c:v libx264 -t '30' -f matroska mosaic.mp4

Yes, each video needs to be manually in the command. Things are easy to replace on a text editor though. From [here](https://trac.ffmpeg.org/wiki/Create%20a%20mosaic%20out%20of%20several%20input%20videos%20using%20xstack).

### Check properties of a video

This prints out the **duration** of a video in seconds, like `18.544322` ([more](https://superuser.com/a/945604/896030)):

    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4

This prints out the **framerate** of a video, like `30/1`:

    ffprobe -v 0 -of csv=p=0 -select_streams v:0 -show_entries stream=r_frame_rate input.mp4

The following prints out the **timestamps for the keyframes** of a video ([source](https://stackoverflow.com/a/30982414/1934487)):

    ffprobe -loglevel error -skip_frame nokey -select_streams v:0 -show_entries frame=pkt_pts_time -of csv=print_section=0 input.mp4

General **metadata** of a file can be exported to text:

    ffmpeg -i input.mp4 -f ffmetadata metadata.txt

### Replacing the sound track on a video

Or in other words, extracting the audio track of a video, removing it and adding a new one. Thanks @arastoo for the pointers!

First of all, and to avoid transcoding, you should check the audio file type that the video file contains:

    ffprobe video.mp4
    
Once the file format is determined, extract sound the file without re-encoding:

    ffmpeg -i video.mp4 -vn -acodec copy oldAudio.aac

Remove the audio file from the video:

    ffmpeg -i video.mp4 -c copy -an videoNoSound.mp4

And now just add new audio to that file:

    ffmpeg -i videoNoSound.mp4 -i newAudio.mp3 -c:v copy -c:a copy videoWithNewSound.mp4

[This guide](https://gist.github.com/protrolium/e0dbd4bb0f1a396fcb55) has lots of `ffmpeg` audio-related tips!

### Add dummy silent audio to video

`concat` has given me problems when adding a video with no sound (like a timelapse). This adds a dummy silent track (taken from [here](https://stackoverflow.com/a/12375018/1934487)):

    ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -i input.mp4 -c:v copy -c:a aac -shortest output.mp4

## Add watermark to the video

Piece of cake ([more info](https://gist.github.com/bennylope/d5d6029fb63648582fed2367ae23cfd6)):

    ffmpeg -i test.mp4 -i watermark.png -filter_complex "overlay=10:10" test1.mp4
