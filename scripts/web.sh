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

create_test_page() {
#create test php page
    cat > /var/www/html/info.php 
    <?php
        phpinfo();
    ?>
    EOF


    #create test php-mysql page
    cat > /var/www/html/mysql.php 
    <?php
    \$conn = mysql_connect('$masterIP', 'root', '$mysqlPassword');
        if (!\$conn) {
            die('Could not connect:' . mysql_error());
        }
        echo 'Connected to MySQL sucessfully!';
        if(mysql_query("create database testdb")){
            echo "    Created database testdb successfully!";
        }else{
            echo "    Database testdb already exists!";
        }
        \$db_selected = mysql_select_db('testdb',\$conn);
        if(mysql_query("create table test01(name varchar(10))")){
            echo "    Created table test01 successfuly!";
        }else{
            echo "    Table test01 already exists!";
        }
        if(mysql_query("insert into test01 values ('$insertValue')")){
            echo "    Inserted value $insertValue into test01 successfully!";
        }else{
            echo "    Inserted value $insertValue into test01 failed!";
        }
        \$result = mysql_query("select * from testdb.test01");
        while(\$row = mysql_fetch_array(\$result))
        {
        echo "    Welcome ";
        echo \$row["name"];
        echo "!!!";
        }
        mysql_close(\$conn)
    ?>
    EOF
}

install_ap
disk_format
create_test_page