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
        echo "    ServerName $SITENAME";
        echo "    ServerAlias *.$SITENAME";
        echo "    DocumentRoot ${SITE_DIR}";
        echo "    RewriteEngine On";
        echo "    ProxyPreserveHost On";
        echo "    UseCanonicalName On";
        echo "    ProxyPass / http://0.0.0.0:8080/";
        echo "    ProxyPassReverse / http://0.0.0.0:8080/";
        echo "    ErrorLog ${SITE_DIR}/log/error.log";
        echo "    CustomLog ${SITE_DIR}/log/access.log combined";
        echo "</VirtualHost>";
    ) | tee /etc/apache2/sites-available/$SITENAME.conf >/dev/null 2>&1;
    echo -e "${GREEN}done${NC}";

    # restart apache
    echo -n "Restart apache service ... ";
    service apache2 restart
    echo -e "${GREEN}done${NC}";

    # update hosts file
    echo -n "Updating available hosts ... ";
    # remove if exists
    local domain=`echo "test.$SITENAME" | sed 's/\./\\\\./g'`;      # shield dots
    sed -i "/^127\.0\.0\.1\s*$domain$/d" /etc/hosts;                # remove lines by pattern
    # add
    echo "127.0.0.1        test.$SITENAME" | sudo tee -a /etc/hosts >/dev/null 2>&1;
    echo -e "${GREEN}done${NC}";
}





#-----------------------------------------------------------#
#                           MAIN
#-----------------------------------------------------------#

# set colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# validate required params
SITENAME=$1
if [ -z "$SITENAME" ]; then
    die "Website name cannot be empty";
fi;
if [ "$EUID" -ne 0 ]; then
    die "Please run as root";
fi;

# site dir
SITE_DIR="/var/www/$SITENAME"



#-----------------------------------------------------------#
# change apache config
configApache;

# setup docker-ci configs
PROXY_CONFIG="$SITE_DIR/proxy/config.yml"
PROXY_CONFIG_EXAMPLE="$SITE_DIR/proxy/config-example.yml"
if [ ! -f "${PROXY_CONFIG}" ] && [ -f "${PROXY_CONFIG_EXAMPLE}" ]
then
    echo -n "Setting up docker-ci proxy config ... ";
    # copy from example
    cp ${PROXY_CONFIG_EXAMPLE} ${PROXY_CONFIG} && chown -R `stat . -c %u:%g` ${PROXY_CONFIG}
    # remove example lines by pattern
    sed -i "/^\s*-\sexample.com\s*$/d" ${PROXY_CONFIG};
    sed -i "/^\s*-\sexample.loc\s*$/d" ${PROXY_CONFIG};
    echo "    - $SITENAME" | tee -a ${PROXY_CONFIG} >/dev/null 2>&1;
    echo -e "${GREEN}done${NC}";
fi;



#-----------------------------------------------------------#
# finish
echo "";
echo "Now you can see your docker websites at \"http://$SITENAME/\" and it subdomains";
echo -e "${YELLOW}Info: ${NC} to create new project just create unique ${YELLOW}projects/PROJECT_NAME/docker-compose.yml${NC} file. For more info visit ${YELLOW}https://github.com/demmonico/docker-ci${NC}";
echo -e "${YELLOW}Note: ${NC} to successful pulling from ${YELLOW}github.com${NC} you should copy your ${YELLOW}~/.ssh${NC} folder to ${YELLOW}config/ssh${NC} folder.";
echo -e "${GREEN}All done. Have a nice day :)${NC}";
echo "";
