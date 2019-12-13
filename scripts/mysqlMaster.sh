#/bin/bash


mysqlPassword=$1

install_mysql() {

	#get repo
	yum install wget -y
	for((i=1;i<=5;i++))
	do
		wget http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm
		if [[ $? -ne 0 ]];then
			if [[ $i == 5 ]];then
				echo "tried 5 times to download repo but failed. exit. try again later."
				exit 1
			fi
			continue
		else
			echo "download repo successfully"
			break
		fi
	done
	yum localinstall -y mysql-community-release-el6-5.noarch.rpm

	#install mysql 5.6
	for((i=1;i<=5;i++))
	do
		yum install -y mysql-community-server
		if [[ $? -ne 0 ]];then
			if [[ $i == 5 ]];then
				echo "tried 5 times to install mysql server but failed. exit. try again later."
				exit 10
			fi
			yum clean all
			continue
		else
			echo "installed mysql server successfully."
			break
		fi
	done

	#configure my.cnf
	sed -i '/\[mysqld\]/a server-id = 1\nlog_bin = /var/lib/mysql/mysql-bin.log' /etc/my.cnf
	
	#auto-start
	chkconfig mysqld on
	

}


disk_format() {
	cd /tmp
	yum install wget -y
	for ((j=1;j<=3;j++))
	do
		wget https://raw.githubusercontent.com/sethbilly/azure-wordpress-mysql-cluster/master/shared_scripts/vm-disk-utils.sh  
		if [[ -f /tmp/vm-disk-utils-0.1.sh ]]; then
			bash /tmp/vm-disk-utils-0.1.sh -b /var/lib/mysql -s
			if [[ $? -eq 0 ]]; then
				sed -i 's/disk1//' /etc/fstab
				umount /var/lib/mysql/disk1
				mount /dev/md0 /var/lib/mysql
				chown -R mysql:mysql /var/lib/mysql
			fi
			break
		else
			echo "download vm-disk-utils-0.1.sh failed. try again."
			continue
		fi
	done
		
}

start_mysql() {
	#start mysql
	service mysqld start

	#set mysql root password
	mysqladmin -uroot password "$mysqlPassword" 2> /dev/null

	#grant privileges
	mysql -uroot -p$mysqlPassword -e "grant replication slave on *.* to 'repluser'@'%' identified by 'replpass';grant all privileges on *.* to 'root'@'%' identified by '$mysqlPassword';flush privileges;"
}
