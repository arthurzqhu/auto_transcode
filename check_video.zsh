#!/bin/zsh

# check if the input is video
check_video()
{
    if [[ "$1" == *.mkv || "$1" == *.mp4 || "$1" == *.avi || "$1" == *.wmv \
            || "$1" == *.mov || "$1" == *.m4v || "$1" == *.m2ts ]]; then
        l_vid=true
    else
        l_vid=false
    fi
}
