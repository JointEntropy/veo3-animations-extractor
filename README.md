
## How to use 

Run `extract_from_veo.sh` extract for example media


## Description

Simple scripts pipeline for extracting animation spritesheets from veo3 generated character animations.

It uses set of ffmpeg operations.

Overall steps are the following:
1. truncate specific  region of mp4 file and get new mp4 file with specified truncated area
2. convert result of step 1 to frames as png files in folder in the size of 256/256
3. convert frames into animation spritesheet grid(of fixed size 2048/2048)
