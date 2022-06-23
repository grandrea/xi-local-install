## Setting up Xi1.x online search system

This is the documentation for setting up online searching, result databases and the rest with Xi1.


You need 4 machines, or VMs.

1. Apache PHP webserver ("webserver")
2. Storage server
3. Database server
4. Computational server/compute machine


All of them can be linux boxes. This configuration is done with Linux mint 20.03.

### configuration of the database server
You need postGreSql (9.6 or later, we also tested with 12)

    sudo apt-get install postgresql postgresl-contrib postgresql-client



For the database, you also need the definition of crosslinkers and modifications, as well as other databases these are in this repository in xisearch1_db_sqls. copy the 4 files in the directory to the database server. 

In the folder with the sql files, become the postgres user:

    sudo su postgres

then edit xidb_schema to change the password to something you like and create the database:

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

### configuration of the storage server
Install samba 


create a share



 
### configuration of the computational server

You need Java (8 or later. Versions 12 or above have been seen to cause problems, albeit this is just for xiFDR, xiSEARCH should still work)

    sudo apt-get install default-jre default-jdk