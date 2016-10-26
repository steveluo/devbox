#!/usr/bin/env bash

# Variables

USER="vagrant"
noroot() {
    sudo -EH -u "$USER" "$@";
}

network_detection() {
  # Network Detection
  #
  # Make an HTTP request to baidu.com to determine if outside access is available
  # to us. If 3 attempts with a timeout of 5 seconds are not successful, then we'll
  # skip a few things further in provisioning rather than create a bunch of errors.
  if [[ "$(wget --tries=3 --timeout=5 --spider http://baidu.com 2>&1 | grep 'connected')" ]]; then
    echo "Network connection detected..."
    ping_result="Connected"
  else
    echo "Network connection not detected. Unable to reach baidu.com..."
    ping_result="Not Connected"
  fi
}

network_check() {
  network_detection
  if [[ ! "$ping_result" == "Connected" ]]; then
    echo -e "\nNo network connection available, skipping package installation"
    exit 0
  fi
}

fix_grub_pc() {
  echo "set grub-pc/install_devices /dev/sda" | debconf-communicate
}

update_apt() {
  echo "Updating apt sources ..."
  cp -f /srv/config/apt/sources.list /etc/apt/sources.list

  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C

  if [[ ! $( apt-key list | grep 'Nginx' ) ]]; then
    echo "Applying Nginx signing key..."
    wget --quiet "http://nginx.org/keys/nginx_signing.key" -O- | apt-key add -
  fi

  apt-get -y update
  apt-get -y upgrade
}

install_essentials() {
  echo -e "\n Install essential development tools ..."
  # some development tools
  apt-get -y install build-essential g++ python python-pygments python-pip
  apt-get -y install libssl-dev gettext imagemagick ngrep
}

install_tools() {
  echo -e "\n Install some useful tools ..."
  apt-get -y install dselect htop vim wget curl zip unzip zsh tmux colordiff silversearcher-ag
  apt-get -y install ntp
}

install_git() {
  echo -e "\nInstall git ..."
  # add git ppa repository so we can get latest git
  echo "Adding ppa:git-core/ppa repository"
  sudo add-apt-repository -y ppa:git-core/ppa &>/dev/null
  apt-get -y update
  apt-get -y install git-core
  apt-get -y install git-extras
  pip install legit
  # legit install
}

DBPASSWD=root

install_mysql() {
  echo -e "\nInstall mysql database ..."
  debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBPASSWD"
  debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBPASSWD"

  apt-get install -y mysql-server


  cp "/srv/config/mysql/my.cnf" "/etc/mysql/my.cnf"
  cp "/srv/config/mysql/root-my.cnf" "/home/$USER/.my.cnf"

  if [[ -f "/srv/database/init.sql" ]]; then
    echo -e "\nImport MySQL init sql..."
    mysql -uroot -p$DBPASSWD < "/srv/database/init.sql"
  fi
  # debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
  # debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD"
  # debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD"
  # debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD"
  # debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"
  #
  # apt-get install -y phpmyadmin
}

install_postfix() {
  echo -e "\nInstall postfix mail server ..."
  echo postfix postfix/main_mailer_type select Internet Site | debconf-set-selections
  echo postfix postfix/mailname string devbox | debconf-set-selections

  # Disable ipv6 as some ISPs/mail servers have problems with it
  echo "inet_protocols = ipv4" >> "/etc/postfix/main.cf"
}

install_jdk() {
  echo -e "\nInstall JDK8 ..."
  debconf-set-selections <<< "oracle-java-installer shared/accepted-oracle-license-v1-1 select true"
  # echo oracle-java-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
  apt-get install -y --force-yes oracle-java8-installer
  update-java-alternatives -s java-8-oracle
}

install_maven() {
  echo -e "\nInstall Maven ..."
  mkdir -p /opt/java/maven
  cd /opt/java/maven
  wget --quiet "http://apache.mirrors.pair.com/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz"
  tar -zxvf apache-maven-3.3.9-bin.tar.gz
  ln -sf /opt/java/maven/apache-maven-3.3.9 /opt/java/maven/current
  rm -f apache-maven-3.3.9-bin.tar.gz
}

install_ant() {
  echo -e "\nInstall Ant ..."
  mkdir -p /opt/java/ant
  cd /opt/java/ant
  wget --quiet "http://mirrors.sonic.net/apache//ant/binaries/apache-ant-1.9.7-bin.tar.gz"
  tar -zxvf apache-ant-1.9.7-bin.tar.gz
  ln -sf /opt/java/ant/apache-ant-1.9.7 /opt/java/ant/current
  rm -f apache-ant-1.9.7-bin.tar.gz
}

install_nginx() {
  apt-get install nginx
}

