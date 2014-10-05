################################################################################
#Discourse Mail Proxy v0.1                                                     #
#This small script is inspired by AlterMIME. but does a very specifc task      #
#Unlike just appending a disclaimer text in a mail, it looks for a specific set#
#of words in a mail and replaces that with a link. This was specifically       #
#developed for Discourse [http://discoversd.com/] to replace link_url text with#
#a subdomain value fetched from a DB. You are most welcome to take and break   #
#it for your needs !!                                                          #
# 																		                                                    Cheers,#
#                                                  																	Anindya Roy#
#                                                                  i@anindya.me#
################################################################################


#!/bin/sh 
# Localize these. 
INSPECT_DIR=/var/spool/filter
SENDMAIL=/usr/sbin/sendmail
HTTP="https" #Change it with what suites you. HTTP or HTTPS
DOMAIN="monitoringclient.com"  #Your domain goes here 
export PGPASSWORD="Specifies!" #Put your Postgres Password Here
dbHost="172.17.0.37" #Put your PostgreSQL Hostname or IP here
dbName="discourse" #And DB Name Goes here
dbUser="anindya" #Finally the db user

# Exit codes from <sysexits.h> 
EX_TEMPFAIL=75 
EX_UNAVAILABLE=69

# Clean up when done or when aborting. 
trap "rm -f in.$$" 0 1 2 3 15 

# Start processing. 
cd $INSPECT_DIR || { echo $INSPECT_DIR does not exist; exit 
$EX_TEMPFAIL; }

cat >in.$$ || { echo Cannot save mail to file; exit $EX_TEMPFAIL; } 

if grep -q link_url in.$$; then #Just to make sure we dont connect to the DB unless the mail as the link_url 

#Capturing th eFor  email id from the mail
e_id=`grep "for <" in.$$  | grep -Po "(?<=\<)[^']*(?=\>)"`
echo $e_id

#Fetching the id from user table and storing in u_id
#u_id=`PGPASSWORD=Specifies! psql -t -h $dbHost -d $dbName -U $dbUser << EOF
u_id=`psql -t -h $dbHost -d $dbName -U $dbUser << EOF
select id from users where email = '$e_id' LIMIT 1;
EOF`
echo $u_id

#Fetching the Value from the user_custom_fields
#Value=`PGPASSWORD=Specifies! psql -t -h $dbHost -d $dbName -U $dbUser << EOF
Value=`psql -t -h $dbHost -d $dbName -U $dbUser << EOF
select value from user_custom_fields where id = '$u_id' AND name = 'subdomain'; 
EOF` 
echo $Value
if [ -n "$Value" ]; then
echo
else
Value="sample"
fi

#Building the Link URL
link_url=`echo $HTTP :// $Value . $DOMAIN | tr -d ' '`
echo $link_url

#And finally the replace process
sed -i "s|link_url|${link_url}|g" in.$$
sed -i "s|show_url|${link_url}|g" in.$$
#sed -i "s|notification|${link_url}|g" in.$$ #Just for me to do some quick and dirty testing


$SENDMAIL "$@" <in.$$ 
 
else
$SENDMAIL "$@" <in.$$ 
fi

exit $?
