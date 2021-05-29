#!/bin/bash
set -e

usage="$(basename "$0") [-h -b N]

Log when you buy a pack of cigs, and check when you last bought one.

           With no options, calculate the last time you purchased an item.
  -h       Print this help output
  -b N     Log a new purchase. Without N, start logging from the current time. 
           Otherwise, N is how many hours ago you purchased a new item."

lb_file=/var/tmp/cigs.txt
threshold=1209600  # two weeks
while getopts "b:h" OPTION; do
    case $OPTION in
    h)
        echo "$usage"
        exit
        ;;
    b)
        offset=$OPTARG
        if [[ -n $offset && ! $offset =~ ^[0-9]+$ ]]; then 
        echo "HOURS parameter passed to -b must be an integer."
        exit
        fi
        echo -e "Bought a new deck...\nResetting timer to 0 days and $offset hours."
        offset=$((offset*60*60))
        last_bought="$(date -u +%s)"
        new_lb=$((last_bought-offset))
        echo $new_lb > $lb_file
        exit
        ;;
    *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
done

if [ -s "$lb_file" ] ; then
  last_bought=$(cat "$lb_file")
  else echo "Cannot proceed: $lb_file does not exist or is empty." && exit
fi
now=$(date -u +%s)
elapsed="$((now-last_bought))"

if (($elapsed > 1209600)); then string="$((elapsed/604800)) weeks"
elif (($elapsed > 604800)); then string="$((elapsed/604800)) week"
elif (($elapsed > 127800)); then string="$((elapsed/86400)) days"
elif (($elapsed > 86400)); then string="$((elapsed/86400)) day"
else string="$((elapsed/3600)) hours"
fi
RED='\033[0;31m'
GREEN1='\033[0;32m'
if (($elapsed < -3600 ))
then echo "$string is a negative number! $elapsed";
elif (($elapsed < threshold))
then echo -e "${RED}It's been $string since you last bought a deck."
else
echo -e "${GREEN1}It's been $string since you last bought a deck."
fi