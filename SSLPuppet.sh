# This file is managed by PUPPET
#!/bin/bash
cd /var/lib/puppet/ssl/ca/signed/
certs=$(ls *.pem)
echo $certs
echo "{"
echo "\"data\":["
for cert in $certs
	do
	endDate=$(openssl x509 -enddate -noout -in $cert| cut -c10-)
		if [[ -n $endDate ]]
		then
		cert=$(echo $cert| cut -f1 -d '.')
		endDateSeconds=$(date '+%s' --date "$endDate")
		nowSeconds=$(date '+%s')
		secUntilExpire=$(expr $endDateSeconds - $nowSeconds)
		hoursUntilExpire=$(expr $secUntilExpire / 3600)
		daysUntilExpire=$(expr $hoursUntilExpire / 24)
		echo "{ \"{#CERTDAYS}\" : \"$daysUntilExpire\" },"
		echo "{ \"{#PUPPETHOSTSIGNED}\" : \"$cert\" },"
		fi
	done
echo "]"
echo "}"
