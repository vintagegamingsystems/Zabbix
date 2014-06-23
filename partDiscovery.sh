#!/bin/bash

devices=$(ls /dev | grep ^sd[a-z][0-9]$)

echo "{"
echo "\"data\":["
for dev in ${devices}
        do
	echo "{ \"{#PARTDEVPATH}\" : \"/dev/$dev\" },"
done
echo "]"
echo "}"
