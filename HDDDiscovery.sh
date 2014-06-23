#!/bin/bash

devices=$(ls /dev | grep ^sd[a-z]$)

echo "{"
echo "\"data\":["
for dev in ${devices}
        do
	echo "{ \"{#DISKDEV}\" : \"/dev/$dev\" },"
done
echo "]"
echo "}"
