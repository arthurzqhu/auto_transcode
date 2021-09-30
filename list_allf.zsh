#!/bin/zsh

# put all videos in the current directory into a list 
list_allf() 
{ 
   f_list=("${(@f)$(find $1 -type f)}") 
   get_skipped 
   for item in "${f_list[@]}" 
   do 
      check_video $item 
      if [[ "$item:u" != *"$2:u"* ]]; then
         l_vid=false
      fi
      itemesc=("${item//\[/\\[}") # need to escape the left bracket 
      if [[ "$l_vid" = true ]]; then 
         if ! printf '%s\n' "${skipped_files[@]}" | grep -q -p -x "$itemesc"; then
            vid_list+=("$item") 
         fi 
      fi 
   done 
} 
