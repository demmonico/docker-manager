#!/bin/bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/bash
#
# This script settings up docker-ci work on the DEV environment (Apache + Docker inside)
# NOTE Please run newsite.sh script before
#
# Format: ./install-dev.sh SITENAME
#   SITENAME is name of docker website domain when will be placed all child websites as subdomains of that
#-----------------------------------------------------------#



# die
function die
{
    local msg=$@;
    if [ -n "$msg" ]; then
        msg="Error: $msg";
    fi;
    echo -e "${RED}${msg}${NC}"  1>&2;
    exit 1;
}


# add apache config
function configApache
{
    echo "Configuring apache to make website available ...";

    # set apache site config
    echo -n "Writing apache config ... ";
    (
        echo "<VirtualHost *:80>";
        echo "    ServerName $sitename";
        echo "    ServerAlias *.$sitename";
        echo "    DocumentRoot /var/www/$sitename";
        echo "    RewriteEngine On";
        echo "    ProxyPreserveHost On";
        echo "    UseCanonicalName On";
        echo "    ProxyPass / http://0.0.0.0:8080/";
        echo "    ProxyPassReverse / http://0.0.0.0:8080/";
        echo "    ErrorLog /var/www/$sitename/log/error.log";
        echo "    CustomLog /var/www/$sitename/log/access.log combined";
        echo "</VirtualHost>";
    ) | sudo tee /etc/apache2/sites-available/$sitename.conf
    echo -e "${GREEN}done${NC}";

    # restart apache
    echo -n "Restart apache service ... ";
    sudo service apache2 restart
    echo -e "${GREEN}done${NC}";
}





#-----------------------------------------------------------#
#                           MAIN
#-----------------------------------------------------------#

# set colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# validate required params
sitename=$1
if [ -z "$sitename" ]; then
    die "Website name cannot be empty";
fi;
if [ "$EUID" -ne 0 ]; then
    die "Please run as root";
fi;



#-----------------------------------------------------------#
# change apache config
configApache;



#-----------------------------------------------------------#
# finish
echo "";
echo "Now you can see your docker websites at \"http://$sitename/\"";
echo "All done. Have a nice day :)";
echo "";
