# guacamole-fguactest

###Basic guacamole installation without database


#Manual Installation-(tested on ubundu 18.04)

sudo -s

apt-get update

apt install -y  gcc-6 g++-6 libcairo2-dev libjpeg-turbo8-dev libpng-dev \
libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev libfreerdp-dev \
libpango1.0-dev libssh2-1-dev libvncserver-dev libssl-dev libvorbis-dev libwebp-dev

apt install tomcat8 tomcat8-admin tomcat8-common tomcat8-user -y

wget https://sourceforge.net/projects/guacamole/files/current/source/guacamole-server-0.9.14.tar.gz

tar xzf guacamole-server-0.9.14.tar.gz 
cd guacamole-server-0.9.14

make CC=gcc-6

make install

ldconfig

wget https://sourceforge.net/projects/guacamole/files/current/binary/guacamole-0.9.14.war

mkdir /etc/guacamole

mv guacamole-0.9.14.war /etc/guacamole/guacamole.war

ln -s /etc/guacamole/guacamole.war /var/lib/tomcat8/webapps/

mkdir /etc/guacamole/{extensions,lib}

echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat8

vim /etc/guacamole/guacamole.properties

	guacd-hostname: localhost
	guacd-port:    4822
	user-mapping:    /etc/guacamole/user-mapping.xml
	auth-provider:    net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider


ln -s /etc/guacamole /usr/share/tomcat8/.guacamole


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



systemctl restart tomcat8
systemctl restart guacd


###Using script
clone the repo

Edit the "*.properties" & "*.xml" files in guacamole-etc

Make the script executable
	sudo chmod +x guac_install.sh

run guac_install.sh
	sudo -s
	./guac_install.sh build
	
to add new connections, update the .xml file and restart tomcat service

