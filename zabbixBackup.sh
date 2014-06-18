#!/bin/bash
#
# mysql-fullbackup.sh
#
# Author: Joshua Cagle
# Organization: University of Oregon
# Full Backup for Zabbix w/MySQL
#
# Backs up the following data:
# MySQL Database using Percona xtrabackup
# SNMP MIBs
#
# Based on Julius Zaromskis's "Backup rotation" script
# http://nicaw.wordpress.com/2013/04/18/bash-backup-rotation-script/
# and
# Ricardo Santos (rsantos at gmail.com) "Backuping [sic] Full Database" script
# http://zabbixzone.com/zabbix/backuping-full-database/
#

#############Importante!!!############################
# You will need to modify this several places of this
# code to fit your environment.
######################################################

######################################################
# Zabbix server hostname and item key values called by
# zabbix_sender
######################################################

zabbixServer="<zabbixserver IP address or DNS name>"
mountZabbixKey="nfs.backup"
backupCount="count.nfs.backup"
backupTime="time.nfs.backup"
backupCurrentFileSize="size.nfs.backup"

######################################################
# NFS share name on host
######################################################

nfsMountHostname="<hostname of nfs share hosting node>"
nfsBackup="<nfs share directory>"
# example: /backup

nfsMountName=$(showmount -e ${nfsMountHostname} | grep ${nfsBackup} | awk '{print $1}')
if [[ $nfsMountName == "$nfsBackup" ]]
        then
             # Sends status code of 1 to Zabbix server if the NFS share
              # is available.
              zabbix_sender -z 127.0.0.1 -s ${zabbixServer} -k ${mountZabbixKey} -o 1

######################################################
# MySQL username and key
######################################################

MYSQLUSER="zabbix"
# Most likely the zabbix user
MYSQLPASS="<password>"
# User password in plain text

########################################################
# Defines destination directory names using date command
########################################################

dateDaily=`date +"%Y-%m-%d"`


########################################################
# Percona parameter value
########################################################

# Memory used in stage 2
USEMEMORY="1GB"


########################################################
# Define configuration file locations BELOW this line.
########################################################

# Backup script location
backupScript="/var/lib/xtrabackup/mysql-fullbackup.sh"

# Recovery script location
recoveryScript="/var/lib/xtrabackup/zabbix_recovery.sh"

# MySQL directory location
MYSQLDIR="/var/lib/mysql"

# SNMP MIB database locations
SNMPMIBDir="/usr/share/snmp/mibs/"


#######################################################
# Enter configuration file locations ABOVE this line.
#######################################################

# Establishes the base directory storage location
BASEDIR="/var/lib/xtrabackup"

# MySQL configuration file location
MYSQLCNF="/etc/my.cnf"

# NFS backup share location
NFSBKPDIR="${BASEDIR}/nfsZabbixBackup"

# Compressed database filename
COMPBACKUPFILE="compBackup${dateDaily}.tar.bz"

# Backup location
BKPDIR="${NFSBKPDIR}/backup.daily$dateDaily"

# Makes backup directory based on date
mkdir -p ${BKPDIR}

# Temporary backup directory
BKPTEMPDIR="${NFSBKPDIR}/backup"


########################################################################
# Backs up MySQL database with Percona xtrabackup software
########################################################################

# Start time variable for runtime
res1=$(date +%s.%N)

echo ""
echo "##################################################################"
echo "Backup for ${dateDaily} starting..."
echo "##################################################################"
echo ""

# Makes temporary backup directory
mkdir -p ${BKPTEMPDIR}

# Start database backup - stage 1
innobackupex --defaults-file=${MYSQLCNF} --user=${MYSQLUSER} --no-timestamp --password=${MYSQLPASS} ${BKPTEMPDIR}/mysqlBackup

# Start database backup - stage 2 (prepare backup for restore)
innobackupex --apply-log --use-memory=${USEMEMORY} ${BKPTEMPDIR}/mysqlBackup


#################################################################################
# Additional configuration files and directories should be added BELOW this line.
#################################################################################

# If you want to copy just one individual configuration file from a directory you should
# make a directory inside of the ${BKPTEMPDIR} to put it in.
# It should look like something below.
# mkdir -p ${BKPTEMPDIR}/directoryname
# then cp command

# Backs up mysql-fullbackup.sh script
echo ""
echo "Backing up backup script"
echo ""
mkdir -p ${BKPTEMPDIR}/backupScript/
cp -fv ${backupScript} ${BKPTEMPDIR}/backupScript