# install_php() {
#   apt-get -y install php7.0-fpm php7.0-cli php7.0-common php7.0-dev
#   apt-get -y install php-imagick php-memcache php-pear
#   apt-get -y install php7.0-bcmath php7.0-curl php7.0-gd php7.0-mbstring php7.0-mcrypt
#   apt-get -y install php7.0-mysql php7.0-imap php7.0-json php7.0-soap php7.0-ssh2 php7.0-xml php7.0-zip
#
#   phpenmod mcrypt
#   phpenmod mbstring
# }

install_fasd() {
  git clone ://github.com/clvv/fasd.git /home/$USER/fasd
  cd /home/$USER/fasd
  make install
  cd
  rm -rf /home/$USER/fasd
}

NVM_DIR="/opt/nvm"

install_nvm() {
  if [[ ! -d "$NVM_DIR" ]]; then
    echo -e "\nDownloading nvm ..."
    git clone https://github.com/creationix/nvm.git /opt/nvm
    cd "$NVM_DIR"
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" origin`
  else
    echo -e "\nUpdating nvm ..."
    cd $NVM_DIR
    git pull origin master
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" origin`
  fi

  source $NVM_DIR/nvm.sh

  echo -e "\nInstalling gulp bower"
  nvm install 6 # node 6
  nvm use default
  npm install -g gulp bower grunt yo

  # https://github.com/so-fancy/diff-so-fancy
  npm install -g diff-so-fancy
}

setup_dotfiles() {
  echo -e "\nUpdating user dot files ..."

  git clone "git://github.com/steveluo/ubuntu-dotfiles.git" /home/$USER/.dotfiles
  chown -R $USER:$USER /home/$USER/.dotfiles
  noroot sh /home/$USER/.dotfiles/symlink-setup.sh

  # Install vim plugins
  # noroot vim -u ~/.dotfiles/vimrc.install +PlugInstall +qa

  noroot cat /srv/keys/vagrant.pub >> ~/.ssh/authorized_keys
  chsh -s /usr/bin/zsh $USER
}

install_gnome() {
  echo -e "\nInstall Gnome ..."
  apt-get -y install ubuntu-gnome-desktop
  apt-get -y install virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11

  # apt-get -y purge libreoffice*
  # apt-get -y purge aisleriot gnome-sudoku mahjongg ace-of-penguins gnomine gbrainy
  # apt-get -y purge gnome-chess gnome-mines cheese
  # apt-get -y autoremove
}

install_developer_tools() {
  add-apt-repository -y ppa:ubuntu-desktop/ubuntu-make
  apt-get -y update

  apt-get -y install ubuntu-make
  apt-get -y install mysql-workbench

  # install Chromium Browser
  apt-get -y install chromium-browser

  #install Guake
  apt-get install -y guake
  cp /usr/share/applications/guake.desktop /etc/xdg/autostart/

  # install gvim
  apt-get -y install vim-gtk

  #install IDEA community edition
  su -c 'umake ide idea /home/$USER/.local/share/umake/ide/idea' $USER

  # increase Inotify limit (see
  # https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit)
  echo "fs.inotify.max_user_watches = 524288" > /etc/sysctl.d/60-inotify.conf
  sysctl -p --system
}

update_environment() {
  echo 'LANG=en_US.UTF-8' >> /etc/environment
  echo 'LANGUAGE=en_US.UTF-8' >> /etc/environment
  echo 'LC_ALL=en_US.UTF-8' >> /etc/environment
  echo 'LC_CTYPE=en_US.UTF-8' >> /etc/environment
}

cleanup() {
  echo "Cleaning up ..."
  apt-get -y autoclean
  apt-get -y clean
  apt-get -y autoremove
  dd if=/dev/zero of=/EMPTY bs=1M > /dev/null 2>&1
  rm -f /EMPTY
  rm -f `echo $HISTFILE`
}


install_mailcatcher() {
  echo -e "\nInstall Mailcatcher ..."
  apt-get install -y software-properties-common libsqlite3-dev
  gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
  curl --silent -L "https://get.rvm.io" | sudo bash -s stable --ruby
  source "/usr/local/rvm/scripts/rvm"

  /usr/local/rvm/bin/rvm default@mailcatcher --create do gem install mailcatcher --no-rdoc --no-ri
  /usr/local/rvm/bin/rvm wrapper default@mailcatcher --no-prefix mailcatcher catchmail

  cp "/srv/config/mailcatcher/mailcatcher.conf" "/etc/init/mailcatcher.conf"
}

### SCRIPT

network_check
fix_grub_pc
update_apt

install_essentials
install_tools
install_git
install_mysql
install_postfix
install_mailcatcher
install_jdk
install_maven
install_ant
install_nvm

install_gnome
install_developer_tools

install_fasd
setup_dotfiles
update_environment

# install_developer_tools

cleanup

