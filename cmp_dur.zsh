#!/bin/zsh

# compare length - dont overwrite if they are not within a second 
cmp_dur() 
{   
    org_dur=$(ffprobe -v error -select_streams v:0 -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$1") 
    new_dur=$(ffprobe -v error -select_streams v:0 -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$2") 
    dur_diff=$((new_dur-org_dur)) 
    dur_diff=${dur_diff#-} # take absolute value 
}
