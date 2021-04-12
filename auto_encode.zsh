#!/bin/zsh

# check if the input is video
check_video()
{
    if [[ "$1" == *.mkv || "$1" == *.mp4 || "$1" == *.avi ]]; then
        l_vid=true
    else
        l_vid=false
    fi
}

# output the codec
get_codec()
{
    curr_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
        -of default=noprint_wrappers=1:nokey=1 "$1")
}

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

# perform encoding process into hevc
do_encode()
{
    get_codec "$1"

    if [ "$curr_codec" = "hevc" ]; then
        echo "$1 already hevc!"
    else
        f_name=$(basename "$1")
        f_name=${f_name%.*}
        outfile="$curr_dir/.cvt_tmp/$f_name.mp4"
        outdir=$(dirname "$1")
        mkdir "$curr_dir/.cvt_tmp/"
        /Applications/HandBrakeCLI --preset-import-file fastOCTRA.json -Z "fastOCTRA" -i "$1" -o $outfile
        
        cmp_dur "$1" "$outfile"
        # compare the size and duration
        # only overwrite the original file if size is smaller and duration is the same
        eval $(stat -s "$1")
        old_size=$st_size
        eval $(stat -s "$outfile")
        new_size=$st_size
        if [[ $new_size -lt $old_size && $dur_diff -lt 1 ]]; then
            rm "$1"
            mv "$outfile" "$outdir/"
            # remove the temp dir
            rm -rf "$curr_dir/.cvt_tmp/" 
        fi

        # record such incidence to deal with later
        if [[ $new_size -gt $old_size || $dur_diff -gt 1 ]]; then
            if [ ! -f "$curr_dir/auto_encode.log" ]; then
                echo $1 > "$curr_dir/auto_encode.log"
            else
                echo $1 >> "$curr_dir/auto_encode.log"
            fi
        fi
    fi
}

# put all videos in the current directory into a list
list_allf()
{

    f_list=("${(@f)$(find $1 -type f)}")
    for item in "${f_list[@]}"
    do
        check_video $item
        if [[ "$l_vid" = true ]]; then
            vid_list+=("$item")
        fi 
    done
}


trap "exit" INT

read input


if [[ -f "$input" ]]; then
    curr_dir="$(dirname "$input")"
    
    check_video "$input"
    if [[ "$l_vid" = false ]]; then
        continue 
    else
        do_encode "$input"
    fi
fi

if [[ -d "$input" ]]; then
    curr_dir="$input"
    # put all videos in the current directory into a list
    list_allf "$input"
    for v_file in "${vid_list[@]}"
    do
        do_encode "$v_file"
    done
fi

