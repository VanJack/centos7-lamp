#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#==========================================================================#
#   System Required:  CentOS 6+                                            #
#   Description:  Yum Install LAMP(Linux + Apache + MySQL/MariaDB + PHP )  #
#   Original Project by Teddysun:                                          #
#           https://teddysun.com/lamp-yum                                  #
#           https://github.com/teddysun/lamp-yum                           #
#   Modified by: Vanjack                                                   #
#   Github: https://github.com/VanJack/centos7-lamp                        #
#==========================================================================#
clear
HORAINICIAL=$(date +%T)
LOG="/var/log/$(echo $0 | cut -d'/' -f2)"
# Current folder
cur_dir=`pwd` &>> $LOG

# Make sure only root can run our script
rootness(){
if [[ $EUID -ne 0 ]]; then
   echo "Error:This script must be run as root!" 1>&2
   exit 1
fi
}

# Disable selinux
# Its will be reactivated at the end of the process
disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then &>> $LOG
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config &>> $LOG
    setenforce 0 &>> $LOG
fi
}

# Get public IP
get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 ) &>> $LOG
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com ) &>> $LOG
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip ) &>> $LOG
    [ ! -z ${IP} ] && echo ${IP} || echo &>> $LOG
}

get_char(){
    SAVEDSTTY=`stty -g` &>> $LOG
    stty -echo &>> $LOG
    stty cbreak &>> $LOG
    dd if=/dev/tty bs=1 count=1 2> /dev/null &>> $LOG
    stty -raw &>> $LOG
    stty echo &>> $LOG
    stty $SAVEDSTTY &>> $LOG
}
#===========================================Pre-installation settings===========================================
pre_installation_settings(){
    echo
    echo "#############################################################"
    echo "# LAMP Auto yum Install Script for CentOS                   #"
    echo "# Intro: https://teddysun.com/lamp-yum                      #"
    echo "# Author: Teddysun <i@teddysun.com>                         #"
    echo "# Modified by: Vanjack                                      #"                    
    echo "# Github: https://github.com/VanJack/centos7-lamp           #"
    echo "#############################################################"
    echo
    echo
    echo "Installing repositories..."
	#YUM UTILS
	yum install yum-utils &>> $LOG
    # Install Epel repository
    rpm -qa | grep "epel-release" &>/dev/null &>> $LOG
    if [ $? -ne 0 ]; then
        yum -y install epel-release | bash &>> $LOG
        rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm | bash &>> $LOG
    fi
	# Install REMI repository
	rpm -qa | grep "remi-release" &>/dev/null &>> $LOG
    if [ $? -ne 0 ]; then
        rpm -Uvh https://rpms.remirepo.net/enterprise/remi-release-7.rpm | bash &>> $LOG
    fi
	# Install SCLs repository
	rpm -qa | grep "scl-release" &>/dev/null &>> $LOG
    if [ $? -ne 0 ]; then
	yum -y install centos-release-scl	| bash &>> $LOG
	fi
	# Install IUS repository
	rpm -qa | grep "ius-release" &>/dev/null &>> $LOG
    if [ $? -ne 0 ]; then
	yum -y install https://repo.ius.io/ius-release-el7.rpm 	| bash &>> $LOG
	yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm	| bash &>> $LOG
	yum-config-manager --enable ius-testing &>> $LOG
	fi
	#
    echo "Getting Public IP address..."
    echo -e "Your main public IP is\t\033[32m$(get_ip)\033[0m"
    echo
    # Choose databese
    while true
    do
    echo "Please choose a version of the Database:"
    echo -e "\t\033[32m1\033[0m. Install MySQL-5.5"
	echo -e "\t\033[32m2\033[0m. Install MySQL-8.0(recommend)"
    echo -e "\t\033[32m3\033[0m. Install MariaDB-5.5"
    read -p "Please input a number:(Default 1) " DB_version
    [ -z "$DB_version" ] && DB_version=1
    case $DB_version in
        1|2|3)
        echo
        echo "---------------------------"
        echo "You choose = $DB_version"
        echo "---------------------------"
        echo
        break
        ;;
        *)
        echo "Input error! Please only input number 1,2 or 3!"
    esac
    done
    # Set MySQL root password
    echo "Please input the root password of MySQL or MariaDB:"
    read -p "(Default password: root):" dbrootpwd
    if [ -z $dbrootpwd ]; then
        dbrootpwd="root"
    fi
    echo
    echo "---------------------------"
    echo "Password = $dbrootpwd"
    echo "---------------------------"
    echo
    # Choose PHP version
    while true
    do
    echo "Please choose a version of the PHP:"
    echo -e "\t\033[32m1\033[0m. Install PHP-5.4"
    echo -e "\t\033[32m2\033[0m. Install PHP-5.5"
    echo -e "\t\033[32m3\033[0m. Install PHP-5.6"
    echo -e "\t\033[32m4\033[0m. Install PHP-7.4"
	echo -e "\t\033[32m5\033[0m. Install PHP-8.0"
    read -p "Please input a number:(Default 1) " PHP_version
    [ -z "$PHP_version" ] && PHP_version=1
    case $PHP_version in
        1|2|3|4|5)
        echo
        echo "---------------------------"
        echo "You choose = $PHP_version"
        echo "---------------------------"
        echo
        break
        ;;
        *)
        echo "Input error! Please only input number 1,2,3,4 or 5"
    esac
    done

    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    # Remove Packages
    yum -y remove httpd*        &>> $LOG
    yum -y remove mysql*        &>> $LOG
    yum -y remove mariadb*      &>> $LOG
    yum -y remove php*          &>> $LOG
    yum -y remove phpmyadmin*   &>> $LOG

    # Set timezone
    rm -f /etc/localtime  &>> $LOG
    ln -s /usr/share/zoneinfo/America/Bahia /etc/localtime &>> $LOG
    yum -y install ntp &>> $LOG
    ntpdate -d cn.pool.ntp.org &>> $LOG
    ntpdate -v time.nist.gov &>> $LOG
    /sbin/hwclock -w &>> $LOG
}

