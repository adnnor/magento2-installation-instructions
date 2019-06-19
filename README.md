## Bash script
I am provisioning bash script (beta) for the clean installation of **Ubuntu 18.04 LTS (Bionic Beaver)** to setup complete environment for Magento 2.3.

**Usage**

Clone the repo and execute `sudo bash setup.sh -u johndoe` (`johndoe` is your username).

**Features**

This bash script offers;

- Apache installation and configuration
- VirtualHost (local.mage23.com)
- MariaDB 10.3
- PHP 7.2 with required dependencies
- PHP FPM

> **Note**: DO NOT modify the script until you know what you are doing.

**You can use this script,**
- If you need a quick setup on clean installation of Ubuntu 18.04 LTS.
- If you hate repeatitions or tired of setup the same environment over and over again.

**Don't use this,**
- If you don't know the LAMP stack configuration.
- If you are not certain about technologies/features this bash script provisions for you.
- If you are new to LAMP stack configuration and love to learn, skip this and follow the instruction given below.

**Your suggestions and contributions are valuable.**

# Magento 2.3 Environment Setup & Installation

Instructions to setup the environment and install Magento 2.3 under Ubuntu 16.04 LTS and 18.04 LTS.

## Features and Applications
- PHP 7.2 extensions for Magento 2.3
- MariaDB 10.4
- Apache 2.4
- PHP FPM
- VirtualHost dev.magento.com
- [n98-magerun2](https://files.magerun.net/)
- XDebug
- SendMail
- [Composer](https://getcomposer.org/download/)

## Install Apache 2.4
Magento 2.3 requires Apache 2.2 or 2.4 with `mod_rewrite` and `mod_version` enabled. Open you terminal and execute
```bash
sudo apt-get install apache2
```
Check if Apache is installed
```bash
apache2 -v
```
If above command is outputting the Apache version then you successfully installed the Apache, now confirm that Apache is running
```bash
sudo service apache2 status
```
Open your browser and enter `http://localhost/` you will see welcome page. Open your terminal (CTRL+ALT+T) and run `sudo chown $USER:$USER -R /var/www` it will change the ownership of `/var/www/` to you so you can create and modify files and directories under `/var/www/`.
Following are useful Apache commands
- `apache2 -M` to list all active modules of Apache.
- `apache2 -V` to get the Apache version
If you are encounter with `Config variable ${xxx} is not defined` error, it is because you directly executed the apache2 binary. In Ubuntu the apache config relies on the **envvar** file which is only activated if you start apache with apachectl, so either run `apachectl -M` or execute `source /etc/apache2/envvars` and everything will be good.

**Enable required/useful Apache modules for Magento**
- `sudo a2enmod rewrite` - Enables URL Rewrite.
- `sudo a2enmod alias` - Enables Alias command.
- `sudo a2enmod env` - Enables Environment Variable.
- `sudo a2enmod setenvif` - Enables Environment Variable based on condition.
- `sudo a2enmod version` - Enables Version module.

> If you get an error `ERROR: Module version does not exist!` and `apachectl -M | grep version` outputs `version_module (static)` then its mean mod_version is statically compiled into apache2 package and works automatically.

One more thing, modify Apache defafult configuration so it allow .htaccess to override default settings, otherwise .htaccess under `DocumentRoot` will not work, `sudo nano /etc/apache2/apache2.conf` and search for the following block;
```bash
<Directory /var/www/>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
</Directory>
```
Replace `AllowOverride None` with `AllowOverride All`.
## Setup VirtualHost
Previously we were able to access Apache's welcome page over `http://localhost` it is coming from `/var/www/html/`, I don't want to put my Magento installation under `/var/www/html/magento/` and access it like `http://localhost/magento/` so I will create separate VirtualHost.

Head to my other repo for a nice and easy [VirtualHost Generator](https://github.com/adnnor/virtualhost-generator) and generate `dev.magento.com` or whatever you want, make sure it is working, open the browser and browse for `http://dev.magento.com/` (in my case) and you will see empty directory listing. We will modify the VirtualHost later to best fit for our Magento environment.
## Install MariaDB
If you have any previous version of MariaDB, check its version and uninstall if it is not compatible with Magento 2.3. Remember Magento 2.3 supports MariaDB 10.x or MySQL 5.6, 5.7, skip this step if you already have one of them.

Uninstall previous version
```bash
sudo apt-get remove mariadb-server mariadb-client
```
Check the MariaDB version
- Login to MariaDB `mysql -u root -p`
- When you are logged in run `SELECT VERSION();`

REMEMBER the root password which you will provide during installation, we need this to login to MariaDB.
```bash
sudo apt-get install software-properties-common
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
# Ubuntu Xenial Xerus (16.04 LTS)
sudo add-apt-repository 'deb [arch=amd64] http://mirror.zol.co.zw/mariadb/repo/10.3/ubuntu xenial main'
# Ubuntu Bionic Beaver (18.04 LTS)
sudo add-apt-repository 'deb [arch=amd64] http://mirror.zol.co.zw/mariadb/repo/10.3/ubuntu bionic main'
sudo apt update
sudo apt install mariadb-server mariadb-client
```
After successful MariaDB installation, create a new database for Magento;
```bash
mysql -u root -p
# Enter root password which you entered during installation.
# Once you are inside MariaDB console
CREATE DATABASE magento;
# Type exit to get out from the console
```
## PHP 7.2
According to [Magento 2.3 System Requirements](https://devdocs.magento.com/guides/v2.3/install-gde/system-requirements-tech.html) we need following extensions
- bc-math (Magento Commerce only) => php7.2-bcmath
- curl => php7.2-curl
- dom => php7.2-dom
- gd => php7.2-gd
- intl => php7.2-intl
- mbstring => php7.2-mbstring
- PDO/MySQL => php7.2-mysql
- SimpleXML => php7.2-simplexml
- soap => php7.2-soap
- libxml => php7.2-xml
- xsl => php7.2-xsl
- zip => php7.2-zip
- json => php7.2-json
- iconv => php7.2-iconv is part of php7.2-common
- ctype => php7.2-ctype is part of php7.2-common
- spl => This extension is available and compiled by default in PHP 5.0.0, as of PHP 5.3.0 this extension can no longer be disabled and is therefore always available.
- openssl => I found that PHP 7.x has openssl compiled within the core and doesn't need an external extension.
- hash => As of PHP 5.1.2, the Hash extension is bundled and compiled into PHP by default, As of PHP 7.2.0, the Hash extension is a core PHP extension, so it is always enabled.

First get the current PHP status along with the enabled extensions
```bash
php -v // to get PHP version
php -me // to list enabled extensions
```
Remember that `php` in terminal will display the version details for `php` activated for the `bash`, your all php versions may located under /usr/bin/ so make sure you are searching all rooms.

If you current php version is satisfied by Magento 2.3 minimum requirement, you can skip this step.

Ubuntu Bionic Beaver is shipped with PHP 7.2 so you don't to use any PPA, run following command to install PHP with all required extensions on Ubuntu 18.04 LTS (Bionic Beaver).

```bash
sudo apt-get install libapache2-mod-php7.2 php7.2 php7.2-bcmath php7.2-common php7.2-curl \
      php7.2-dom php7.2-gd php7.2-intl php7.2-mbstring php7.2-mysql php7.2-simplexml \
      php7.2-soap php7.2-xml php7.2-xsl php7.2-zip php7.2-json
```
If you are using Ubuntu 16.04 LTS (Xenial Xerus), follow the below given instructions
```bash
sudo add-apt-repository ppa:ondrej/php
sudo apt-get -y update
sudo add-apt-repository ppa:ondrej/php
sudo apt-get -y update
sudo apt-get install libapache2-mod-php7.2 php7.2 php7.2-bcmath php7.2-common php7.2-curl \
      php7.2-dom php7.2-gd php7.2-intl php7.2-mbstring php7.2-mysql php7.2-simplexml \
      php7.2-soap php7.2-xml php7.2-xsl php7.2-zip php7.2-json
```
Now we have to test our PHP installation, create a new document, lets say, test.php under /var/www/html with following content;
```php
<?php

phpinfo();

?>
```
Now open your browser and type `http://localhost/test.php`, you can use your VirtualHost also, create aforementioned file under document root of your VirtualHost, in my case it is `/var/www/magento/public_html/` and visit `http://dev.magento.com/test.php` if you see a page with tons of useful information with PHP version, Congratulations! You have successfully installed PHP.

Notice `Server API`, we will get back to this.

## Install and Configure SendMail
Run `which sendmail` to check whether you have SendMail installed or not. Follow the steps to install SendMail.

- `sudo apt-get install sendmail`
- Configure `/etc/hosts` file, make sure the line looks like `127.0.0.1 localhost`
- `sudo sendmailconfig` and answer `Y` to everything
- `sudo service sendmail restart` to restart sendmail
- Test your installation, execute `echo "Subject: sendmail test" | sendmail -v username@host.com`
## XDebug
Open your terminal and run `sudo apt install php-xdebug`, it will install XDebug, to test the installation run `php -v`, if you see following similar output, you have finished installing XDebug.
- `sudo apt install php-xdebug` to install xdebug.
- Now enable stack trace, edit `/etc/php/7.2/mods-available/xdebug.ini` and put `xdebug.show_error_trace = 1`
- `sudo service apache2 restart`.
- Run `php -m` and confirm that xdebug is under the active PHP extensions list, or run `php -v` and find the following similar output;
```bash
PHP xxx
Copyright (c) xxx
with Xdebug xxx, Copyright (c) 2002-2018, by Derick Rethans
```
## n98-magerun2
> n98-magerun2 is the swiss army knife for Magento developers, sysadmins and devops. The tool provides a huge set of well tested command line commands which save hours of work time. All commands are extendable by a module API.

New [version 3.0](https://magerun.net/v3-0-0-released-with-magento-2-3-support/) has been released upon Magento 2.3, so it is recommended to delete older version of n98-magerun2 (if any) and install a new 3.0 version.

Follow the [link](https://github.com/netz98/n98-magerun2) for detailed instructions.
## PHP FPM
PHP scripts are handled and executed in two ways;

- As Apache's Module (mod_php).
- As PHP FPM, standalone process manager. 

The most popular method to execute PHP is mod_php (Apache Module for PHP), it is embedded in Apache processes thus handles and execute PHP script itself, major downsides of mod_php are; 

- Consumes more server resources because the mod_php runs as Apache module and it opens a new footprint for each request.
- All files created by PHP script is owned by Apache owner e.g. www-data and it makes common permission issues when you are executing Magento's bin commands.

The other way to handle PHP requests is PHP FPM (**F**astCGI **P**rocess **M**anager).

> PHP-FPM (FastCGI Process Manager) is an alternative PHP FastCGI implementation with some additional features useful for sites of any size, especially busier sites. Find more about PHP FPM [here](https://php-fpm.org/).

PHP FPM runs as a standalone process manager, Apache communicates FPM using Apache's mod_fastcgi or mod_fcgid and treats it a separate server responsible to execute PHP scripts.

> Note: `mod_fcgid` is the free variant of `mod_fastcgi`. 

Using PHP FPM you have two major benefits

- PHP scripts are executed separately so your Apache server will not be involved in memory eating processes as previously described.
- You will not face permission issues as everything related to configuration and permissions is under PHP-FPM.
- You can run different PHP versions for different projects using PHP FPM Pools, Pool is like a separate PHP container with different permission groups, user and configuration, you can declare as many Pools as you want.


> Note: Apache handles the script execution in two ways, CGI and FastCGI, both have nothing to do with PHP, it only helps Apache to handle scripts, CGI is old and slow, FastCGI is new and fast.

**Install & Configure PHP FPM**
```bash
sudo apt-get install php7.2-fpm
sudo apt-get install libapache2-mod-fcgid
```
> Note: On Ubuntu 16.04 (Xenial Xerus) you can install `libapache2-mod-fastcgi` but on Ubuntu 18.04 (Bionic Beaver) fcgid is default avaiable, if you prefer fastcgi you can [download](https://packages.ubuntu.com/xenial/libapache2-mod-fastcgi) and install using `sudo dpkg -i <path-to-package-name>` or add `xenial` repository under `apt.list` of Bionic Beaver but it may crash your system.
**Enabled required modules to run PHP FPM properly**
```bash
sudo a2enmod proxy
sudo a2enmod proxy_http
# Run if Ubuntu 18.04 (Bionic Beaver)
sudo a2enmod proxy_fcgi
sudo a2enmod fcgid
# Run Ubuntu 16.04 (Xenial Xerus)
sudo a2enmod proxy_fastcgi
sudo a2enmod fastcgi
```
Edit `sudo nano /etc/php/7.2/fpm/pool.d/www.conf`, search for something similar to `listen = /run/php/php7.2-fpm.sock` and replace it with `listen = 127.0.0.1:9000`, also make sure that `user` and `group` directive is set to your user and group so you don't have issues running Magento's bin commands, don't mix `user` with `listen.owner` or `listen.group`, your modified settings must look like below

```bash
listen = 127.0.0.1:9000

user = johndoe
group = johndoe

; don't edit following two settings
listen.owner = www-data
listen.group = www-data
```

Edit your VirtualHost file, in my case it is `sudo nano /etc/apache2/sites-enabled/dev.magento.com.conf`, modify `DocumentRoot` to `/var/www/magento/public_html/pub` (`pub` at the end), add `ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/magento/public_html/pub` to next line.

```bash
sudo service apache2 restart
sudo service php7.2-fpm restart
```
Are you eager to know why I have changed the DocumentRoot? [Magento devdocs](https://devdocs.magento.com/guides/v2.3/install-gde/tutorials/change-docroot-to-pub.html) explains it in detail.

> If you installed Magento in Apache’s default docroot `/var/www/html`, the Magento file system is vulnerable because it’s accessible from a browser. This topic describes how to change the Apache docroot on an existing Magento instance to serve files from the Magento `pub/` directory, which is more secure.

> Serving files from the `pub/` directory prevents site visitors from accessing the Web Setup Wizard and other sensitive areas of the Magento file system from a browser.
## Install Magento
```bash
# In my case
cd /var/www/magento/public_html
composer create-project --repository-url=https://repo.magento.com/ \
                        magento/project-community-edition:2.3.* .
```
Enter Magento Marketplace Public Key as `Username` and Private Key as `Password`. It will take some time to download all depedences. 

Once download is finished, rename `php.ini.sample` to `php.ini` and make sure that it contains following must-have configuration;

```bash
memory_limit = 2G
max_execution_time = 18000
display_errors = Off
```

> **DISCLAIMER:**
> These instructions are made available for learning purposes only as well as give you general information of Magento 2.3 environment setup and installation, I endeavor to provide accurate and timely information, there can be no guarantee that such information is accurate as of the date it is received or that it will continue to be accurate in the future. No one shall act on such information without appropriate professional advice after a thorough examination of the particular situation or circumstances, by following these instructions you also understand that any kind of naming convention or label is used as an example only and owner of this information will not be responsible of any data lose or whatsoever.
