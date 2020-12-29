#!/bin/bash

LOG_DIR=/var/log/nginxcertbot
FILE_NAME=nginxcertbot.log
MAX_NUM_FILES=10

for i in `ls -1 $LOG_DIR/${FILE_NAME}.* | sort --field-separator=. -k3 -nr`
do
  # Grab the number (last token) for all of the numbered files
  log_num=$(echo "$i" | awk -F\. '{print $NF}')

  # If it is equal to or greater than our max number of files
  # just delete it.
  if [ "$log_num" -ge $MAX_NUM_FILES ]
  then
    rm $i
    continue
  fi

  target_num=$((log_num + 1))
  mv -f $i ${FILE_NAME}.${target_num}
done

mv -f $LOG_DIR/$FILE_NAME $LOG_DIR/${FILE_NAME}.1
