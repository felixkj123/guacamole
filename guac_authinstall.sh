#!/bin/bash

TOM_VERSION="tomcat8"

TOP_DIR=$(cd $(dirname "$0") && pwd)
GUAC_ROOT_DIR="/etc/guacamole"
GUAC_FILES_DIR="$TOP_DIR/guacamole-files"
GUAC_SHARE_DIR="/usr/share/$TOM_VERSION"
GUAC_LIB_DIR="/var/lib/$TOM_VERSION"


SUCCESS=0
ERROR=1

CMD="$1"
TYPECMD="$2"

DATABASE_INSTALL='database'

files="gcc-6 g++-6 libcairo2-dev libjpeg-turbo8-dev libpng-dev \
libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev libfreerdp-dev \
libpango1.0-dev libssh2-1-dev libvncserver-dev libssl-dev libvorbis-dev libwebp-dev \
libpulse-dev libtelnet-dev expect"

tomcatfiles="tomcat8 tomcat8-admin tomcat8-common tomcat8-user"

guacServerFileName="guacamole-server-0.9.14"
guacServerFileLink="https://sourceforge.net/projects/guacamole/files/current/source/$guacServerFileName.tar.gz"
guacClientFileName="guacamole-0.9.14.war"
guacClientFileLink="https://sourceforge.net/projects/guacamole/files/current/binary/$guacClientFileName"

guacdatabaseName="mysql"
guacdbextversion="0.9.14"
guacdbextFileName="guacamole-auth-jdbc"
guacjavaconnversion="5.1.48"
guacjavaconnFileName="mysql-connector-java"

databaseServ="mariadb"

Black=`tput setaf 0`   #${Black}
Red=`tput setaf 1`     #${Red}
Green=`tput setaf 2`   #${Green}
Yellow=`tput setaf 3`  #${Yellow}
Blue=`tput setaf 4`    #${Blue}
Magenta=`tput setaf 5` #${Magenta}
Cyan=`tput setaf 6`    #${Cyan}
White=`tput setaf 7`   #${White}
Bold=`tput bold`       #${Bold}
Rev=`tput smso`        #${Rev}
Reset=`tput sgr0`      #${Reset}


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
	tar xzf $guacServerFileName.tar.gz
	
	echo "check4"	
	echo -e "\e[1;31mcheck4............................\e[0m"	
	###Downloading Guacamole client
	wget -P $TOP_DIR $guacClientFileLink
	guac_apt_fetch_retval="$?"
        guac_cmd_stat $guac_apt_fetch_retval
	echo "check5"	
	echo -e "\e[1;31mcheck5............................\e[0m"	
}


