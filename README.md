# Guacamole-master

## Basic guacamole installation without database


## Manual Installation-(tested on ubundu 18.04)

		sudo -s
		apt-get update
		
### Install the necessary dependencies for guacamole
		
		apt install -y  gcc-6 g++-6 libcairo2-dev libjpeg-turbo8-dev libpng-dev \
		libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev libfreerdp-dev \
		libpango1.0-dev libssh2-1-dev libvncserver-dev libssl-dev libvorbis-dev libwebp-dev libtelnet-dev libpulse-		   dev

### Install tomcat
		apt install tomcat8 tomcat8-admin tomcat8-common tomcat8-user -y

### Download Guacamole server, and build

		wget https://sourceforge.net/projects/guacamole/files/current/source/guacamole-server-0.9.14.tar.gz
		
		tar xzf guacamole-server-0.9.14.tar.gz 
		
		cd guacamole-server-0.9.14
		
		./configure --with-init-dir=/etc/init.d

		make CC=gcc-6

		make install

		ldconfig

### Download Guacamole client

		wget https://sourceforge.net/projects/guacamole/files/current/binary/guacamole-0.9.14.war

		mkdir /etc/guacamole

		mv guacamole-0.9.14.war /etc/guacamole/guacamole.war

		ln -s /etc/guacamole/guacamole.war /var/lib/tomcat8/webapps/

		mkdir /etc/guacamole/{extensions,lib}

		echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat8


### Enter values to /etc/guacamole/guacamole.properties

		vim /etc/guacamole/guacamole.properties

paste the below given to the file, if database authentication is used, comment out user-mapping section

		guacd-hostname: localhost
		guacd-port:    4822
		user-mapping:    /etc/guacamole/user-mapping.xml
		auth-provider:    net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider

### Link /etc/guacamole to /usr/share/tomcat*/.guacamole

		ln -s /etc/guacamole /usr/share/tomcat8/.guacamole


#### If database authentication is used skip this part of editing /etc/guacamole/user-mapping

		vim /etc/guacamole/user-mapping.xml

		<user-mapping>
			<authorize username="guacamoleusername" password="guacamolepassword">
				<connection name="Mst to be printed on to the guacamole UI">
					<protocol>commprotocol</protocol>
					<param name="hostname">ipaddress</param>
					<param name="port">portno</param>
					<param name="password">password</param>
					<param name="username">username</param>
				</connection>	
			</authorize>
		</user-mapping>
			
			
	guacamoleusername	=	username for guacamole
	guacamolepassword	=	password for guacamole
	commprotocol		=	communication protocol("ssh","vnc","rdp")
	ipaddress		=	ip address if remote server
	portno			=	listening port number of the commprotocol(default 3396 for RDP, 5900 for vnc, 22 for ssh)
					(if port is not working check the open ports from 'nmap $hostip')
	username		=	username of the remote server(not mandatory)
	password		=	password of the remote server(not mandatory)



### Download authentication extension for guacamole
- Download guacamole-auth-jdbc-0.9.14.tar.gz from [here](http://guacamole.apache.org/releases/0.9.14/).

		tar xvf guacamole-auth-jdbc-0.9.14.tar.gz
		cd guacamole-auth-jdbc-0.9.14/mysql/
		cp guacamole-auth-jdbc-mysql-0.9.14.jar /etc/guacamole/extensions


### Download mysql driver from apache
- Go to site [here](https://dev.mysql.com/downloads/connector/j/).

- Click on "Looking for the previous GA version?"

- Download mysql-connector-java-5.1.48.tar.gz

		tar xzf mysql-connector-java-5.1.48.tar.gz
		cp mysql-connector-java-5.1.48/mysql-connector-java-5.1.48.jar /etc/guacamole/lib


### Install Mariadb server

		apt-get update
		apt install mariadb-server
		systemctl status mariadb

### Configuring database
		cd guacamole-auth-jdbc-0.9.14/mysql/

### Creating Database,Users and granting privileges
		mysql -u root -p

		CREATE DATABASE guacamole_db;

		CREATE USER 'guacamole_user'@'localhost' IDENTIFIED BY 'some_password';
note:guacamole_user = guacamole_server machine user
eg: CREATE USER 'accl'@'localhost' IDENTIFIED BY 'some_password';

		GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
	
eg: GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'accl'@'localhost';

		FLUSH PRIVILEGES;

		quit

		ls schema/

		cat schema/*.sql | mysql -u root -p guacamole_db


### Configuring Guacamole for database authentication, edit /etc/guacamole/guacamole.properties
		vim /etc/guacamole/guacamole.properties
	
paste the below given to the file,

		#Mysql Properties
		mysql-hostname: localhost
		mysql-port: 3306
		mysql-database: guacamole_db
		mysql-username: guacamole_user
		mysql-password: some_password
	
note: replace guacamole_user with the selected user in database and replace some_password with the user' passsword

		systemctl restart tomcat8
		systemctl restart guacd


To login to the guacamole enter **http://<guacamole_server_ip>:8080/guacamole/**, the default **username and password** is '**guacadmin**' which should **_only be used to login to the server initially and must be deleted after the creation of custom username and password_**.

## End of Manual Installation


### Using script to install Guacamole(database authentication is not yet supported)

- clone the repo

- Edit the "*.properties" & "*.xml" files in guacamole-etc

- Make the script executable
	
	sudo chmod +x guac_install.sh

- run guac_install.sh
	- to build/install
		
		sudo -s
		./guac_install.sh build
	
	- to clean/uninstall the build
		
		./guac_install.sh clean
	
- to add new connections, update the .xml file and restart tomcat service

