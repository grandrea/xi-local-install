## Setting up Xi1.x online search system

This is the documentation for setting up online searching WITHIN A LOCAL NETWORK, result databases and the rest with Xi1.


You need 4 machines, or VMs.

1. Apache PHP webserver ("webserver")
2. Storage server
3. Database server
4. Computational server/compute machine


All of them can be linux boxes. This configuration is done with Linux mint 20.03.

### configuration of the storage server
Install samba 

	sudo apt-get install samba openssh-server

Create a folder for storage for all the xi data. Remeber it will get HUUUGE.

	mkdir storage

create a share in samba

	sudo /etc/samba/smb.conf

and add the section from example_smb.conf at the bottom of the file, editing the path and if you want change the name last 2 lines for users with access (by default is a group called rsmbusers that will need to be created).

Create the user group in called "rsmbusers" like in the example smb.conf.

	sudo addgroup rsmbusers

and take note of the group id output (in my case 1001).

Add the primary user on this compurter to this group

	sudo usermod -a -G rsmbusers andrea


and restart samba


	sudo systemctl restart smb.service



### configuration of the database server
You need postGreSql (9.6 or later, we also tested with 12)

    sudo apt-get install postgresql postgresl-contrib postgresql-client sshfs openssh-server



For the database, you also need the definition of crosslinkers and modifications, as well as other databases these are in this repository in xisearch1_db_sqls. copy the 4 files in the directory to the database server. 

In the folder with the sql files, become the postgres user:

    sudo su postgres

then edit xidb_schema to change the password to something you like.

	vim xidb_schema.sql

and create the database:

    cat xidb_schema.sql | psql
This creates a datatabase called xi3.

Then do the same with the other files giving the database name:

    gunzip -c mods_xl.sql.gz | psql xi3
    cat basic_data.sql | psql xi3

If you have uniprot annotation database (download from mirror here), do the same for the uniprot database:

    gunzip -c uniprot.sql.gz | psql xi3 




Switch back to super user (or whichever user has permission to do this) and edit /etc/postgresql/VERSION_NUMBER/main/pg_hba.conf file to add the address of the webserver, the computational address, and the network- indicating which user from which network has access to what database. In our case, we give access to the whole subnetwork by adding the line

    hostssl    xi3    all    192.168.0.0/24    md5




Enable listening by editing /etc/postgresql/VERSION_NUMBER/main/postgresql.conf by editing listen_addresses as follows:

    listen_addresses = '*'

 restart the process

    sudo systemctl restart postgresql


#### add the storage server to the paths in the database

	psql xi3

then update as follows to match what is done in the mounting of storage server at the end of configuration of webserver

	update base_setting set setting='/mnt/xiStorage/' where id=1;


### configuration of the webserver
You need apache (2.4.38 or later) , PHP (7.3 or later) and the php-pgsql module

    sudo apt-get install apache2 php php-pgsql

Enable postgresql module in php by adding the line 

    extension=pgsql.so


to php.ini of your php install (usually /etc/php/version_number/apache2/php.ini) just below the top [PHP] line.

Then

    sudo systemctl restart apache2


to enable the module.


Once you configured the database client (steps above), you should be able to connect to the database server by:

    psql -h db xi3 bio_user

using the password you changed in the Database server configuration.


In the /var/www/html/ directory, you need to pull the xiview container.git 

for xiview PUBLIC:

    cd /var/www/html/
    git clone --recurse-submodules https://github.com/Rappsilber-Laboratory/xiView_container.git 


For rappsilber INTERNAL (virtual machine version), clone the internal branch:

    git clone -b VM --recurse-submodules https://github.com/Rappsilber-Laboratory/xiView_container.git 

make double sure to pull all remote submodules

	git submodule update --init --remote --recursive

You will then need to edit ownership and permissions to the cloned repository so that it www-data group.

    chgrp www-data -R xiView_container

and edit read/write permissions as needed.

You then need to change the file connectionString.php.default to look for the database server (via IP or domain name) and move it to a safe place (away from the directory of the repository! This can be a security risk that exposes your database/password). Copy this file to connectionString.php and edit. Put in the ip address of the host, xi3 as the database name, bio_user as the user and the password you chose in database configuration. 


You can then open your browser and go to localhost/xiView_container/userGUI/userLogin.html and see the login page.

#### create the first account

Work to do in UserGUI module

Fix the error reporting in the file in php/registerNewUser.php by adding

	require_once('../../vendor/php/PHPMailer-master/scr/Exception.php');
	
wherever you see require_once SMTP and PHPMailer statements.

Modify the regex rules in userGui/json/config.json. Edit the horrendous regex for email parsing to 

	"/*@.*/"

and edit the line 

	<input type="email"......>

in userReg.html and change the pattern to

	pattern=".*"


Then begin removing the captcha from the user login page.

remove line 52-53 from userReg.html to eliminate

	<div id="recaptchaWidget.....>

and the related error message.

In the php folder of userGui, change registerNewUser.php. Comment out (with the character "//" because comment in php is not #) line 12 and line 18 to disable the captcha.

In userReg.html, similarly dete lines 73,110 to disable captcha.

Copy xi_ini from the main folder to the directory above. You will need admin rights.

	cp -rv xi_ini ../

then edit emailInfo.php to have the email of the first user and it has to have a real host:

	"account"= "andrea.graziadei@tu-berlin.de",  
	"password" = "MYPASSWORD",
	"host" = "exchange.tu-berlin.de",

and 

	$urlRoot="http://192.168.0.6/xiView_container";
	

 Now go to the user login page in your browser localhost/xiView_container/userGUI/php/registerNewUser.php. Create the user. You should receive an email.
 
 Now you need to activate this user in the database, so go back to the DATABASE SERVER.

In the database (become postgres user, type psql etc)

	update user_in_group set group_id=1;

to enable login. Then check the number of the user id:

	select * from user_groups;

Then make the user an admin:


	insert INTO user_in_group (user_id,group_id) values (1,5);

That 1 in values should be the user_id number from the 	select * from user_groups; command. If you retype that command now you should see the user belonging to "internal" (group 1) and "admin" (group 5).


You can now login to your user and try to submit a search!

#### fixing xi to work with an empty database (not needed if on latest VM branch)

online Xi was not configured to run on an empty database. But this is an easy fix. Go to searchSubmit module/js.

edit the function mergeInFilenamesToAcquisitions at line 371.

before runNames.foreach add

	if (runNames) {

and a
 
	}
after the ; that closes the runNames block.

and the same for the block on the "acquistions" (yes, it is misspelled in the original) block.

	if (acquistions) {
	
	...
	});}

This should enable you to open the "new search" page in the history page.

#### mount the storage server samba share

define the storage server in /etc/hosts by adding the line with its ip e.g.

	192.168.0.7     storage

Add the line from credentials.txt to /etc/fstab on the webserver, changing user and password to match the user on the storage server that has access to the xiStorage share and the rsmbusers group.

Then create the xiStorage directory for the mount

	sudo mkdir /mnt/xiStorage

 
 
### configuration of the computational server

You need Java (8 or later. Versions 12 or above have been seen to cause problems, albeit this is just for xiFDR, xiSEARCH should still work)

    sudo apt-get install default-jre default-jdk
