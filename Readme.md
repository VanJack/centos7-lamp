![LAMP](https://github.com/VanJack/centos7-lamp/raw/master/conf/lamp.gif)

Description
===========
This repository is a copy of the https://github.com/teddysun/lamp-yum.git

---
LAMP is a powerful bash script for the installation of Apache + PHP + MySQL/MariaDB and so on. You can install Apache + PHP + MySQL/MariaDB in a smaller memory VPS by yum command, Just need to input numbers to choose what you want to install before installation. And all things will be done in a few minutes.

Supported System
===============
- CentOS-6.x
- CentOS-7.x

System requirements
===================
- Hard disk space: 2GB
- RAM: 64MB
- An internet connection is required
- Correct repository
- User: root

Supported Software
==================
- Apache-2.2 for CentOS-6.x
- Apache-2.4 for CentOS-7.x
- MySQL-5.5 MariaDB-5.5
- PHP-5.4 PHP-5.5 PHP-5.6
- PHP Module: XCache, Zend Guard Loader, ionCube Loader (PHP 5.4 only)
- phpMyAdmin

Installation
============
```bash
yum -y install wget unzip
wget --no-check-certificate -O centos7-lamp.zip https://github.com/VanJack/centos7-lamp/archive/master.zip
unzip centos7-lamp.zip
cd centos7-lamp-master
chmod +x *.sh
./lamp.sh 2>&1 | tee lamp.log
```

Upgrade
=======
```bash
yum -y update
```

phpMyAdmin Upgrade
==================
```bash
./update_phpmyadmin.sh
```

Uninstall
=========
```bash
./lamp.sh uninstall
```

Default Location
================
| Apache Location            | Path                                     |
|----------------------------|------------------------------------------|
| Web root location          | /data/www/default                        |
| Main Configuration File    | /etc/httpd/conf/httpd.conf               |

| MySQL Location             | Path                                     |
|----------------------------|------------------------------------------|
| Data Location              | /var/lib/mysql                           |
| my.cnf Configuration File  | /etc/my.cnf                              |

Process Management
==================
| Process     | Command                                                 |
|-------------|---------------------------------------------------------|
| Apache      | /etc/init.d/httpd  (start\|stop\|status\|restart)       |
| MySQL       | /etc/init.d/mysqld (start\|stop\|status\|restart)       |
| MariaDB     | /etc/init.d/mysqld (start\|stop\|status\|restart)       |

License
=======
Copyright (C) 2014 - 2021 Teddysun

Licensed under the [GPLv3](LICENSE) License.
