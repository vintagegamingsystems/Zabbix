#!/usr/bin/python
import socket
import re
zabbixServer = "<zabbix server DNS/IP address>"
hostname = socket.gethostname()
hostname = "Hostname=" + hostname
filename = "/etc/zabbix/zabbix_agentd.conf"
file = open(filename, "r")
fileString = file.read()
file.close()
fileString = re.sub(r'Hostname=Zabbix server', hostname, fileString)
fileString = re.sub(r'Server=127.0.0.1',zabbixServer, fileString)
file = open(filename, "w")
file.write(fileString)
file.close()

