#!/bin/bash
set -e

usage="$(basename "$0") [-h -b N]

Log when you buy a pack of cigs, and check when you last bought one.

           With no options, calculate the last time you purchased an item.
  -h       Print this help output
  -b N     Log a new purchase. Without N, start logging from the current time. 
           Otherwise, N is how many hours ago you purchased a new item."

item="deck" # a deck of cigs, or a noun for any other vice you wish to log and track
lb_file="/var/tmp/cigs.txt" # file in which the timestamp is stored and retrieved
threshold="1209600"  # how often you can buy it before the program turns red; default is two weeks, stored in seconds since epoch
while getopts "bh" OPTION; do
    case $OPTION in
    h)
        echo "$usage"
        exit
        ;;
    b)
        eval nextopt=\${$OPTIND}
        if [[ -n $nextopt && $nextopt != -* ]] ; then
        OPTIND=$((OPTIND + 1))
        offset=$nextopt
        else
        offset=0
        fi
        if [[ -n $offset && ! $offset =~ ^[0-9]+$ ]]; then
        echo "Hours parameter passed to -b must be in the form of an integer."
        exit
        fi
        echo -e "Bought a new $item...\nResetting timer to 0 days and $offset hours."
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

now=$(date +%s)
elapsed=$(((now-last_bought) / 3600))
H=$((elapsed % 24))
D=$(( ( elapsed /= 24 ) % 7))
W=$((elapsed / 7))

ws=s; [ $W = 1 ] && ws=
ds=s; [ $D = 1 ] && ds=
hs=s; [ $H = 1 ] && hs=
case $W+$D+$H in
0+0+0 ) string="$H hour$hs" ;;
0+0+* ) string="$H hour$hs" ;;
0+*+0 ) string="$D day$ds"  ;;
0+*+* ) string="$D day$ds and $H hour$hs" ;;
*+0+0 ) string="$W week$ws" ;;
*+0+* ) string="$W week$ws and $H hour$hs" ;;
*+*+0 ) string="$W week$ws and $D day$ds" ;;
*+*+* ) string="$W week$ws, $D day$ds and $H hour$hs" ;;
esac

colour1='\033[0;31m'
colour2='\033[0;32m'
if (($elapsed < threshold))
then echo -e "${colour1}It's been $string since you last bought a $item."
else
echo -e "${colour2}It's been $string since you last bought a $item."
fi
