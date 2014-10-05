dmProxy
=======

Discourse Mail Proxy
This small script is inspired by AlterMIME. but does a very specific task Unlike just appending a disclaimer text in a mail, it looks for a specific set of words in a mail and replaces that with a link. This was specifically developed for Discourse [http://discoversd.com/] to replace link_url text with a subdomain value fetched from a DB. You are most welcome to take and break it for your needs !!
 																		                                  Cheers,
																	                                   Anindya Roy
                                                                                                      i@anindya.me


Pre-Requisites
=============
Any Linux distribution with bash and Postfix already installed and running


Installation
============

Step 1. 
=======
Download dmProxy or simply do a git clone of this folder. I recommend to do it in a folder like /opt/dmProxy. But you are welcome to use your imagination. 

Step 2.
=======
open the dmProxy file in your favorit text editor and localize the first block with your system settings. Everything is commented pretty well. Though I am bad with spellings so pardon my typos ;-) ! here is a quick list of what all you would need to replace

Line 17: INSPECT_DIR=/var/spool/filter -- This is the folder where the mails will be captured and worked on. we will create it in the next step

Line 18: SENDMAIL=/usr/sbin/sendmail  -- Your sendmail location. do a whereis sendmail to find this

Line 19: HTTP="https" -- Change it with what suites you. HTTP or HTTPS. this will be appended at the beginning of the link

Line 20: DOMAIN="monitoringclient.com"  -- Your domain goes here 

Line 21: export PGPASSWORD="" -- Put your Postgres Password Here. yes plain text. bad idea. there are other ways to do this aswell. do some googling ;-)

Line 22: dbHost="" -- Put your PostgreSQL Hostname or IP here

Line 23: dbName="" #And DB Name Goes here. most likely it will be discourse.

Line 24: dbUser="" #Finally the db user. Remember the plain text password in line 21? create a readonly DB user and use it for this script.

And you are pretty much done with the script

Step 3.
=======
Create a folder where your mails will be kept while parsing. This folder needs to be secure enough so we will create a dedicated user for running our proxy and accessing this folder in next step
-#mkdir /var/spool/filter

Step 4.
=======
Create a user called filter like this
-#useradd -r -c "Postfix Filters" -d /var/spool/filter filter

Step 5.
=======
Now make sure the folder /var/spool/filter is owned by the filter user
-#chown filter:filter /var/spool/filter

Step 6.
=======
and tighten the security a bit
-#chmod 750 /var/spool/filter

Step 7.
=======
Now open postfix's master.cf with your favorit text editor and add a line just below
smtp      inet  n       -       y       -       -       smtpd
    -o content_filter=dmProxy:dummy   #This is the line to be added

NOTE: if you are using smtps then you have to append the same line below smtps as well. This should look like
smtps      inet  n       -       y       -       -       smtpd
    -o content_filter=dmProxy:dummy
    
Step 8.
=======
And now you have to define the dmProxy content filter that you have just created. go to the end of master.cf and append the following 2 lines

dmProxy     unix  -       n       n       -       -     pipe
  flags=Rq user=filter argv=/opt/dmProxy/dmProxy -f ${sender} -- ${recipient}
  
Step 9.
=======
And finally restart postfix
-#/etc/init.d/postfix restart

and you are done !! wasn't it easy ;-) ?
