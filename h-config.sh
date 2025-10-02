#!/usr/bin/env bash

####################################################################################
###
### Nockminer - Golden
### Hive integration: UnRe4L
###
####################################################################################
# allowed variables: WORKER_NAME CUSTOM_TEMPLATE CUSTOM_URL CUSTOM_PASS CUSTOM_ALGO CUSTOM_USER_CONFIG CUSTOM_CONFIG_FILENAME

conf=
conf+=""
conf+=""
conf+="$CUSTOM_TEMPLATE"

echo -e "$conf" > $CUSTOM_CONFIG_FILENAME
echo -e "$CUSTOM_USER_CONFIG" > $CUSTOM_USER_CONFIG_FILENAME
