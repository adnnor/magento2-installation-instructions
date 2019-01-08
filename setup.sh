#!/bin/bash
# Came from https://github.com/adnnor/virtualhost-generator
# @author: Adnan Shahzad
# @Email: adnnor@gmail.com

# Bugs
# 1. DocumentRoot missing public_html
# 2. VHOST has fpm entry with no fpm installation
# 3. Show default username and password for database.
# 4. Show complete details of configuration at the end of the script execution also save in .log


DUB="/var/www"
DIR="mage23"
ServerName="local.$DIR.com"
VHOST_FILE="${ServerName}.conf"
ServerAlias="local.$DIR.com"
DocumentRoot="$DUB/$DIR/public_html"
DocumentRoot_PUB="$DocumentRoot/pub"
FPM_HOST="127.0.0.1"
FPM_PORT="9000"
IP="127.0.0.1"
SAMPLE_CONF="conf.conf"

RESTORE=$(echo -en '\033[0m')
RED=$(echo -en '\033[00;31m')
GREEN=$(echo -en '\033[00;32m')
YELLOW=$(echo -en '\033[00;33m')
LRED=$(echo -en '\033[01;31m')
ABORT=$(echo -en '\033[07;31m')
LGREEN=$(echo -en '\033[01;32m')
LYELLOW=$(echo -en '\033[01;33m')

FILE="$0"
if [ "$EUID" -ne 0 ]; then 
    echo "Run as root e.g. sudo bash ${FILE} -u johndoe"
    exit 1
fi
if [[ -z $2 ]]; then
    echo "Run command with param e.g. sudo bash ${FILE} -u johndoe"
	exit 1
fi
CURRENT_USER=${2}
# SUDO=`sudo lsb_release -rs  2>&1`

# Thanks to BR0kEN-/string_functions.sh for substr and strpos functions
# URL: https://gist.github.com/BR0kEN-/a84b18717f8c67ece6f7

