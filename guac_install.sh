#!/bin/bash

echo -e "\e[1;32mGuacamole Installation Started\e[0m"

TOP_DIR=$(cd $(dirname "$0") && pwd)
GUAC_ROOT_DIR="/etc/guacamole"
SUCCESS=0
ERROR=1

CMD="$1"

files="gcc-6 g++-6 libcairo2-dev libjpeg-turbo8-dev libpng-dev \
libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev libfreerdp-dev \
libpango1.0-dev libssh2-1-dev libvncserver-dev libssl-dev libvorbis-dev libwebp-dev \
libpulse-dev libtelnet-dev"

tomcatfiles="tomcat8 tomcat8-admin tomcat8-common tomcat8-user"

guacServerFileName="guacamole-server-0.9.14.tar.gz"
guacServerFileLink="https://sourceforge.net/projects/guacamole/files/current/source/$guacServerFileName"
guacClientFileName="guacamole-0.9.14.war"
guacClientFileLink="https://sourceforge.net/projects/guacamole/files/current/binary/$guacClientFileName"

guac_cmd_stat () {
	echo -e "\e[1;32mguac_cmd_stat\e[0m"
	echo "guac_cmd_stat is $1"

	if [ $1 != $SUCCESS  ]; then
		echo -e "\e[1;32mcmd failure...\e[0m"
		exit 1
	else
		echo "Done\n"
	
	fi
}

guac_apt_fetch () {	
	echo -e "\e[1;32mguac_apt-fetch files...\e[0m"
	###Installing guacamole required dependencies
	apt-get install -y $files
	guac_apt_fetch_retval="$?"
	guac_cmd_stat $guac_apt_fetch_retval
	
	echo -e "\e[1;31mcheck1............................\e[0m"	
	###Installing Tomcat servlet
	apt-get install $tomcatfiles -y
	guac_apt_fetch_retval="$?"
        guac_cmd_stat $guac_apt_fetch_retval
	
	echo "check2"	
	echo -e "\e[1;31mcheck2............................\e[0m"	
	###Downloading Guacamole server 
	wget -P $TOP_DIR $guacServerFileLink
	guac_apt_fetch_retval="$?"
        guac_cmd_stat $guac_apt_fetch_retval

	echo "check3"	
	echo -e "\e[1;31mcheck3............................\e[0m"	
	###Untar Guacamole server
	tar xzf $guacServerFileName 
	
	echo "check4"	
	echo -e "\e[1;31mcheck4............................\e[0m"	
	###Downloading Guacamole client
	wget -P $TOP_DIR $guacClientFileLink
	guac_apt_fetch_retval="$?"
        guac_cmd_stat $guac_apt_fetch_retval
	echo "check5"	
	echo -e "\e[1;31mcheck5............................\e[0m"	
}

