#!/bin/bash
#Author: Anirban
#Github: https://github.com/abbbhucho
#Last Update: 30 December 2019 

echo '                                                                                          '
echo '       _                               _   ______                   _____      _             '  
echo '      | |                             | | |  ____|                 / ____|    | |            '  
echo '      | |     __ _ _ __ __ ___   _____| | | |__   __ _ ___ _   _  | (___   ___| |_ _   _ _ __      '
echo '      | |    / _` | \__/ _` \ \ / / _ \ | |  __| / _` / __| | | |  \___ \ / _ \ __| | | | |_ \     '
echo '      | |___| (_| | | | (_| |\ V /  __/ | | |___| (_| \__ \ |_| |  ____) |  __/ |_| |_| | |_) |    '
echo '      |______\__,_|_|  \__,_| \_/ \___|_| |______\__,_|___/\__, | |_____/ \___|\__|\__,_| .__/     '
echo '                                                            __/ |                       | |        '
echo '                                                           |___/                        |_|        ' 
echo ' '

echo ' . '

echo ''
echo ''
# Test if PHP is installed
GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${GREEN}============Test if php/hhvm is installed================ ${NC}"
echo ''
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

# Test if HHVM is installed
hhvm --version > /dev/null 2>&1
HHVM_IS_INSTALLED=$?

[[ $HHVM_IS_INSTALLED -ne 0 && $PHP_IS_INSTALLED -ne 0 ]] && { printf "!!! PHP/HHVM is not installed.\n    Installing Composer aborted!\n"; exit 0; }
if [[ $HHVM_IS_INSTALLED -ne 0 && $PHP_IS_INSTALLED -ne 0 ]]; then
	echo "PHP/HHVM is not installed"
else
	php -v || hhvm -v 	
fi
# Test if Composer is installed
echo ''
GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${GREEN}============ Checking Composer =====================${NC}"
echo ''

composer -V > /dev/null 2>&1
COMPOSER_IS_INSTALLED=$?
if [[ $COMPOSER_IS_INSTALLED -ne 0 ]]; then
    echo 'Composer is not installed'
else
    echo 'Composer is installed' && composer -V 
fi
# True, if composer is not installed
if [[ $COMPOSER_IS_INSTALLED -ne 0 ]]; then
    if [[ $HHVM_IS_INSTALLED -eq 0 ]]; then
        # Install Composer
        sudo wget --quiet https://getcomposer.org/installer
        hhvm -v ResourceLimit.SocketDefaultTimeout=30 -v Http.SlowQueryThreshold=30000 installer
        sudo mv composer.phar /usr/local/bin/composer
        sudo rm installer

        # Add an alias that will allow us to use composer without timeout's
        printf "\n# Add an alias for sudo\n%s\n# Use HHVM when using Composer\n%s" \
        "alias sudo=\"sudo \"" \
        "alias composer=\"hhvm -v ResourceLimit.SocketDefaultTimeout=30 -v Http.SlowQueryThreshold=30000 -v Eval.Jit=false /usr/local/bin/composer\"" \
        >> "/home/vagrant/.profile"

        # Resource .profile
        # Doesn't seem to work do! The alias is only usefull from the moment you log in: vagrant ssh
        . /home/vagrant/.profile
    else
		#install composer
		echo ''
		GREEN='\033[0;32m'
		echo -e "${GREEN}>>> Downloading and Verifying Composer ${NC}"
		echo ''
		echo " ====	Checking wget ==== "
		echo ''
		if [ ! -x /usr/bin/wget ]; then
			#some extra check if wget is not installed at the usual place
			command -v wget >/dev/null 2>&1 || { echo >&2 "Please install wget or set in your path. Aborting."; exit 1; }
		fi
		echo " ==== Checking Command line PHP ===="
		echo ''
		echo '>>> is the php-cli set '
		php check_cli.php
		echo ''
		php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
		echo ''
		echo ">>> Verfiying Composer setup data integrity "
		echo ''
		HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
		php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer Verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
		echo ''
		GREEN='\033[0;32m'
		echo -e "${GREEN}>>> Installing Composer${NC}"
		echo ''
		sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
		rm composer-setup.php
	fi
else
	GREEN='\033[0;32m'
    echo -e "${GREEN}>>> Updating Composer ${NC}"

    if [[ $HHVM_IS_INSTALLED -eq 0 ]]; then
        sudo hhvm -v ResourceLimit.SocketDefaultTimeout=30 -v Http.SlowQueryThreshold=30000 -v Eval.Jit=false /usr/local/bin/composer self-update
    else
        composer self-update
    fi
fi
# After successful installation of composer
composer -V
echo ''
GREEN='\033[0;32m'
echo -e "${GREEN}>>> Checking for apache/nginx server ${NC}"
echo ''
# Test if Apache or Nginx is installed
nginx -v > /dev/null 2>&1
NGINX_IS_INSTALLED=$?

