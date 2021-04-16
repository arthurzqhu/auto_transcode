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

# check if the video is already in the auto_encode or AE_comp
get_skipped()
{
    skiplog="$curr_dir/auto_encode.log"
    complog="$curr_dir/AE_comp.log"

    if [ -f $skiplog ]; then 
        while IFS= read -r line
            do; skipped_files+=("$line")
        done < "$skiplog"
    fi 

    if [ -f $complog ]; then
        while IFS= read -r line
            do; skipped_files+=("$line")
        done < "$complog"
    fi
}

# output the codec
get_codec()
{
    curr_codec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
        -of default=noprint_wrappers=1:nokey=1 "$1")

    curr_codectag=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_tag_string \
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

    if [[ "$curr_codec" == "hevc" && "$curr_codectag" == "hvc1" ]]; then
        echo "$1 already hevc!"

        # record the file if it hasnt already been
        if [ ! -f "$curr_dir/AE_comp.log" ]; then
            echo $1 > "$curr_dir/AE_comp.log"
        else
            echo $1 >> "$curr_dir/AE_comp.log"
        fi
    else
        f_name=$(basename "$1")
        f_name=${f_name%.*}
        outfile="$curr_dir/.cvt_tmp/$f_name.mp4"
        outdir=$(dirname "$1")
        if [ ! -d "$curr_dir/.cvt_tmp/" ]; then
            mkdir "$curr_dir/.cvt_tmp/"
        fi
        /Applications/HandBrakeCLI --preset-import-file fastOCTRA.json -Z "fastOCTRA" -i "$1" -o $outfile
        
        cmp_dur "$1" "$outfile"
        # compare the size and duration
        # only overwrite the original file if size is smaller and duration is the same
        eval $(stat -s "$1")
        old_size=$st_size
        eval $(stat -s "$outfile")
        new_size=$st_size
        if [[ $curr_codectag == "hev1" || $new_size -lt $old_size && $dur_diff -lt 1 ]]; then
            rm "$1"
            mv "$outfile" "$outdir/"
            # remove the temp dir
            rm -rf "$curr_dir/.cvt_tmp/" 

            # record the completion of this file
            if [ ! -f "$curr_dir/AE_comp.log" ]; then
                echo $1 > "$curr_dir/AE_comp.log"
            else
                echo $1 >> "$curr_dir/AE_comp.log"
            fi
        fi

        # record such incidence to deal with later
        if [[ $new_size -gt $old_size || $dur_diff -gt 1 ]]; then
            if [ ! -f "$curr_dir/auto_encode.log" ]; then
                echo $1 > "$curr_dir/auto_encode.log"
            else
                echo $1 >> "$curr_dir/auto_encode.log"
            fi
        fi
        
        if [[ $new_size -gt $old_size ]]; then
            rm -rf $outfile
        fi
    fi
}

# put all videos in the current directory into a list
list_allf()
{

    f_list=("${(@f)$(find $1 -type f)}")
    get_skipped
    for item in "${f_list[@]}"
    do
        check_video $item
        itemesc=("${item//\[/\\[}")
        if [[ "$l_vid" = true ]]; then
            if ! printf '%s\n' "${skipped_files[@]}" | grep -q -p -x "$itemesc"; then
                vid_list+=("$item")
            fi
        fi
    done
}


trap "exit" INT

# echo give me a video file or directory containing video files:
# read input


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

    for v_file in "${vid_list[@]}"
    do
        do_encode "$v_file"
    done

    echo "all done!"
fi