# @param string $1
#   Input string.
# @param int $2
#   Cut an amount of characters from left side of string.
# @param int [$3]
#   Leave an amount of characters in the truncated string.
substr()
{
    local length=${3}

    if [ -z "${length}" ]; then
        length=$((${#1} - ${2}))
    fi

    local str=${1:${2}:${length}}

    if [ "${#str}" -eq "${#1}" ]; then
        echo "${1}"
    else
        echo "${str}"
    fi
}

# @param string $1
#   Input string.
# @param string $2
#   String that will be searched in input string.
# @param int [$3]
#   Offset of an input string.
strpos()
{
    local str=${1}
    local offset=${3}

    if [ -n "${offset}" ]; then
        str=`substr "${str}" ${offset}`
    else
        offset=0
    fi

    str=${str/${2}*/}

    if [ "${#str}" -eq "${#1}" ]; then
        return 0
    fi

    echo $((${#str}+${offset}))
}
# END BR0kEN- credit

log() {
    
    local arg1=${1}
    local arg2=${2}

	if [[ $# -eq 2 ]] && [[ ! -z "$1" ]] && [[ ! -z "$2" ]]; then
		printf "$arg1" "$arg2" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" &>> .log
		printf "$arg1" "$arg2" 2>&1
	elif [[ $# -eq 1 ]] && [[ ! -z "$1" ]]; then
		printf "$arg1" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" &>> .log
		printf "$arg1" 2>&1
	else
		echo "error"
	fi   
}

abort() {
	log "${LRED}ERROR!${RESTORE}\n"
	printf '======\n' &>> .log
	printf '%s\n' "$1" &>> .log
	printf '======\n' &>> .log
	printf "\n\n${ABORT} Execution Interrupted ${RESTORE} Check .log for the error details ...\n\n"
	exit 1
}

apache_status() {
	log "Checking apache2 status ... "

	APACHE=`service --status-all | grep apache2`
	APACHE_STATUS=$(strpos "${APACHE}" "+")
	if [ "$APACHE_STATUS" == "" ]; then
		log "${LYELLOW}Oops! It is not running${RESTORE} ... starting apache2 service "
		APACHE_ACTIVE=`sudo service apache2 restart 2>&1`
		if [ $? -eq 0 ]; then
			log "... ${LGREEN}done${RESTORE}, apache is running now! \m/\n"
		else
			abort "$APACHE_STATUS"
		fi
	else 
		log "${LGREEN}it is running ... (Y)${RESTORE}\n"
	fi
}

mysql_status() {
	log "Checking MySQL status ... "

	MYSQL=`service --status-all | grep mysql`
	MYSQL_STATUS=$(strpos "${MYSQL}" "+")
	if [ "$MYSQL_STATUS" == "" ]; then
		log "${LYELLOW}Oops! It is not running${RESTORE} ... starting mysql service "
		MYSQL_ACTIVE=`sudo service mysql restart 2>&1`
		if [ $? -eq 0 ]; then
			log "... ${LGREEN}done${RESTORE}, mysql is running now! \m/\n"
		else
			abort "$MYSQL_ACTIVE"
		fi
	else 
		log "${LGREEN}it is running ... (Y)${RESTORE}\n"
	fi
}

printf "\n"

COLUMNS=$(tput cols) 
space="#############################################################" 
title="Welcome to Magento 2.3 Environment Setup and Installer" 
printf "%*s\n" $(((${#space}+$COLUMNS)/2)) "$space"
printf "%*s\n" $(((${#title}+$COLUMNS)/2)) "$title"
printf "%*s\n" $(((${#space}+$COLUMNS)/2)) "$space"
printf "\n"

OS=$(lsb_release -rs)
DISTRO=$(lsb_release -is)
if [[ ! $OS == "18.04" ]] && [[ ! $DISTRO == "Ubuntu" ]]; then
	printf "\n${ABORT} Execution Interrupted ${RESTORE} INCOMPATIBLE OS, this script is made for Ubuntu 18.04 LTS (Bionic Beaver) ...\n"
	exit 1
else
	log "Happy to see Ubuntu 18.04 LTS (Bionic Beaver) \m/ ... \n\n"
fi

log "Searching for apache ... "
APACHE_VERSION=$(dpkg -l | awk '$2 ~ /^apache2$/ { print $3 }')
if [ ! -z $APACHE_VERSION ]; then
	if dpkg --compare-versions $APACHE_VERSION ge 2.2; then
		log "${LGREEN}ok ... apache2 $APACHE_VERSION found!${RESTORE} \n"
		apache_status
	else
	    log "ok ... ${YELLOW}INCOMPATIBLE${RESTORE} apache2 $APACHE_VERSION found.\n"
	    log "Updating apache2 ... "
	    APACHE_UPDATE=`sudo apt-get --only-upgrade install -y apache2 2>&1`
		if [ $? -eq 0 ]; then
			log "... ${LGREEN}done!${RESTORE} Considering latest version ;) \n"
			apache_status
		else
			abort "$APACHE_UPDATE"
		fi
	fi
else
	log "${LYELLOW}Ohh! Failed to find apache2 :(${RESTORE}\n"
	log "Installing Apache ... "
    APACHE_INSTALL=`sudo apt-get install -y apache2 2>&1`
	if [ $? -eq 0 ]; then
		log "${LGREEN}done! \m/${RESTORE}\n"
	else
		abort "$APACHE_INSTALL"
	fi
fi

log "Checking ownership of $DUB ..."
DIR_USER=$(stat -c '%U' "$DUB")
DIR_GROUP=$(stat -c '%G' "$DUB")
if [[ ! -z $DIR_USER ]] || [[ ! -z $DIR_GROUP ]]; then
	if [[ $DIR_USER == "root" ]] || [[ $DIR_GROUP == "root" ]]; then
		log "Well .. it is $DIR_USER:$DIR_GROUP - ${YELLOW}not good.${RESTORE} Recommended setting is $USER:$USER ... \n"
		log "Changing ownership of $DUB ... "
		DUB_OWNERSHIP=`sudo chown $CURRENT_USER:$CURRENT_USER "$DUB" 2>&1`
		if [ $? -eq 0 ]; then
			log "${LGREEN}done!${RESTORE}\n"
		else
			abort "$DUB_OWNERSHIP"
		fi
	else
		log "${LGREEN} looks good ... ${RESTORE}it is $DIR_USER:$DIR_GROUP ... (Y) \n"
	fi
fi

log "Creating required directories ... "
MAKE_DIR=`mkdir -p "$DocumentRoot/public_html" && mkdir -p "$DocumentRoot/backup" 2>&1`
if [ $? -eq 0 ]; then
	sudo chown "$CURRENT_USER" -R "$DocumentRoot" 
	log "${LGREEN}done!${RESTORE}\n"
else
	abort "$MAKE_DIR"
fi


log "Enabling require apache2 mods ... "
REQ_MOD_ENABLE=`sudo a2enmod rewrite && sudo a2enmod alias && \
				sudo a2enmod env && sudo a2enmod setenvif 2>&1`
if [ $? -eq 0 ]; then
	log "${LGREEN}done!${RESTORE}\n"
else
	abort "$REQ_MOD_ENABLE"
fi

log "Creating VirtualHost (${ServerName}) ... "
GENERATE_CONF=`cp "${SAMPLE_CONF}" "${VHOST_FILE}" 2>&1`
if [ ! $? -eq 0 ]; then
	abort "$GENERATE_CONF"
fi
[ ! -z "${CURRENT_USER}" ] && sed -i "s/!USER!/${CURRENT_USER}/" $VHOST_FILE
[ ! -z "${DIR}" ] && sed -i "s/!DIR!/${DIR}/g" $VHOST_FILE
[ ! -z "${ServerName}" ] && sed -i "s/!ServerName!/${ServerName}/g" $VHOST_FILE
[ ! -z "${ServerAlias}" ] && sed -i "s/!ServerAlias!/${ServerAlias}/g" $VHOST_FILE
[ ! -z "${DocumentRoot}" ] && sed -i "s#!DocumentRoot!#${DocumentRoot}/pub#" $VHOST_FILE
[ ! -z "${FPM_HOST}" ] && sed -i "s#!FPM_HOST!#${FPM_HOST}#" $VHOST_FILE
[ ! -z "${FPM_PORT}" ] && sed -i "s#!FPM_PORT!#${FPM_PORT}#" $VHOST_FILE
COPY_CONF=`sudo mv "${ServerName}.conf" /etc/apache2/sites-available/ 2>&1`
if [ ! $? -eq 0 ]; then
	abort "$COPY_CONF"
fi

ACTIVATE_SITE=`sudo a2ensite "${ServerName}.conf" 2>&1`
if [ ! $? -eq 0 ]; then
	abort "$ACTIVATE_SITE"
fi

UPDATE_HOSTS=`sudo echo "$IP ${ServerName}" >> /etc/hosts 2>&1`
if [ ! $? -eq 0 ]; then
	abort "$UPDATE_HOSTS"
fi

RESTART_APACHE=`sudo service apache2 restart 2>&1`
if [ ! $? -eq 0 ]; then
	abort "$RESTART_APACHE"
fi

if [ $? -eq 0 ]; then
	log "${LGREEN}done!${RESTORE}\n"
fi

log "Taking backup of /etc/apache2/apache2.conf ... "
CONF_BK=`cp /etc/apache2/apache2.conf ./ 2>&1`
if [ $? -eq 0 ]; then
	log "${LGREEN}done!${RESTORE}\n"
else
	abort "$CONF_BK"
fi

log "Searching for MariaDB or MySQL ... "
MARIA_SEARCH=$(dpkg -l | awk '$2 ~ /^mariadb$/ { print $3 }')
MYSQL_SEARCH=$(dpkg -l | awk '$2 ~ /^mysql-server-5.7$/ { print $3 }')
if [ ! -z $MARIA_SEARCH ]; then
	if dpkg --compare-versions $MARIA_SEARCH ge 10.2; then
		log "${LGREEN}ok ... MariaDB $MARIA_SEARCH found!${RESTORE} \n"
		mysql_status
	else
	    log "ok ... ${YELLOW}INCOMPATIBLE${RESTORE} MariaDB $MARIA_SEARCH found.\n"
	    log "Updating MariaDB ... "
	    MYSQL_UPDATE=`sudo apt-get --only-upgrade install -y mariadb 2>&1`
		if [ $? -eq 0 ]; then
			log "... ${LGREEN}done!${RESTORE} Considering latest version ;) \n"
			mysql_status
		else
			abort "$MARIA_SEARCH"
		fi
	fi
else
	log "${LYELLOW}Ohh! Failed to find MariaDB,${RESTORE} it's ok ... \nLet's search for MySQL now ... "
	if [ ! -z $MYSQL_SEARCH ]; then
		if dpkg --compare-versions $MYSQL_SEARCH ge 5.6; then
			log "${LGREEN}ok ... MySQL $MYSQL_SEARCH found!${RESTORE} \n"
			mysql_status
		else
		    log "ok ... ${YELLOW}INCOMPATIBLE${RESTORE} MySQL $MYSQL_SEARCH found.\n"
		    log "Updating MySQL ... "
		    MYSQL_UPDATE=`sudo apt-get --only-upgrade -y install mysql-server mysql-client 2>&1`
			if [ $? -eq 0 ]; then
				log "... ${LGREEN}done!${RESTORE} Considering latest version ;) \n"
				mysql_status
			else
				abort "$MYSQL_UPDATE"
			fi
		fi
	else
		log "Ohh! Failed to find MySQL also :(\n"
		log "Preferring MariaDB 10.3 ... installing, please be patient ... "

		MARIADB_SOFT_PROP=`sudo apt-get install -y software-properties-common 2>&1`
		if [ ! $? -eq 0 ]; then
			abort "$MARIADB_SOFT_PROP"
		fi
		MARIADB_KEYSERVER=`sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8 2>&1`
		if [ ! $? -eq 0 ]; then
			abort "$MARIADB_KEYSERVER"
		fi
		MARIADB_APT_REPO=`sudo add-apt-repository 'deb [arch=amd64] http://mirror.zol.co.zw/mariadb/repo/10.3/ubuntu bionic main' 2>&1`
		if [ ! $? -eq 0 ]; then
			abort "$MARIADB_APT_REPO"
		fi
		MARIADB_APT_UPDT=`sudo apt-get update 2>&1`
		if [ ! $? -eq 0 ]; then
			abort "$MARIADB_APT_UPDT"
		fi

		export DEBIAN_FRONTEND="noninteractive"
		sudo debconf-set-selections <<< "maria-db-10.3 mysql-server/root_password password 123abc"
		sudo debconf-set-selections <<< "maria-db-10.3 mysql-server/root_password_again password 123abc"

		MYSQL_INSTALL=`sudo apt-get install -y mariadb-server 2>&1`
		if [ $? -eq 0 ]; then
			log "${LGREEN}done! \m/${RESTORE}\n"
		else
			abort "$MYSQL_INSTALL"
		fi
	fi
fi

log "Searching for installing PHP 7.2 and all of its required extensions ...\n"

install_php() {
	local ext="${1}"
	log ">> $ext ... "
	dpkg -s $ext &> /dev/null
	if [ $? -eq 0 ]; then
		log "${LGREEN}found!${RESTORE}\n"
	else
		log "${LYELLOW}not found${RESTORE} ... installing ... "
	    EXT_INSTALL=`sudo apt-get install -y "${ext}" 2>&1`
		if [ $? -eq 0 ]; then
			log "${LGREEN}done!${RESTORE}\n"
		else
			abort "$EXT_INSTALL"
		fi	
	fi
}

# # php7.2-simplexml
# # php7.2-dom
extensions=(libapache2-mod-php7.2 php7.2 php7.2-bcmath php7.2-common php7.2-curl php7.2-gd php7.2-intl \
			php7.2-mbstring php7.2-mysql php7.2-soap php7.2-xml php7.2-xsl php7.2-zip php7.2-json)
for i in "${extensions[@]}"; do
	install_php "$i"
done




printf "\n"