# Backs up zabbix_recovery.sh script
echo ""
echo "Backing up zabbix_recovery.sh script"
echo ""
mkdir -p ${BKPTEMPDIR}/recoveryScript/
cp -fv ${recoveryScript} ${BKPTEMPDIR}/recoveryScript

# Backs up ${MYSQLDIR}/zabbix directory
echo ""
echo "Backing up ${MYSQLDIR}/zabbix directory"
echo ""
mkdir -p ${BKPTEMPDIR}/mysqlBackup/zabbix
cp -Rfv ${MYSQLDIR}/zabbix/* ${BKPTEMPDIR}/mysqlBackup/zabbix

# Backs up ${MYSQLDIR}/mysql directory
echo ""
echo "Backs up folder in ${MYSQLDIR}/mysql directory"
echo ""
cp -Rfv ${MYSQLDIR}/mysql/ ${BKPTEMPDIR}/mysqlBackup/

# Backs up SNMP MIB Databases Directory ${SNMPMIBDir}
echo ""
echo "Bacon up!! SNMP MIB Databases ha!"
echo ""
cp -rfv ${SNMPMIBDir} ${BKPTEMPDIR}/


#########################################################
# ¡IMPORTANTE!
# Add everything you want to be backed up ABOVE this line.
#########################################################

echo ""
echo "Compressing backup, removing temporary directory, and moving backup to NFS share"
# Compresses temporary backup Directory
echo ""
echo "Compressing Temporary Database Directory"
echo ""
cd ${NFSBKPDIR}
tar -cvjf ${COMPBACKUPFILE} backup

# Moving the compressed backup file to the backup directory
mv ${COMPBACKUPFILE} ${BKPDIR}

# Removing temporary backup folder
rm -rf ${BKPTEMPDIR}


#######################################################
# Time based deletion of backup directories
#######################################################

# Declared function counts how many directories are in $NFSBKPDIR

function countBackup()
{
declare -a files
# Retrieves an array of file names in the $NFSNKPDIR
files=$(ls -l $NFSBKPDIR | grep '^d' | awk '{print $9}')
y=0
for file in ${files[@]}
    do
    # Counts the files in the $NFSBKPDIR directory
((y++))

done
}

# Function countBackup is called below
countBackup

# Checks to see if there are greater than 5 current backups of the zabbix server
if [[ $y -ge 5 ]]
then

echo "Searching for daily backups that are older than 6 days to remove from ${NFSBKPDIR}"
    echo ""
    find ${NFSBKPDIR}/backup.daily*/ -maxdepth 1 -mtime +6 -type d -exec rm -rv {} \;

else
echo "There are currently fewer than 5 current backups of the zabbix server"
fi

# Function countbackup is called below
countBackup

# Sends the number of current backups to the zabbix server via zabbix_sender command
zabbix_sender -z 127.0.0.1 -s ${zabbixServer} -k ${backupCount} -o $y

echo ""
echo "#################################################"
echo "Backup Process for ${dateDaily} completed"
echo "#################################################"
echo ""
else
                # Sends status code of 0 to Zabbix server if the NFS share
                # is not available. This value will trigger an alert in the
                # Zabbix frontend.
                echo "Error copying files to NFS share. Backup directory not transferred."
                zabbix_sender -z 127.0.0.1 -s ${zabbixServer} -k ${mountZabbixKey} -o 0
exit 0
fi

# Statements below returns runtime of current script
# These values are used in conjunction with the res1 variable above.
res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)

time=$(printf "Total runtime: %d:%02d:%02d:%02.4f\n" $dd $dh $dm $ds)

time=$(echo $time | awk '{print $3}')

# Sends execution time to Zabbix server
zabbix_sender -z 127.0.0.1 -s ${zabbixServer} -k ${backupTime} -o $time

# backupSize variable contains the human readable size of the current backup file
backupSize=$(ls -lh $BKPDIR | grep "^total" | awk '{print substr($2, 0, length($2)-1)}')

# Sends latest backup file size to zabbix server
zabbix_sender -z 127.0.0.1 -s ${zabbixServer} -k ${backupCurrentFileSize} -o $backupSize
echo $BKPDIR

echo ""
echo "#################################################"
echo "Backup Data sent to Zabbix server ${dateDaily}"
echo "#################################################"

