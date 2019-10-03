#!/bin/bash
cd "$(dirname "$0")"

test -e compiled || mkdir compiled

cd compiled

if [[ $# -ne 0 ]]; then
	for i in "$@"; 
	do
		smxfile="`echo $i | sed -e 's/\.sp$/\.smx/'`";
		echo -e "Deploying $i...";
		cp $i ../../plugins
	done
else
	for compiledfile in *.smx
	do
		smxfile="`echo $compiledfile | sed -e 's/\.sp$/\.smx/'`"
		echo -e "Deploying $compiledfile ..."
		cp $i ../../plugins
	done
fi