database_install () {
                ### Extract database extension for guacamole
                tar -C $TOP_DIR/ -xvf $GUAC_FILES_DIR/$guacdbextFileName-$guacdbextversion.tar.gz
                guac_db_retval="$?"
        	guac_cmd_stat $guac_db_retval
		
		cp $TOP_DIR/$guacdbextFileName-$guacdbextversion/$guacdatabaseName/$guacdbextFileName-$guacdatabaseName-$guacdbextversion.jar $GUAC_ROOT_DIR/extensions
		guac_db_retval="$?"
        	guac_cmd_stat $guac_db_retval

                ### Extract mysql driver 
                tar -C $TOP_DIR/ -xzf $GUAC_FILES_DIR/$guacjavaconnFileName-$guacjavaconnversion.tar.gz
                guac_db_retval="$?"
        	guac_cmd_stat $guac_db_retval
		cp $TOP_DIR/$guacjavaconnFileName-$guacjavaconnversion/$guacjavaconnFileName-$guacjavaconnversion.jar $GUAC_ROOT_DIR/lib


                ### Install database
                apt -y install $databaseServ-server
                guac_db_retval="$?"
                guac_cmd_stat $guac_db_retval

		systemctl status $databaseServ --no-pager

                cd $TOP_DIR
                #./install_mariadb.sh $1 $2
                mysql -u root -p$2 -e "CREATE DATABASE guacamole_db;"
                guac_db_retval="$?"
                guac_cmd_stat $guac_db_retval
		
		mysql -u root -p$2 -e "GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO '$1'@'localhost' IDENTIFIED BY '$2';"
                guac_db_retval="$?"
                guac_cmd_stat $guac_db_retval
		
		mysql -u root -p$2 -e "FLUSH PRIVILEGES;"
                guac_db_retval="$?"
                guac_cmd_stat $guac_db_retval
		
		sleep 5

                cat $TOP_DIR/$guacdbextFileName-$guacdbextversion/$guacdatabaseName/schema/*.sql | mysql -u root -p$2 guacamole_db
		guac_db_retval="$?"
                guac_cmd_stat $guac_db_retval


	#	sed -i '/Mysql Properties/a mysql-hostname: localhost' $GUAC_ROOT_DIR/guacamole.properties
	#	sed -i '/Mysql Properties/a mysql-port: 3306' $GUAC_ROOT_DIR/guacamole.properties
	#	sed -i '/Mysql Properties/a mysql-database: guacamole_db' $GUAC_ROOT_DIR/guacamole.properties
	#	sed -i "/Mysql Properties/a mysql-username: ${1}" $GUAC_ROOT_DIR/guacamole.properties
	#	sed -i "/Mysql Properties/a mysql-password: ${2}" $GUAC_ROOT_DIR/guacamole.properties		
	#	
	#	sed -i "s/guacamole_user/${1}/" $GUAC_ROOT_DIR/guacamole.properties		
	#	sed -i "s/some_password/${2}/" $GUAC_ROOT_DIR/guacamole.properties


	sed -i "/Mysql Properties/a mysql-hostname: localhost\n
        	/Mysql Properties/a mysql-port: 3306\n
        	/Mysql Properties/a mysql-database: guacamole_db\n
        	/Mysql Properties/a mysql-username: ${1}\n
        	/Mysql Properties/a mysql-password: ${2}" $GUAC_ROOT_DIR/guacamole.properties
}


guac_install () {
	echo -e "\e[1;32mGuacamole Installation Started\e[0m"
	guacServDir=$(echo $guacServerFileName.tar.gz | sed 's/\.tar\.gz//g')
	
	echo -e "\e[1;32mGuac server Dir is $guacServDir...\e[0m"

	if [ -d $guacServerFileName  ]; then
		cd $guacServerFileName

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
		if [ -e $GUAC_LIB_DIR/webapps/guacamole.war ]; then
        		echo -e "\e[1;32mchecking guacamole.war in tomcat in var/lib\e[0m"
			echo "exists"
			rm $GUAC_LIB_DIR/webapps/guacamole.war
		fi
		
		echo -e "\e[1;32mlinking guacamole.war with /var/lib/tomcat8/webapps...\e[0m"
		ln -s $GUAC_ROOT_DIR/guacamole.war $GUAC_LIB_DIR/webapps/
		guac_install_retval="$?"
                guac_cmd_stat $guac_install_retval
		
		
		mkdir $GUAC_ROOT_DIR/{extensions,lib}

		echo "GUACAMOLE_HOME=$GUAC_ROOT_DIR" >> /etc/default/tomcat8
		
		###copy .properties and .xml files to /etc/guacamole directory
		if [ -d $TOP_DIR/guacamole-etc ]; then
			cp $TOP_DIR/guacamole-etc/guacamole.properties $GUAC_ROOT_DIR
			
			case $TYPECMD in
       			         $DATABASE_INSTALL)
					 		sed -i '/basic-user-mapping/d' $GUAC_ROOT_DIR/guacamole.properties
                        	       			###Install mariadb
                         			  	database_install $1 $2 
       			                 ;;
       			         basic)
       			                 		cp $TOP_DIR/guacamole-etc/user-mapping.xml $GUAC_ROOT_DIR
       			                 ;;
       			         *)
       			                 echo -e "\e[1;32mEnter the correct mode\e[0m"
       			 esac

		else
			echo -e "\e[1;31m$TOP_DIR/guacamole-etc not found,\n check the repo\e[0m"
		fi

		###Check for .guacamole file in /usr/share/tomcat*
                if [ -e $GUAC_SHARE_DIR/.guacamole ]; then
                        echo "exists"
                        rm $GUAC_SHARE_DIR/.guacamole
                fi
		
		ln -s $GUAC_ROOT_DIR $GUAC_SHARE_DIR/.guacamole
		guac_install_retval="$?"
                guac_cmd_stat $guac_install_retval
		
		###Install mariadb
                #database_install $1 $2		

		systemctl enable guacd
		systemctl start guacd
		systemctl enable tomcat8
		systemctl restart tomcat8
		echo -e "\e[1;32mInstallation Finished\e[0m"

	else
		echo -e "\e[1;31m$guacServerFileName file not found...[\e0m"
		exit 1
	fi

}


guac_clean () {

	echo -e "\e[1;31mClean will wipe out all guacamole dependencies,tomcat, amd mariadb database. \n \
		Do you want to continue<yes/no>\e[0m"
	read user_clean_retval
	if [  $user_clean_retval = 'no' ] || [  $user_clean_retval = n  ]; then
		exit 0
	fi
	
	echo -e "\e[1;32mGuac cleaning Initiated\e[0m"
	echo -e "\e[1;31mPurging dependencies\e[0m"
	apt-get purge -y $files 
	guac_clean_retval="$?"
	guac_cmd_stat $guac_clean_retval
	
	echo -e "\e[1;31mPurging tomcat8\e[0m"
	apt-get purge -y $tomcatfiles
	guac_clean_retval="$?"
	guac_cmd_stat $guac_clean_retval
	
	echo -e "\e[1;31mPurging mariadb database\e[0m"
	apt-get purge -y mariadb-common
	guac_clean_retval="$?"
	guac_cmd_stat $guac_clean_retval
	
	echo -e "\e[1;31mRemoving lib files \e[0m"
	if [ -d $GUAC_LIB_DIR ]; then
		rm -r $GUAC_LIB_DIR
		guac_clean_retval="$?"
		guac_cmd_stat $guac_clean_retval
	fi
	
	echo -e "\e[1;31mRemoving etc files\e[0m"
	if [ -d $GUAC_ROOT_DIR ]; then
		rm -r $GUAC_ROOT_DIR
		guac_clean_retval="$?"
		guac_cmd_stat $guac_clean_retval
	fi
	
	echo -e "\e[1;31mRemoving share files\e[0m"
	if [ -d $GUAC_SHARE_DIR ]; then
		rm -r $GUAC_SHARE_DIR
		guac_clean_retval="$?"
		guac_cmd_stat $guac_clean_retval
	fi

	echo -e "\e[1;31mRemoving Downloaded files\e[0m"
	
	if [ -d $TOP_DIR/$guacServerFileName ]; then
		rm -r $guacServerFileName*
		guac_clean_retval="$?"
        	guac_cmd_stat $guac_clean_retval
	fi
	
	if [ -d $TOP_DIR/$guacjavaconnFileName-$guacjavaconnversion ]; then
		
		rm -r $TOP_DIR/$guacjavaconnFileName-$guacjavaconnversion
		guac_clean_retval="$?"
        	guac_cmd_stat $guac_clean_retval
	fi

	if [ -d $TOP_DIR/$guacdbextFileName-$guacdbextversion ]; then
		
		rm -r $TOP_DIR/$guacdbextFileName-$guacdbextversion
		guac_clean_retval="$?"
                guac_cmd_stat $guac_clean_retval
	fi
}


input_check () {

	case $1 in
		build)
			;;
		clean)
			;;
		database)
			;;
		basic)
			;;
		*)
			echo -e "\e[1;31mIncorrect input command/mode\e[0m"
			exit 1

	esac

}

usage () {
		echo "Usage: ./guac_authinstall.sh <command> <mode>\n
                      command : build/clean
                      mode    : database/basic"

}
main () {

clear
echo -e "


                                                ${Yellow}'.'
                            ${Green}'.:///:-.....'     ${Yellow}-yyys/-
                     ${Green}.://///++++++++++++++/-  ${Yellow}.yhhhhhys/'
                  ${Green}'.:++++++++++++++++++++++: ${Yellow}'yhhhhhhhhy-
          ${White}.+y' ${Green}'://++++++++++++++++++++++++' ${Yellow}':yhhhhyo:'
        ${White}-yNd. ${Green}'/+++++++++++++++++++++++++++//' ${Yellow}.+yo:' ${White}'::
       ${White}oNMh' ${Green}./++++++++++++++++++++++++++++++/:' '''' ${White}'mMh.
      ${White}-MMM:  ${Green}/+++++++++++++++++++++++++++++++++-.:/+:  ${White}yMMs
      ${White}-MMMs  ${Green}./++++++++++++++++++++++++++++++++++++/' ${White}.mMMy
      ${White}'NMMMy. ${Green}'-/+++++++++++++++++++++++++++++++/:.  ${White}:dMMMo
       ${White}+MMMMNy:' ${Green}'.:///++++++++++++++++++++//:-.' ${White}./hMMMMN'
       ${White}-MMMMMMMmy+-.${Green}''''.---::::::::::--..''''${White}.:ohNMMMMMMy
        ${White}sNMMMMMMMMMmdhs+/:${Green}--..........--${White}:/oyhmNMMMMMMMMMd-
         ${White}.+dNMMMMMMMMMMMMMMNNmmmmmmmNNNMMMMMMMMMMMMMMmy:'
            ${White}./sdNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNmho:'
          ${White}'     .:+shmmNNMMMMMMMMMMMMMMMMNNmdyo/-'
          ${White}.o:.       '.-::/+ossssssso++/:-.'       '-/'
           ${White}.ymh+-.'                           ''./ydy.
             ${White}/dMMNdyo/-.''''         ''''.-:+shmMNh:
               ${White}:yNMMMMMMNmdhhyyyyyyyhhdmNNMMMMMNy:
                 ${White}':sdNNMMMMMMMMMMMMMMMMMMMNNds:'
                     ${White}'-/+syhdmNNNNNNmdhyo/-'
"





	case $CMD in
		build)
			if [ "$#" -ne 2 ]; then
 				#echo "Usage: ./guac_authinstall.sh <command> <mode>\n
				#	command : build/clean
				#	mode    : database/basic"
				usage
				exit 1
			fi
			
			input_check $1
			input_check $2

			if [ $2 = database ]; then
				echo "Enter the guacamole_server system username"
				read server_username
				echo "Enter the guacamole_server system password"
				read -s server_password
			
			else
				usage
				exit 1
			fi
			apt-get update
			guac_apt_fetch
			guac_install $server_username $server_password
			;;
		clean)
			guac_clean
			;;
		*)
			echo -e "\e[1;32mNothing to do...???\n Do you want to build or clean:<build/clean>\e[0m"
	esac	
}

main $@