# Install Apache
install_apache(){
    # Install Apache
    echo "Start Installing Apache..."
    yum -y install httpd &>> $LOG
    cp -f $cur_dir/conf/httpd.conf /etc/httpd/conf/httpd.conf &>> $LOG
    rm -fv /etc/httpd/conf.d/welcome.conf /data/www/error/noindex.html &>> $LOG
    chkconfig httpd on &>> $LOG
    mkdir -p /data/www/default &>> $LOG
    chown -R apache:apache /data/www/default &>> $LOG
    touch /etc/httpd/conf.d/none.conf &>> $LOG
    cp -f $cur_dir/conf/index.html /data/www/default/ &>> $LOG
    cp -f $cur_dir/conf/index_cn.html /data/www/default/ &>> $LOG
    cp -f $cur_dir/conf/lamp.gif /data/www/default/ &>> $LOG
    cp -f $cur_dir/conf/p.php /data/www/default/ &>> $LOG
    cp -f $cur_dir/conf/p_cn.php /data/www/default/ &>> $LOG
    cp -f $cur_dir/conf/jquery.js /data/www/default/ &>> $LOG
    cp -f $cur_dir/conf/phpinfo.php /data/www/default/ &>> $LOG
    echo "Apache Install completed!"
}

# Install database
install_database(){
    if [ $DB_version -eq 1 ]; then
        install_mysql55
	elif [ $DB_version -eq 2 ]; then
        install_mysql80
    elif [ $DB_version -eq 3 ]; then
        install_mariadb
    fi
}
#===========================================DATABASES_VERSIONS===========================================
install_mysql55(){
    #----------------------Install MySQL55----------------------
    echo "Start Installing MySQL 5.5..."
    yum install http://repo.mysql.com/yum/mysql-5.5-community/el/7/x86_64/mysql-community-release-el7-5.noarch.rpm &>> $LOG
    yum -y install mysql mysql-server &>> $LOG
    rpm -qa | grep -i mysql-community &>> $LOG
    cp -f $cur_dir/conf/my.cnf /etc/my.cnf &>> $LOG
    chkconfig mysqld on &>> $LOG
    # Resume mysqld service
    systemctl start mysqld &>> $LOG
    systemctl enable mysqld &>> $LOG
    /usr/bin/mysqladmin password $dbrootpwd &>> $LOG
    /usr/bin/mysql -uroot -p$dbrootpwd <<EOF &>> $LOG
    drop database if exists test;
    delete from mysql.user where user='';
    update mysql.user set password=password('$dbrootpwd') where user='root';
    delete from mysql.user where not (user='root') ;
    flush privileges;
    exit
EOF
    systemctl restart mysqld &>> $LOG
    echo "MySQL Install completed!"
}
#
install_mysql80(){
    #----------------------Install MySQL80----------------------
    echo "Start Installing MySQL 8.0clear..."
    yum -y install http://repo.mysql.com/yum/mysql-8.0-community/el/8/x86_64/mysql80-community-release-el8-1.noarch.rpm &>> $LOG
    yum -y install mysql mysql-server &>> $LOG
    cp -f $cur_dir/conf/my.cnf /etc/my.cnf &>> $LOG
    chkconfig mysqld on &>> $LOG
    # Start mysqld service
    systemctl start mysqld &>> $LOG
    systemctl enable mysqld &>> $LOG
    /usr/bin/mysqladmin password $dbrootpwd &>> $LOG
    /usr/bin/mysql -uroot -p$dbrootpwd <<EOF &>> $LOG
    drop database if exists test;
    delete from mysql.user where user='';
    update mysql.user set password=password('$dbrootpwd') where user='root';
    delete from mysql.user where not (user='root') ;
    flush privileges;
    exit
EOF
    systemctl restart mysqld &>> $LOG
    echo "MySQL Install completed!"
}
#
install_mariadb(){
    #----------------------Install MariaDB----------------------
    echo "Start Installing MariaDB..."
    yum -y install mariadb mariadb-server &>> $LOG
    cp -f $cur_dir/conf/my.cnf /etc/my.cnf &>> $LOG
    chkconfig mariadb on &>> $LOG
    # Start mysqld service
    systemctl start maridb &>> $LOG
    systemctl enable mariadb &>> $LOG
    /usr/bin/mysqladmin password $dbrootpwd &>> $LOG
    /usr/bin/mysql -uroot -p$dbrootpwd <<EOF &>> $LOG
    drop database if exists test;
    delete from mysql.user where user='';
    update mysql.user set password=password('$dbrootpwd') where user='root';
    delete from mysql.user where not (user='root') ;
    flush privileges;
    exit
EOF
    systemctl restart mariadb &>> $LOG
    echo "MariaDB Install completed!"
}
#===========================================Install_PHP_VERSIONS===========================================
install_php(){
    echo "Start Installing PHP..."
    yum -y install libjpeg-devel libpng-devel
    if [ $PHP_version -eq 1 ]; then
        yum-config-manager --disable 'remi-php*' &>> $LOG
        yum-config-manager --enable   remi-php54 &>> $LOG
        yum -y update &>> $LOG
        yum -y install php54-php-{bcmath,bz2,cli,common,curl,fpm,devel,domxml,gd,gettext,imap,intl,json,jpeg,ldap \
        mbstring,mcrypt,mhash,mysqlnd,openssl,pear,pdo,xml,xmlrpc,zip} &>> $LOG
    fi
    if [ $PHP_version -eq 2 ]; then
	#PHP 55
        yum-config-manager --disable 'remi-php*' &>> $LOG
        yum-config-manager --enable   remi-php55 &>> $LOG
        yum -y update &>> $LOG
        yum -y install php55-php-{bcmath,bz2,cli,common,curl,fpm,devel,domxml,gd,gettext,imap,intl,json,jpeg,ldap \
        mbstring,mcrypt,mhash,mysqlnd,openssl,pear,pdo,xml,xmlrpc,zip} &>> $LOG
    fi
    if [ $PHP_version -eq 3 ]; then
	#PHP 56
        yum-config-manager --disable 'remi-php*' &>> $LOG
        yum-config-manager --enable   remi-php56 &>> $LOG
        yum -y update
        yum -y install php56-php-{bcmath,bz2,cli,common,curl,fpm,devel,domxml,gd,gettext,imap,intl,json,jpeg,ldap \
        mbstring,mcrypt,mhash,mysqlnd,openssl,pear,pdo,xml,xmlrpc,zip} &>> $LOG
    fi
    if [ $PHP_version -eq 4 ]; then
	#PHP 74
        yum-config-manager --disable 'remi-php*' &>> $LOG
        yum-config-manager --enable  remi-php74 &>> $LOG
        yum -y update &>> $LOG
        yum -y install php74-php-{bcmath,bz2,cli,common,curl,fpm,devel,domxml,gd,gettext,imap,intl,json,jpeg,ldap \
        mbstring,mcrypt,mhash,mysqlnd,openssl,pear,pdo,xml,xmlrpc,zip} &>> $LOG
    fi
    if [ $PHP_version -eq 5 ]; then
	#PHP 80
        yum-config-manager --disable 'remi-php*' &>> $LOG
        yum-config-manager --enable   remi-php80 &>> $LOG
        yum -y update &>> $LOG
        yum -y install php80-php-{bcmath,bz2,cli,common,curl,fpm,devel,domxml,gd,gettext,imap,intl,json,jpeg,ldap \
        mbstring,mcrypt,mhash,mysqlnd,openssl,pear,pdo,xml,xmlrpc,zip} &>> $LOG
    fi
    cp -f $cur_dir/conf/php.ini /etc/php.ini &>> $LOG
    echo "PHP install completed!"
}

