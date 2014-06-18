#This file is managed by PUPPET.
#!/bin/bash
port=443
endDate=$(echo | openssl s_client -connect $HOSTNAME:443 2>/dev/null | openssl x509 -noout -enddate | cut -c10-)
# Code after if statement only runs if $endDate variable has a non-zero length. Tested with endDate=
if [[ -n $endDate ]]	
then
   endDateSeconds=$(date '+%s' --date "$endDate")
nowSeconds=$(date '+%s')
secUntilExpire=$(expr $endDateSeconds - $nowSeconds)
hoursUntilExpire=$(expr $secUntilExpire / 3600)
daysUntilExpire=$(expr $hoursUntilExpire / 24)
echo $daysUntilExpire
fi
