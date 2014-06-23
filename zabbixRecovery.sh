#!/bin/bash
#
# zabbix_recovery.sh
#
# Author: Joshua Cagle
# Organization: University of Oregon
# Restores Zabbix MySQL database, MIBs, and puppet modules
# Restores the following files:
# MySQL Database
# SNMP MIBs
#
# Puppet modules including:
# zabbixserver
# iptables
#
#
###########################################
# Backup directory location
###########################################

backupDir="<path to backup directory>"


###########################################
# Temporary directory location
###########################################

temporaryDir="/tmp/"


###############################################
# Backup locations
###############################################

mibsLocation="/usr/share/snmp/mibs"

mysqlLocation="/var/lib/mysql"

###############################################
# Declaration of restoration variables
###############################################

mibRestore=0

mysqlRestore=0


###########################################
# Function declaration
########################################### 

function functionInput ()
{
echo "Below is a list of backups"
echo ""
declare -a files
# Retrieves an array of file names in the $backupDir 
local files=$(ls -l $backupDir | grep '^d' | awk '{print $9}')
# Function reads input from user.
local y=1
for file in ${files[@]} 
do
	
	echo "[$y] $file"	
	#For loop puts directory names into $files array again
	files[$y]=$file
	((y++))


done
echo ""

# Read user input for backup filename 
echo "Enter the number of the backup you would like to restore."
read inputBackupDirectoryNum
# Sanitizes variable to only accept numeric data
inputBackupDirectoryNum=${inputBackupDirectoryNum//[^0-9]/}
((y--))

while [[ ! $inputBackupDirectoryNum =~ ^[0-9]+$ || $inputBackupDirectoryNum -lt 1 || $inputBackupDirectoryNum -gt $y ]]
do	
	echo "Enter the "number" of the backup listed above, the number must be between 1 and $y."
	read inputBackupDirectoryNum
	inputBackupDirectoryNum=${inputBackupDirectoryNum//[^0-9]/}
done

# Pull backup directory name from files array index number using user input
inputBackupDirectory=${files[$inputBackupDirectoryNum]}
}

clear
echo "###########################################"
echo "           Zabbix Recovery Script"
echo "###########################################"

# Calls function functionInput
functionInput

x=1
while [ $x==1 ]
do
	echo ""
	echo "Would you like to restore $inputBackupDirectory?"
	echo ""
	echo -e "Press '\e[1;31my\e[0m' key and Enter key, if this is true." 
	echo -e "If this is '\e[1;34mNOT\e[0m' true, press any other key to be prompted again for name of backup directory."
	read answer
	answer=${answer//[^a-zA-Z]/}
		if [[ "$answer" == "y" || "$answer" == "Y" ]]
			then 
			echo "Restoring from...$inputBackupDirectory"
			break
		else 
			clear
			functionInput
		fi
done

echo "Would you like to restore the MIB files to $mibsLocation?"
echo -e "Enter '\e[1;31my\e[0m' and press Enter to '\e[1;31mRESTORE\e[0m' MIBs."
echo -e "Enter '\e[05;34mn\e[0m' and press Enter to '\e[1;34mNOT RESTORE\e[0m' MIBs."
read answer
answer=${answer//[^a-zA-Z]/}

x=1
while [[ $x==1 ]]
do
                if [[ $answer == "y" || $answer == "Y" ]]
                        then
                        mibRestore=1
                        break
                elif [[ $answer == "n" || $answer == "N" ]]
                        then
                        echo "User chose to not restore MIBs."
                        break
                else
                    	echo "Would you like to restore the MIBs to $mibsLocation?"
                        echo -e "Enter '\e[1;31my\e[0m' and press Enter to '\e[1;31mRESTORE\e[0m' MIBs."
                        echo -e "Enter '\e[05;34mn\e[0m' and press Enter to '\e[1;34mNOT RESTORE\e[0m' MIBs."
                        read answer
			answer=${answer//[^a-zA-Z]/}			
                fi
done

echo "Would you like to restore the MySQL database to $mysqlLocation?"
echo -e "Enter '\e[1;31my\e[0m' and press Enter to '\e[1;31mRESTORE\e[0m' the MySQL database."
echo -e "Enter '\e[05;34mn\e[0m' and press Enter to '\e[1;34mNOT RESTORE\e[0m' the MySQL database."
read answer
answer=${answer//[^a-zA-Z]/}

x=1
while [[ $x==1 ]]
do
                if [[ $answer == "y" || $answer == "Y" ]]
                        then
                        mysqlRestore=1
                        break
                elif [[ $answer == "n" || $answer == "N" ]]
                        then
                        echo "User chose to not restore MySQL database."
                        break
                else
                        echo "Would you like to restore the MySQL database to $mysqlLocation?"
                        echo -e "Enter '\e[1;31my\e[0m' and press Enter to '\e[1;31mRESTORE\e[0m' the MySQL database."
                        echo -e "Enter '\e[05;34mn\e[0m' and press Enter to '\e[1;34mNOT RESTORE\e[0m' the MySQL database."
                        read answer
			answer=${answer//[^a-zA-Z]/}

                fi
done


# Start time variable for runtime
res1=$(date +%s.%N)


##################################################
# Decompresses the backup file
##################################################

if [[ $mibRestore == 0 && $mysqlRestore == 0 ]]
	then
		echo "No files choose to be restored"
		exit 1
	else
	compressedBackupFileLocation="${backupDir}/${inputBackupDirectory}"
	backupFileName=$(ls ${compressedBackupFileLocation})
	backupFile=$compressedBackupFileLocation/$backupFileName

	# Decompresses user chosen backup directory to 
	echo "Decompressing backup directory"
	tar -xjvf  $backupFile -C $temporaryDir


###################################################
# Restoration of  MIBs, MySQL database directories
###################################################

	if [[ $mibRestore == 1 ]]
		then
		echo "Copying MIBs to $mibsLocation..."
        	cp -rpfv /tmp/backup/mibs/* $mibsLocation/
		chown -R root:root $mibsLocation

	fi

	if [[ $mysqlRestore == 1 ]]
		then
		cd /root
		echo "Stopping apache daemon."
		service httpd stop
		echo "Stopping Zabbix daemon."
		service zabbix-server stop
		echo "Stopping mysqld daemon."
		service mysqld stop
		echo "Restoring MySQL database..."
        	cp -rpfv /tmp/backup/mysqlBackup/* $mysqlLocation
        	echo "Changing permissions of files in $mysqlLocation"
        	chown -R mysql:mysql $mysqlLocation
        	chmod 660 $mysqlLocation/ib*
		chmod 640 $mysqlLocation/backup-my.cnf
		chmod 660 $mysqlLocation/zabbix/* 
		chmod 700 $mysqlLocation/zabbix/
		echo "Starting mysql daemon.."
        	service mysqld start
		echo "Starting Zabbix server daemon."
		service zabbix-server start
		echo "Starting apache daemon."
		service httpd start
	fi

zabbixStatus=$(service zabbix-server status | awk '{print $3}')
if [[ $zabbixStatus == "stopped" ]]
	then
	service zabbix-server start
fi

# remove temporary backup directory located in $backupDir
                rm -rfv /tmp/backup
		
# Statements below returns runtime of current script
# These	values are used	in conjunction with the	res1 variable above.
res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

printf "Total runtime: %d:%02d:%02d:%02.4f\n" $dd $dh $dm $ds
fi
