#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

tempFile="/tmp/zabbixSendmailTmpFile"

NAME=`echo "$(basename $(readlink -f $0))" | tr ' +=-' '_' | tr '[A-Z]' '[a-z]' | tr -cd [a-z_]`
OFFSETFILE=/tmp/${NAME}.offset
MAILLOG=/var/log/maillog

if [ -z "`which logtail`" ] ; then
  	echo "logtail is not installed, install with: apt-get install logtail" >&2
  	date >&2
	exit 1
fi

sender=`which zabbix_sender` 2>/dev/null
[ -z "${sender}" ] && sender=/usr/bin/zabbix_sender
if [ ! -x "${sender}" ] ; then
  	echo "zabbix_sender is not installed, install with: apt-get install zabbix-sender" >&2
	date >&2
  	exit 1
fi

# Finds Zabbix server hostname or IP address amongst fragments. May break if it finds another instance of "Server=" in a file.
zabbixServer=$(cat /etc/zabbix/fragments/* | grep "^Server=" | cut -d'=' -f2 | cut -f1 -d",")

sends=0
success=0
function zsend {
  key="$2"
  [ -z "$key" ] && key="`echo "$1" | sed 's/^ *//' | tr ' +=-' '_' | tr '[A-Z]' '[a-z]' | tr -cd [a-z_]`"
  value="$3"
  [ -z "${value}" ] && value=`grep -c "$1" ${LOGSNIPPET}`

   ${sender} -z $zabbixServer -s $HOSTNAME -k "${key}" -o "${value}" > $tempFile 
	if grep "Failed 0" "$tempFile"
		then
		(( success++ ))
	fi
(( sends++ ))
}

LOGSNIPPET=`mktemp`
LOG=/var/log/maillog

# Take the last piece of the log that's not been read.
logtail -f ${LOG} -o ${OFFSETFILE} >${LOGSNIPPET}

# get the number of mails in the queue
sendmailq=`mailq 2>/dev/null | tail -n1 | awk '{print $3}'`
[ -z "${sendmailq}" ] && sendmailq=0

# Send the queue
zsend 'mailq' 'mailq' ${sendmailq}

# Analyse the log and send the data
zsend ' stat=Data format error'
zsend ' stat=Deferred'
zsend ' stat=Host unknown'
zsend ' stat=Local.configuration.error'
zsend ' stat=maillog Message exceeds maximum fixed size' "maxfixed"
zsend ' stat=Sent'
zsend ' stat=Service unavailable'
zsend ' stat=User unknown'
zsend ' Domain of sender address .* does not exist' 'domain'
zsend ' reject=4' 'reject4'
zsend ' reject=5' 'reject5'
echo "${success} / ${sends}" Messages Successfully Sent >&2
date >&2
rm -f ${LOGSNIPPET}
