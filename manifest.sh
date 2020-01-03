#!/bin/bash

TOP_DIR=$(cd $(dirname "$0") && pwd)

jarname="branding.jar"
foldername="branding"

if [ -e $foldername/$jarname ]; then
	rm $foldername/$jarname
fi

if [ ! -d $foldername ]; then
	printf "%s" "$filename not found"
	exit 1
fi


if [ $1 = 'e'  ]; then
	vi $foldername/guac-manifest.json
fi


cd $foldername
zip -r $jarname *
cd

printf "%s\n" "copying $jarname to extensions"
cp $foldername/$jarname /etc/guacamole/extensions/


