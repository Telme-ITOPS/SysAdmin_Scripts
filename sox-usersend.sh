#!/bin/bash
input=/usr/tmp/sox-all-hosts
output=/usr/tmp/sox-users-system.txt

cat /root/phosts /root/phosts-xen | sort | uniq | grep -v "#" | grep -v "^$" | grep -v "-" > $input
pssh -h $input -p 100 -i "hostname && getent group root | cut -d: -f4" > $output
pssh -h $input -p 100 -i "hostname && getent group wheel | cut -d: -f4" >> $output


echo "All users with root and sudo access to production Linux system. Attachment." | mail -s "SOX - Linux system root and sudo access" -a $output monthly_mssql_user@cms.telmetrics.com

#echo "All users with root and sudo access to production Linux system. Attachment." | mail -s "SOX - Linux system root and sudo access" -a $output bzammit@telmetrics.com


rm -f $input
rm -r $output