apache2 -v > /dev/null 2>&1
APACHE_IS_INSTALLED=$?
if [[ $APACHE_IS_INSTALLED -eq 0 ]]; then
	if ! pidof apache2 > /dev/null
	then
		echo  "Apache web server  is down, Trying auto-restart"

		# web server down, restart the server
		sudo /etc/init.d/apache2 restart > /dev/null
		sleep 10

		#checking if apache restarted or not
		if pidof apache2 > /dev/null
		then
			echo "Apache restarted successfully"
		else
			echo "Restart Failed, try restarting manually"
		fi
	else
		echo "Apache web server is running"	
	fi
else																																																																																																																																																																																																																																																																																																
	if [ -e /var/run/nginx.pid ]; then echo "nginx is running";
	else	echo 'nginx is not running or installed! Please use command "service nginx start" to start the server or "sudo apt install nginx" to install it' & exit 0; 

	fi
fi	
#----------------------------------------------------------------------------------------------------------------------------------
echo ''
GREEN='\033[0;32m'
echo -e "${GREEN}>>> Installing Laravel$ ${NC}"
echo ''
echo 'Enter the name of the Laravel project'
read project

# Test if Vagrant is installed
vagrant --version > /dev/null 2>&1
VAGRANT_IS_INSTALLED=$?

if [[ $VAGRANT_IS_INSTALLED -eq 0 ]]; then
    echo 'Vagrant is installed, checking for laravel VagrantBox'
	# Test if Server IP is set in Vagrantfile
	echo 'Do you want to continue with Laravel vagrant box? y or n'
	read con
	if [ $con == 'y' ]; then
		[[ -z "$1" ]] && { printf "!!! IP address not set. Check the Vagrantfile.\n    Installing Laravel aborted!\n"; exit 0; }
	fi
fi
# Test if Laravel Homestead is installed
homestead --version > /dev/null 2>&1
HOMESTEAD_IS_INSTALLED=$?
# Check if Laravel root is set. If not set use default
if [[ $HOMESTEAD_IS_INSTALLED -eq 0 ]]; then
	echo 'Laravel/Homestead is installed successfully'
    laravel_root_folder="/vagrant/laravel"
else
    laravel_root_folder="$project"
fi
echo "laravel root folder : $PWD/$laravel_root_folder"
echo ''
laravel_public_folder="$laravel_root_folder/public"
echo ''
while true; do
read -p 'Do you want to make laravel project in apache /var/www/html directory(press y or n and then [ENTER])? ' yn
case $yn in 
	[Yy]* ) 
		function dir(){
			cd ~
			DIR="/var/www/html"
			cd $DIR
			cd $PWD
			if [ -d "$DIR" ]; then
				# Take action if $DIR exists. #
				echo "Installing config files in ${DIR}..."
				while true; do
				read -p "Do you have any particular version of laravel in mind(eg: 5.8.*)?" yn
				case $yn in
					[Yy]* ) echo -n "Provide the version"
							read; 
							RED='\033[1;31m'
							NC='\033[0m'
							echo -e "${RED} Please wait while laravel is set up ...${NC}"
							composer create-project laravel/laravel="${REPLY}" $laravel_root_folder
							echo ''
							echo '>>> Setting up file permissions ...'
							echo ''
							sudo chgrp -R www-data $DIR/$laravel_root_folder
							sudo chmod -R 775 $DIR/$laravel_root_folder/storage
							break;;
					[Nn]* ) 
							RED='\033[1;31m'
							NC='\033[0m'
							echo -e "${RED} Please wait while laravel is set up ... ${NC}" 
							composer create-project --prefer-dist laravel/laravel $laravel_root_folder
							echo ''
							echo '>>> Setting up file permissions ...'
							echo ''
							sudo chgrp -R www-data $DIR/$laravel_root_folder
							sudo chmod -R 775 $DIR/$laravel_root_folder/storage
							
								exit 0;;
						* ) echo "Please answer yes or no.";;
				esac
				done	
			else echo "The directory doesn't exist" && break;	
			fi
		}
		dir 
		exit;;
		
	[Nn]* )		break;;		
	* ) echo "Please answer yes or no.";;
    esac
done
# Create Laravel

	while true; do
    read -p "Do you have any particular version of laravel in mind(eg: 5.8.*)?" yn
    case $yn in
        [Yy]* ) echo -n "Provide the version"
				read; 
				RED='\033[1;31m'
				NC='\033[0m'
				echo -e "${RED} Please wait while laravel is set up ... ${NC}"
				composer create-project laravel/laravel="${REPLY}" $laravel_root_folder
				break;;
        [Nn]* ) 
				RED='\033[1;31m'
				NC='\033[0m'
				echo -e "${RED} Please wait while laravel is set up ... ${NC}"
				composer create-project --prefer-dist laravel/laravel $laravel_root_folder
				exit 0;;
        * ) echo "Please answer yes or no.";;
    esac
done
# end