guac_install () {
	echo -e "\e[1;32mguac_install...\e[0m"
	guacServDir=$(echo $guacServerFileName | sed 's/\.tar\.gz//g')
	
	echo -e "\e[1;32mGuac server Dir is $guacServDir...\e[0m"

	if [ -e $guacServDir  ]; then
		cd $guacServDir

		###Initializing init.d to Install a startup script for guacd
		echo -e "\e[1;32mconfiguring guacamole\e[0m"
		./configure --with-init-dir=/etc/init.d
		guac_install_retval="$?"
		guac_cmd_stat $guac_install_retval
		
		###Compiling code with gcc-6
		echo -e "\e[1;32mcompiling code with gcc-6\e[0m"
		make CC=gcc-6
		guac_install_retval="$?"
                guac_cmd_stat $guac_install_retval

		###Install the components that were built
		echo -e "\e[1;32minstalling components that were built\e[0m"
		make install
		guac_install_retval="$?"
                guac_cmd_stat $guac_install_retval

		###Create the necessary links and cache to the most recent shared libraries found in the guacamole server directory.
		echo -e "\e[1;32mCreating links ldconfig\e[0m"
		ldconfig
		guac_install_retval="$?"
                guac_cmd_stat $guac_install_retval

		###Check for Guacamole Root Directory /etc/guacamole(if yes then delete and make a new one)
		if [ -d $GUAC_ROOT_DIR  ]; then
			echo -e "\e[1;32m/etc/guacamole exists, deleting and remaking\e[0m"
			rm -r $GUAC_ROOT_DIR
			mkdir $GUAC_ROOT_DIR
		else
			echo -e "\e[1;32mNo /etc/guacamole found, making the directory\e[0m"
			mkdir $GUAC_ROOT_DIR
		fi
		
		echo -e "\e[1;32mMoving the client to guac root\e[0m"
		mv $TOP_DIR/$guacClientFileName $GUAC_ROOT_DIR/guacamole.war

		###Check for guacamole.war file in /var/lib/tomcat*/webapps
		if [ -e /var/lib/tomcat8/webapps/guacamole.war ]; then
        		echo -e "\e[1;32mchecking guacamole.war in tomcat in var/lib\e[0m"
			echo "exists"
			rm /var/lib/tomcat8/webapps/guacamole.war
		fi
		
		echo -e "\e[1;32mlinking guacamole.war with /var/lib/tomcat8/webapps...\e[0m"
		ln -s $GUAC_ROOT_DIR/guacamole.war /var/lib/tomcat8/webapps/
		guac_install_retval="$?"
                guac_cmd_stat $guac_install_retval
		
		
		mkdir $GUAC_ROOT_DIR/{extensions,lib}

		echo "GUACAMOLE_HOME=$GUAC_ROOT_DIR" >> /etc/default/tomcat8
		
		###copy .properties and .xml files to /etc/guacamole directory
		if [ -d $TOP_DIR/guacamole-etc ]; then
			cp $TOP_DIR/guacamole-etc/guacamole.properties $GUAC_ROOT_DIR
			cp $TOP_DIR/guacamole-etc/user-mapping.xml $GUAC_ROOT_DIR
		else
			echo -e "\e[1;31m$TOP_DIR/guacamole-etc not found,\n check the repo\e[0m"
		fi

		###Check for .guacamole file in /usr/share/tomcat*
                if [ -e /usr/share/tomcat8/.guacamole ]; then
                        echo "exists"
                        rm /usr/share/tomcat8/.guacamole
                fi
		
		ln -s $GUAC_ROOT_DIR /usr/share/tomcat8/.guacamole
		guac_install_retval = "$?"
                guac_cmd_stat $guac_install_retval
		systemctl enable guacd
		systemctl start guacd
		systemctl restart tomcat8
		echo -e "\e[1;32mInstallation Finished\e[0m"

	else
		echo -e "\e[1;31m$guacServDir file not found...[\e0m"
		exit 1
	fi

}


guac_clean () {

	echo -e "\e[1;32mGuac cleaning Initiated\e[0m"
	echo -e "\e[1;31mPurging dependencies\e[0m"
	apt-get purge -y $files
	guac_clean_retval="$?"
	guac_cmd_stat $guac_clean_retval
	
	echo -e "\e[1;31mPurging tomcat8\e[0m"
	apt-get purge -y $tomcatfiles
	guac_clean_retval="$?"
	guac_cmd_stat $guac_clean_retval
	
	echo -e "\e[1;31mRemoving lib files \e[0m"
	rm -r /var/lib/tomcat8/
	guac_clean_retval="$?"
	guac_cmd_stat $guac_clean_retval
	
	echo -e "\e[1;31mRemoving etc files\e[0m"
	rm -r /etc/guacamole/
	guac_clean_retval="$?"
	guac_cmd_stat $guac_clean_retval
	
	echo -e "\e[1;31mRemoving share files\e[0m"
	rm -r /usr/share/tomcat8
	guac_clean_retval="$?"
	guac_cmd_stat $guac_clean_retval
}


main () {
	echo -e "\e[1;32m$files...\e[0m"
	echo "1st arg is $1"
	case $CMD in
		build)
			apt-get update
			guac_apt_fetch
			guac_install
			;;
		clean)
			guac_clean
			;;
		*)
			echo -e "\e[1;32mNothing to do...???\n Do you want to build or clean:<build/clean>\e[0m"
	esac	
}

main
