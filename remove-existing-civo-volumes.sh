#!/bin/bash
civo volumes ls --region fra1 -o json | jq .[].id
for i in $(civo volume ls -o json | jq .[].id );   do     civo volume remove $(echo $i | sed 's/"//g') --yes ;   done
