#!/usr/bin/expect

set username [lindex $argv 0];
set password [lindex $argv 1];

spawn /usr/bin/mysql -u root -p
sleep 1
expect  "password: "
sleep 1
send "$password\r"
sleep 1
expect "*\> "
send "CREATE DATABASE guacamole_db;\r"
expect "*\> "
send "CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';\r"
expect "*\> "
send "GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO '$username'@'localhost';\r"
expect "*\> "
send "FLUSH PRIVILEGES;\r"
expect "*\> "
send "quit\r"
