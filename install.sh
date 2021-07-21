#!/bin/bash

cd /install

if [[ -f checkpoint0 ]]
then
	echo "skipping..."
else
	# Check if root
	if [ "$EUID" -ne 0 ]
		then echo "Please run as root"
		exit
	fi
	
	mkdir /install
	cd /install
	
	# Upgrade System
	apt update -qq
	apt upgrade -qq -y

	# Install necessary packages
	apt install software-properties-common nginx git dirmngr gnupg nodejs libncurses5-dev libgmp-dev libssl-dev -qq -y
	
	# Get PGP Keys and install more software (See https://www.phusionpassenger.com/docs/advanced_guides/install_and_upgrade/nginx/install/oss/focal.html)
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
	apt-get install -y apt-transport-https ca-certificates

	# Create dedicated user
	adduser new-tool --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password

	# Add repository for Ruby Version Manager and Passenger(see https://github.com/rvm/ubuntu_rvm)
	apt-add-repository -y ppa:rael-gc/rvm
	sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger focal main > /etc/apt/sources.list.d/passenger.list'
	apt update
	apt install rvm libnginx-mod-http-passenger -y --quiet

	# Add user to rvm group
	usermod -a -G rvm new-tool
	usermod -aG rvm $SUDO_USER
	
	cd /var/www/
	git clone https://github.com/edbingo/new-tool
	
	chown new-tool:new-tool -R new-tool/
	chown $SUDO_USER:$SUDO_USER -R /install
	
	if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]
	then
		ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf ;
	fi
	ls /etc/nginx/conf.d/mod-http-passenger.conf
	cd /etc/nginx/sites-enabled/
	mv default default.bak
	wget https://raw.githubusercontent.com/edbingo/install/main/athene.bks-campus.ch
	cp athene.bks-campus.ch /etc/nginx/sites-available/
	systemctl restart nginx
	
	# Set checkpoint and reboot
	cd /install
	touch checkpoint0
	reboot
	exit
fi

if [ "$EUID" -ne 0 ]
then
	echo "proceeding..."
else
	echo "Root is no longer needed"
	exit
fi

cd /install

if [[ -f checkpoint1 ]]
then
	echo "Please Wait"
else
	source /usr/share/rvm/scripts/rvm
	cd /install
	rvm install ruby-2.6.0
	rvm use --default ruby-2.6.0
	touch checkpoint1
	echo "Please run this script again as newly created user new-tool (sudo su new-tool)"
	exit
fi

cd /install

if [ "$EUID" -ne 1001 ]
then
	echo "Please run as user new-tool (sudo su new-tool)"
	exit
else
	source /usr/share/rvm/scripts/rvm
	rvm install ruby-2.6.0
	cd /var/www/new-tool
	bundle install --deployment --without development test
	bundle exec rake assets:precompile db:migrate db:seed RAILS_ENV=production
	echo "Install complete?"
fi
	

