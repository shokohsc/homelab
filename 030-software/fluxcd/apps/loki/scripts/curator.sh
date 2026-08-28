#!/bin/sh
# Cause filesize is similar always just delete last x% (default: 10) Files.
folder="."
if [ ! -z $SPACEMONITORING_FOLDER ]; then
		folder=$SPACEMONITORING_FOLDER
fi

maxusedPercent=90
if [ ! -z $SPACEMONITORING_MAXUSEDPERCENTE ]; then
		maxusedPercent=$SPACEMONITORING_MAXUSEDPERCENTE
fi

deletingIteration=10
if [ ! -z $SPACEMONITORING_DELETINGITERATION ]; then
		deletingIteration=$SPACEMONITORING_DELETINGITERATION
fi

echo "Folder $folder will be monitored that minimum $maxusedPercent% is free. Delete every ${deletingIteration}th files on cleanup."

usedInodesPercent=$(df -i $folder | sed -n '2p' | awk '{print $5}' | cut -d% -f1)
usedSpacePercent=$(df $folder | sed -n '2p' | awk '{print $5}' | cut -d% -f1)
fileCount=$(ls $folder | wc -l)
deletingFileCount=$((fileCount / deletingIteration))

# debug
# usedInodesPercent=89
# usedSpacePercent=89
# echo $folder
# echo $usedInodesPercent
# echo $usedSpacePercent
# echo $fileCount
# echo $deletingFileCount

if [ $usedInodesPercent -ge $maxusedPercent -o $usedSpacePercent -ge $maxusedPercent ]; then
		echo More than ${maxusedPercent}% Space or Inodes are used -\> remove $deletingFileCount files
		# ls $folder -1t | tail -$deletingFileCount | awk -v prefix="$folder/" '{print prefix $0}' | tr '\n' '\0' | xargs -0 rm
		ls $folder -1t | tail -$deletingFileCount | awk -v prefix="$folder/" '{print prefix $0}' | tr '\n' '\0' | xargs -0 rm -v -rf "{}"
else
		echo No cleanup needed
fi
