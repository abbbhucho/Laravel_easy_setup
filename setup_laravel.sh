#!/bin/bash
#Author: Anirban
#Github: https://github.com/abbbhucho
#Last Update: 30 December 2019 

echo '/***                                                                                          '
echo ' *      _                               _   ______                   _____      _             '  
echo ' *     | |                             | | |  ____|                 / ____|    | |            '  
echo ' *     | |     __ _ _ __ __ ___   _____| | | |__   __ _ ___ _   _  | (___   ___| |_ _   _ _ __      '
echo ' *     | |    / _` | \__/ _` \ \ / / _ \ | |  __| / _` / __| | | |  \___ \ / _ \ __| | | | |_ \     '
echo ' *     | |___| (_| | | | (_| |\ V /  __/ | | |___| (_| \__ \ |_| |  ____) |  __/ |_| |_| | |_) |    '
echo ' *     |______\__,_|_|  \__,_| \_/ \___|_| |______\__,_|___/\__, | |_____/ \___|\__|\__,_| .__/     '
echo ' *                                                           __/ |                       | |        '
echo ' *                                                          |___/                        |_|        ' 
echo ' */'

echo ' . '

echo ''
echo ''
# Test if PHP is installed
echo '============Test if php/hhvm is installed================'
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
echo '============ Checking Composer ====================='
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
		echo ">>> Downloading and Verifying Composer"
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
		$HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
		php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer Verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
		echo ''
		echo ">>> Installing Composer"
		echo ''
		sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
	fi
else
    echo ">>> Updating Composer"

    if [[ $HHVM_IS_INSTALLED -eq 0 ]]; then
        sudo hhvm -v ResourceLimit.SocketDefaultTimeout=30 -v Http.SlowQueryThreshold=30000 -v Eval.Jit=false /usr/local/bin/composer self-update
    else
        composer self-update
    fi
fi
# After successful installation of composer
composer -V

