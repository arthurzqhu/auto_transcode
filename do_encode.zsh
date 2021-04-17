#!/bin/zsh

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
