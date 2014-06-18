#!/bin/bash

#Author: Joshua Cagle
#Organization: University of Oregon

# Finds Zabbix server hostname or IP address amongst fragments.
# May break if it finds another instance of "Server=" in a file
# that is not commented out, for which should never happen.
zabbixServer=$(cat /etc/zabbix/fragments/* | grep "^Server=" | cut -d'=' -f2 | cut -f1 -d",")

statArray=("active connections openings|""passive connection openings|""failed connection attempts|"\
"connection resets received|""connections established|""segments received|"\
"segments send out|""segments retransmited|""bad segments received|""resets sent")

# The stats function reads the tempFile into memory and declares variables
# based on whether the values are old or new. Since we are running this script
# via a cron job at interval the oldValues array will house the prior values.

z=0
function stats {
y=0
i=0

if [[ -e tempFile ]]
then
for i in `cat tempFile`
do
if [[ $z -eq 0 ]]
then
oldValue="$i"
oldValues[$y]=$oldValue
else
newValue="$i"
newValues[$y]=$newValue
fi
         (( y += 1 ))
done
fi
(( z += 1 ))
}

#Calls stats function
stats
##Debug
#echo ${oldValues[@]}

#Makes new or overwrites existing statistics file.
#Pushes statArray into the grep command. This finds all the values in
# output that are relevant to what we want to monitor.
netstat -st | grep -E "${statArray[@]}" | awk '{print $1}' > tempFile

#Calls stats function
stats

##Debug
#echo ${newValues[@]}

#Removes the spaces in the statArray and replaces the pipes with a space.
#This allows the index array values to be entered as the key for the item.
valueArray=$(echo ${statArray// /} | sed 's/[|]/ /g')

h=0
# Pushes the valueArray values back into an array instead of string,
# for which it became when the valueArray was restructured.
for element in ${valueArray[@]}
do
     valuesArray[$h]=$element
(( h += 1 ))
done
v=0
for value in ${newValues[@]}
do
#Subtracts the newValues from the oldValues array. This will
#return the change that has occurred between the two sets of
#values.
exprResult=$(expr $value - ${oldValues[$v]})
echo ""
echo "Value and Key Processed"
echo $exprResult ${valuesArray[$v]}
##Debug
# echo $value
# echo ${oldValues[$v]}
# echo $v
# echo $exprResult
# echo $zabbixServer
# echo $HOSTNAME
#Sends metrics off to the Zabbix server.
zabbix_sender -z $zabbixServer -s $HOSTNAME -k ${valuesArray[$v]} -o $exprResult
(( v += 1 ))
done 