#===========================================INSTALL_phpMyAdmin===========================================
install_phpmyadmin(){
    if [ ! -d /data/www/default/phpmyadmin ];then
        echo "Start Installing phpMyAdmin..."
        LATEST_PMA=$(wget --no-check-certificate -qO- https://www.phpmyadmin.net/files/ | awk -F\> '/\/files\//{print $3}' | cut -d'<' -f1 | sort -V | tail -1)
        if [[ -z $LATEST_PMA ]]; then
            LATEST_PMA=$(wget -qO- http://dl.lamp.sh/pmalist.txt | tail -1 | awk -F- '{print $2}') &>> $LOG
        fi
        echo -e "Installing phpmyadmin version: \033[41;37m $LATEST_PMA \033[0m"
        cd $cur_dir &>> $LOG
        if [ -s phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz ]; then
            echo "phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz [found]"
        else
            wget -c http://files.phpmyadmin.net/phpMyAdmin/${LATEST_PMA}/phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz &>> $LOG
            tar zxf phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz &>> $LOG
        fi
        mv phpMyAdmin-${LATEST_PMA}-all-languages /data/www/default/phpmyadmin &>> $LOG
        cp -f $cur_dir/conf/config.inc.php /data/www/default/phpmyadmin/config.inc.php &>> $LOG
        #Create phpmyadmin database
        /usr/bin/mysql -uroot -p$dbrootpwd < /data/www/default/phpmyadmin/sql/create_tables.sql &>> $LOG
        mkdir -p /data/www/default/phpmyadmin/upload/ &>> $LOG
        mkdir -p /data/www/default/phpmyadmin/save/ &>> $LOG
        cp -f /data/www/default/phpmyadmin/sql/create_tables.sql /data/www/default/phpmyadmin/upload/ &>> $LOG
        chown -R apache:apache /data/www/default/phpmyadmin &>> $LOG
        rm -f phpMyAdmin-${LATEST_PMA}-all-languages.tar.gz &>> $LOG
        echo "PHPMyAdmin Install completed!"
    else
        echo "PHPMyAdmin had been installed!"
    fi
    #Start httpd service
    systemctl start httpd &>> $LOG
}

#===========================================Uninstall_LAMP===========================================
uninstall_lamp(){
    echo "Warning! All of your data will be deleted..."
    echo "Are you sure uninstall LAMP? (y/n)"
    read -p "(Default: n):" uninstall &>> $LOG
    if [ -z $uninstall ]; then
        uninstall="n" &>> $LOG
    fi
    if [[ "$uninstall" = "y" || "$uninstall" = "Y" ]]; then
        clear
        echo "==========================="
        echo "Yes, I agreed to uninstall!"
        echo "==========================="
        echo
    else
        echo
        echo "============================"
        echo "You cancelled the uninstall!"
        echo "============================"
        exit
    fi

    echo "Press any key to start uninstall...or Press Ctrl+c to cancel"
    char=`get_char`
    echo
    if [[ "$uninstall" = "y" || "$uninstall" = "Y" ]]; then
        cd ~
        CHECK_MARIADB=$(mysql -V | grep -i 'MariaDB')
        service httpd stop &>> $LOG
        service mysqld stop &>> $LOG
        yum -y remove httpd* &>> $LOG
        if [ -z $CHECK_MARIADB ]; then
            yum -y remove mysql* &>> $LOG
        else
            yum -y remove mariadb* &>> $LOG
        fi
        if [ -s /usr/bin/atomic-php54-php ]; then
            yum -y remove atomic-php54-php* &>> $LOG
        elif [ -s /usr/bin/atomic-php55-php ]; then
            yum -y remove atomic-php55-php* &>> $LOG
        elif [ -s /usr/bin/atomic-php56-php ]; then
            yum -y remove atomic-php56-php* &>> $LOG
        elif [ -s /usr/bin/atomic_php74 ]; then
            yum -y remove atomic-php74-php* &>> $LOG
        elif [ -s /usr/bin/atomic-php80-php ]; then
            yum -y remove atomic-php80-php* &>> $LOG
        else
            yum -y remove php* &>> $LOG
        fi
        rm -rf /data/www/default/phpmyadmin &>> $LOG
        rm -rf /etc/httpd &>> $LOG
        rm -f /usr/bin/lamp &>> $LOG
        rm -f /etc/my.cnf.rpmsave &>> $LOG
        rm -f /etc/php.ini.rpmsave &>> $LOG
        echo "Successfully uninstall LAMP!!"
    else
        echo
        echo "Uninstall cancelled, nothing to do..."
        echo
    fi
}

#===========================================ADD_Apache_Virtualhost===========================================
vhost_add(){
    #Define domain name
    read -p "(Please input domains such as:www.example.com):" domains
    if [ "$domains" = "" ]; then
        echo "You need input a domain."
        exit 1
    fi
    domain=`echo $domains | awk '{print $1}'`
    if [ -f "/etc/httpd/conf.d/$domain.conf" ]; then
        echo "$domain is exist!"
        exit 1
    fi
    #Create database or not
    while true
    do
    read -p "(Do you want to create database?[y/N]):" create
    case $create in
    y|Y|YES|yes|Yes)
    read -p "(Please input the user root password of MySQL or MariaDB):" mysqlroot_passwd
    /usr/bin/mysql -uroot -p$mysqlroot_passwd <<EOF
exit
EOF
    if [ $? -eq 0 ]; then
        echo "MySQL or MariaDB root password is correct.";
    else
        echo "MySQL or MariaDB root password incorrect! Please check it and try again!"
        exit 1
    fi
    read -p "(Please input the database name):" dbname
    read -p "(Please set the password for mysql user $dbname):" mysqlpwd
    create=y
    break
    ;;
    n|N|no|NO|No)
    echo "Not create database, you entered $create"
    create=n
    break
    ;;
    *) echo Please input only y or n
    esac
    done

    #===========================================Create DATABASE===========================================
    if [ "$create" == "y" ];then
        /usr/bin/mysql -uroot -p$mysqlroot_passwd  <<EOF
    CREATE DATABASE IF NOT EXISTS \`$dbname\`;
    GRANT ALL PRIVILEGES ON \`$dbname\` . * TO '$dbname'@'localhost' IDENTIFIED BY '$mysqlpwd';
    GRANT ALL PRIVILEGES ON \`$dbname\` . * TO '$dbname'@'127.0.0.1' IDENTIFIED BY '$mysqlpwd';
    FLUSH PRIVILEGES;
EOF
    fi
    #Define website dir
    webdir="/data/www/$domain"
    DocumentRoot="$webdir/web"
    logsdir="$webdir/logs"
    mkdir -p $DocumentRoot $logsdir
    chown -R apache:apache $webdir
    #Create vhost configuration file
    cat >/etc/httpd/conf.d/$domain.conf<<EOF
    <virtualhost *:80>
    ServerName  $domain
    ServerAlias  $domains 
    DocumentRoot  $DocumentRoot
    CustomLog $logsdir/access.log combined
    DirectoryIndex index.php index.html
    <Directory $DocumentRoot>
    Options +Includes -Indexes
    AllowOverride All
    Order Deny,Allow
    Allow from All
    php_admin_value open_basedir $DocumentRoot:/tmp
    </Directory>
    </virtualhost>
EOF
    systemctl restart httpd > /dev/null 2>&1
    echo "Successfully create $domain vhost"
    echo "######################### information about your website ############################"
    echo "The DocumentRoot:$DocumentRoot"
    echo "The Logsdir:$logsdir"
    [ "$create" == "y" ] && echo "database name and user:$dbname and password:$mysqlpwd"
}

#===========================================Remove_Apache_Virtualhost===========================================
vhost_del(){
    read -p "(Please input a domain you want to delete):" vhost_domain
    if [ "$vhost_domain" = "" ]; then
        echo "You need input a domain."
        exit 1
    fi
    echo "---------------------------"
    echo "vhost account = $vhost_domain"
    echo "---------------------------"
    echo

    echo "Press any key to start delete vhost...or Press Ctrl+c to cancel"
    echo
    char=`get_char`

    if [ -f "/etc/httpd/conf.d/$vhost_domain.conf" ]; then
        rm -f /etc/httpd/conf.d/$vhost_domain.conf
        rm -rf /data/www/$vhost_domain
    else
        echo "Error:No such domain file, Please check your input domain and try again."
        exit 1
    fi

    systemctl restart httpd
    echo "Successfully delete $vhost_domain vhost"
}

#===========================================List_apache_virtualhost===========================================
vhost_list(){
    ls /etc/httpd/conf.d/ | grep -v "php.conf" | grep -v "none.conf" | grep -v "welcome.conf" | grep -iv "README" | awk -F".conf" '{print $1}'
}

#===========================================Enable_selinux===========================================
enable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=enforcing/g' /etc/selinux/config
    setenforce 0
fi
}
#===========================================Firewall_settings===========================================
security_settings(){
    yum list installed | grep "firewalld" &>/dev/null
    if [ $? -ne 0 ]; then
        yum -y install firewalld | bash
        systemctl start firewalld | bash
        systemctl enable firewalld | bash
    fi
    firewall-cmd --remove-service=dhcpv6-client --permanent
    firewall-cmd --add-service=http --permanent
    firewall-cmd --add-service=https --permanent
    firewall-cmd --add-service=mysql --permanent 
    firewall-cmd --reload
}

#===========================================Install_LAMP_Script===========================================
install_lamp(){
    rootness
    disable_selinux
    pre_installation_settings
    install_apache
    install_database
    install_php
    install_phpmyadmin
    enable_selinux
    security_settings
    cp -f $cur_dir/lamp.sh /usr/bin/lamp
    chmod +x /usr/bin/lamp
    clear
    echo
    echo 'Congratulations, Yum install LAMP completed!'
    echo "Your Default Website: http://$(get_ip)"
    echo 'Default WebSite Root Dir: /data/www/default'
    echo "MySQL root password:$dbrootpwd"
    echo
    echo "This version is a copy of the Teddsun's project."
    echo "Be a guest to visit original project on:https://teddysun.com/lamp-yum"
    echo "Enjoy it! "
    
    # script para calcular o tempo gasto (SCRIPT MELHORADO, CORRIGIDO FALHA DE HORA:MINUTO:SEGUNDOS)
    # opção do comando date: +%T (Time)
    HORAFINAL=`date +%T`
    # opção do comando date: -u (utc), -d (date), +%s (second since 1970)
    HORAINICIAL01=$(date -u -d "$HORAINICIAL" +"%s")
    HORAFINAL01=$(date -u -d "$HORAFINAL" +"%s")
    # opção do comando date: -u (utc), -d (date), 0 (string command), sec (force second), +%H (hour), %M (minute), %S (second), 
    TEMPO=`date -u -d "0 $HORAFINAL01 sec - $HORAINICIAL01 sec" +"%H:%M:%S"`
    # $0 (variável de ambiente do nome do comando)
    echo -e "Tempo gasto para execução do script $0: $TEMPO"
    echo -e "Pressione <Enter> para concluir o processo."
    # opção do comando date: + (format), %d (day), %m (month), %Y (year 1970), %H (hour 24), %M (minute 60)
    echo -e "Fim do script $0 em: `date +%d/%m/%Y-"("%H:%M")"`\n" &>> $LOG
    read
    exit 1
}

#===========================================Initialization_step===========================================
action=$1
[ -z $1 ] && action=install
case "$action" in
install)
    install_lamp
    ;;
uninstall)
    uninstall_lamp
    ;;
add)
   vhost_add
    ;;
del)
   vhost_del
    ;;
list)
   vhost_list
    ;;
*)
    echo "Usage: `basename $0` [install|uninstall|add|del|list]"
    ;;
esac
