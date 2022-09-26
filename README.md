## Magento 2.4.5

We are going to setup the AWS EC2 instance for Magento 2.4.5 using Ubuntu 22. These instruction includes the following features;

Notes
- This guide is created for learning purposes, its is not recommended for production servers.
- Please help me to improve this guide.

Make sure your EC2 instance has minimum 5GB of RAM and 3 CPUs

## Technology stack
- Apache 2.4
- PHP 8.1 along with FPM
- MySQL 8.0
- ElasticSearch
- SendMail
- [Composer](https://getcomposer.org/)
- [n98-magerun2](https://files.magerun.net/)
- XDebug

## Install Apache
```bash
# Apache 2.4
sudo apt install apache2
```

Open your browser and enter `http://0.0.0.0/` you will see welcome page. Open your terminal (CTRL+ALT+T) and run `sudo chown $USER -R /var/www` it will change the ownership of `/var/www/` to `ubuntu` (its default username assigned to every Ubuntu instance) so you can create and modify files and directories under `/var/www/`.

Note: 0.0.0.0 is your Elastic IP address associated with EC2 instance.

**Following are useful Apache commands**
- `apache2 -M` to list all active modules of Apache.
- `apache2 -V` to get the Apache version
- `apachectl -V` to get the Apache version
If you are encounter with `Config variable ${xxx} is not defined` error, it is because you directly executed the apache2 binary. In Ubuntu the apache config relies on the **envvar** file which is only activated if you start apache with apachectl, so either run `apachectl -M` or execute `source /etc/apache2/envvars` and everything will be good.

You have an option of creating a virtual host but right now we will modify the existing default configurations.
So open the file `sudo nano /etc/apache2/sites-enabled/000-default.conf` and modify the file as given below.
```bash
DocumentRoot /var/www/html/pub
Protocols h2 http/1.1
<Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
</Directory>
```

## Install PHP
Ubuntu 22.04.1 LTS (Jammy Jellyfish) is shipped with PHP 8.1. No need to add any other repository.
```bash
sudo apt install php8.1-bcmath php8.1-ctype php-json php8.1-xml php8.1-curl php8.1-dom php8.1-fileinfo php8.1-gd php8.1-iconv php8.1-intl php8.1-mbstring php8.1-mysql php8.1-simplexml php8.1-soap php8.1-sockets php8.1-tokenizer php8.1-xmlwriter php8.1-xsl php8.1-zip libxml2 libssl-dev php8.1-fpm libapache2-mod-fcgid -y
```

Adobe Commerce requires additional SPL extension, its the part of PHP core so above command will work for both Adobe Commerce and Magento Open Source

**Disable unwanted Apache modules**
- `sudo a2dismod php8.1` - We will use PHP FPM instead of PHP apache module.
- `sudo a2dismod mpm_prefork` - This is the required module for PHP apache module.

**Enable required Apache modules**
- `sudo a2enmod rewrite` - Enables URL Rewrite.
- `sudo a2enmod alias` - Enables Alias command.
- `sudo a2enmod setenvif` - Enables Environment Variable based on condition.
- `sudo a2enmod mpm_event` - Its required for PHP FPM.
- `sudo a2enmod proxy_fcgi` - Its required for PHP FPM.
- `sudo a2enmod http2` - For the complete set of features described by RFC 7540 and supports HTTP/2 over cleartext (http:), as well as secure (https:) connections. The cleartext variant is named `h2c`, the secure one `h2`, [Details](https://httpd.apache.org/docs/2.4/howto/http2.html).

> If you get an error `ERROR: Module version does not exist!` and `apachectl -M | grep version` outputs `version_module (static)` then its mean mod_version is statically compiled into apache2 package and works automatically.

**Enable PHP FPM configuration for Apache**
- `sudo a2enconf php8.1-fpm`

PHP is successfully Installed. Complete settings are under `/etc/php/8.1/fpm/php.ini`.

## Install MySQL
Ubuntu 22.04.1 LTS (Jammy Jellyfish) is shipped with MySQL 8.0. No need to add any other repository.

```bash
sudo apt install mysql-server mysql-client
```

If the installation doesn't prompt for password, we can set up the root password by executing `sudo mysql_secure_installation` or follow the steps below;

```bash
# start the MySQL cli with sudo
sudo mysql

# execute following MySQL query
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password by 'g0oDp@s$w0Rd';

# exit and login to MySQL cli with the password
mysql -u root -p
```

Its is strongly recommended that we should not use root user, instead create another user, root user has administrative access to MySQL.

## Install ElasticSearch

```bash
# install Java Development Kit (A dependency to run ElasticSearch
sudo apt install default-jdk

# ElasticSearch v7.17
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - 

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list 

sudo apt update && sudo apt install elasticsearch 

# Enabling elasticsearch service will start the service whenever instance reboots.
sudo systemctl enable elasticsearch

sudo systemctl start elasticsearch
```
## Install Composer
Ubuntu 22.04 has Composer 2.2 in its upstream repositories.
```bash
sudo apt install composer
```
or you may install it from the [official source](https://getcomposer.org/download/)

## Install n98-magerun2
The swiss army knife for Magento developers, sysadmins and devops. The tool provides a huge set of well tested command line commands which save hours of work time. All commands are extendable by a module API.
```bash
curl -sS -O https://files.magerun.net/n98-magerun2-latest.phar

chmod +x ./n98-magerun2.phar

sudo mv ./n98-magerun2-latest.phar /usr/bin/magerun2

magerun2 --version
```


## Install and Configure SendMail
- `sudo apt install sendmail`
- `hostname` to show your instance hostname, copy the output, for example the host name is `ip-9-88-211-12`.
- `nano /etc/hosts` to open the file, and paste the hostname, make sure the line looks like `127.0.0.1 localhost ip-9-88-211-12`
- `sudo sendmailconfig` and answer `Y` to everything
- `sudo service sendmail restart` to restart sendmail
- Test your installation, execute `echo "Subject: sendmail test" | sendmail -v username@host.com`


## XDebug
```bash
sudo apt install php-xdebug
```
- Enable stack trace, edit `/etc/php/7.2/mods-available/xdebug.ini` and put `xdebug.show_error_trace = 1`
- Run `php -m` and confirm that xdebug is under the active PHP extensions list, or run `php -v` and find the following similar output;
```bash
PHP xxx
Copyright (c) xxx
with Xdebug xxx, Copyright (c) 2002-2018, by Derick Rethans
```
## Bonus: Setup VirtualHost
Previously we were able to access Apache's welcome page over `http://localhost` it is coming from `/var/www/html/`, I don't want to put my Magento installation under `/var/www/html/magento/` and access it like `http://localhost/magento/` so I will create separate VirtualHost.

Head to my other repo for a nice and easy [VirtualHost Generator](https://github.com/adnnor/virtualhost-generator) and generate `dev.magento.com` or whatever you want, make sure it is working, open the browser and browse for `http://dev.magento.com/` (in my case) and you will see empty directory listing. We will modify the VirtualHost later to best fit for our Magento environment.

## Bonus: Install Magento
```bash
cd /var/www/html

composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:2.4.5 .
```

Enter Magento Marketplace Public Key as `Username` and Private Key as `Password`. It will take some time to download all depedences. 

```bash
bin/magento setup:install --base-url=http://0.0.0.0/ --db-host=localhost --db-name=magento --db-user=root --db-password='g0oDp@s$w0Rd' --admin-firstname=admin --admin-lastname=admin --admin-email=admin@admin.com --admin-user=admin --admin-password=admin321 --language=en_US --currency=USD --use-rewrites=1 --search-engine=elasticsearch7 --elasticsearch-host=127.0.0.1 --elasticsearch-port=9200
```

Note: 0.0.0.0 is your Elastic IP address associated with EC2 instance.

After the successful installation; **set up the permissions**;

```bash
sudo find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
sudo find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
sudo usermod -a -G www-data ubuntu
sudo chown -R :www-data .
sudo chmod u+x bin/magento
```

Note: `ubuntu` is the default username assigned to Ubuntu based EC2 instances.

Now install the sample data

```bash
bin/magento sampledata:deploy

# update the database
bin/magento setup:upgrade

# setup the deployment mode (developer|production)
bin/magento deploy:mode:set production

# deploy static content (in developer mode it is auto deployed but in production the following command is used to deploy static content. The -f flag is used to forceful content deployment in developer mode.
bin/magento setup:static-content:deploy

# clean cache
bin/magento cache:clean
```

Useful bin/magento commands

```bash
# update the base URL
bin/magento config:set web/secure/base_url http://0.0.0.0/

# turn static signature in the js and css URLs
bin/magento config:set dev/static/sign 0

# show the specific configuration value, in follow case, check whether the static signature is enabled or disabled.
bin/magento config:show dev/static/sign
```

> **DISCLAIMER:**
> These instructions are made available for learning purposes only as well as give you general information of Magento 2.3 environment setup and installation, I endeavor to provide accurate and timely information, there can be no guarantee that such information is accurate as of the date it is received or that it will continue to be accurate in the future. No one shall act on such information without appropriate professional advice after a thorough examination of the particular situation or circumstances, by following these instructions you also understand that any kind of naming convention or label is used as an example only and owner of this information will not be responsible of any data lose or whatsoever.
