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
DOMAIN=""  #Your domain goes here 
export PGPASSWORD="" #Put your Postgres Password Here
dbHost="" #Put your PostgreSQL Hostname or IP here
dbName="" #And DB Name Goes here
dbUser="" #Finally the db user

# Exit codes from <sysexits.h> 
EX_TEMPFAIL=75 
EX_UNAVAILABLE=69

# Clean up when done or when aborting. 
trap "rm -f in.$$" 0 1 2 3 15 

# Start processing. 
cd $INSPECT_DIR || { echo $INSPECT_DIR does not exist; exit 
$EX_TEMPFAIL; }

cat >in.$$ || { echo Cannot save mail to file; exit $EX_TEMPFAIL; } 

if grep -q link_url in.$$; then #Just to make sure we dont connect to the DB unless the mail has the link_url word

#Capturing the For email id from the mail
e_id=`grep "for <" in.$$  | grep -Po "(?<=\<)[^']*(?=\>)"`
echo $e_id

#Fetching the id from user table and storing in u_id
u_id=`psql -t -h $dbHost -d $dbName -U $dbUser --variable emailAddress=\'$e_id\' << EOF
select id from users where email = :emailAddress LIMIT 1;
EOF`


#Fetching the Value from the user_custom_fields
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
