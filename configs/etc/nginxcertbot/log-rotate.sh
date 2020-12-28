#!/bin/bash

LOG_DIR=/var/log/nginxcertbot
FILE_NAME=nginxcertbot.log

mv -f $LOG_DIR/$FILE_NAME $LOG_DIR/${FILE_NAME}.1
