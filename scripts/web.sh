#/bin/bash


mysqlPassword=$1
insertValue=$2
masterIP=10.0.0.20

	
install_ap() {


	#install apache 2.4 php5
	yum install httpd php php-mysql -y


	#start httpd
	service httpd start

	#auto-start 
	chkconfig httpd on
	chkconfig firewalld off
	chkconfig iptables off
	service firewalld stop
	service iptables stop

	#set selinux
	sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux
	sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
	setenforce 0

}


disk_format() {
	cd /tmp
	yum install wget -y
	for ((j=1;j<=3;j++))
	do
		wget https://raw.githubusercontent.com/sethbilly/azure-wordpress-mysql-cluster/master/shared_scripts/vm-disk-utils.sh   
		if [[ -f /tmp/vm-disk-utils.sh ]]; then
			bash /tmp/vm-disk-utils.sh -b /var/www/html -s
			if [[ $? -eq 0 ]]; then
				sed -i 's/disk1//' /etc/fstab
				umount /var/www/html/disk1
				mount /dev/md0 /var/www/html
			fi
			break
		else
			echo "download vm-disk-utils.sh failed. try again."
			continue
		fi
	done
		
}

install_ap
disk_format