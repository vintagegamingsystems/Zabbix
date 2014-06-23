#!/usr/bin/python

import sys

sys.path.append("/root/NetApp")

from NaServer import *
from NaElement import *

s=NaServer("is-nas1.uoregon.edu",1,6)
s.set_server_type("Filer")
s.set_admin_user(<username>,<password>)
s.set_transport_type("HTTPS")
output=s.invoke("system-get-version")
r=output.child_get_string("version")
print r
