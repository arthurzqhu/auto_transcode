#!/bin/zsh

# output the codec
get_codec()
{   
   curr_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
      -of default=noprint_wrappers=1:nokey=1 "$1")

   curr_codectag=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_tag_string \
      -of default=noprint_wrappers=1:nokey=1 "$1")
}
