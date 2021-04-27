#!/bin/zsh

. ./cmp_dur.zsh
. ./do_encode.zsh
. ./get_codec.zsh
. ./list_allf.zsh
. ./check_video.zsh
. ./get_skipped.zsh

trap "exit" INT

if [[ -f "$1" ]]; then
    curr_dir="$(dirname "$1")"
    
    check_video "$1"
    if [[ "$l_vid" = false ]]; then
        continue 
    else
        do_encode "$1"
    fi
fi

if [[ -d "$1" ]]; then
    curr_dir="$1"
    # put all videos in the current directory into a list
    list_allf "$1"
    echo total videos: ${#vid_list[@]}
    total_size=$(du -ch $vid_list | tail -1 | cut -f 1)
    echo total video size to re-encode: $total_size
    
    if [[ ${#vid_list[@]} != 0 ]]; then
        for v_file in "${vid_list[@]}"
        do
            do_encode "$v_file"
        done
    fi
    echo "all done!"
fi
