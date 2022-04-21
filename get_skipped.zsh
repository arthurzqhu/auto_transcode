#!/bin/zsh

# check if the video is already in the auto_encode or AE_comp
get_skipped()
{   
   skiplog="$curr_dir/.auto_encode.log"
   complog="$curr_dir/.AE_comp.log"

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
