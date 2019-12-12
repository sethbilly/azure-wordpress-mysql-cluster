#/bin/bash

webNodeCount=$1
zabbixServer=$2


	
install_haproxy() {
	cd /tmp
	yum install wget -y
		for((i=1;i<=5;i++))
		do
			wget http://www.haproxy.org/download/1.6/src/haproxy-1.6.3.tar.gz
			if [[ $? -eq 0 ]];then
				break
			else
				continue
			fi
		done
	tar zxvf haproxy-1.6.3.tar.gz
	cd haproxy-1.6.3
	yum install gcc -y
	make TARGET=linux2628 PREFIX=/usr/local/haproxy
	make install PREFIX=/usr/local/haproxy


}


disk_format() {
	cd /tmp
	mkdir /data
	yum install wget -y
	for ((j=1;j<=3;j++))
	do
		wget https://raw.githubusercontent.com/sethbilly/azure-wordpress-mysql-cluster/master/shared_scripts/vm-disk-utils.sh 
		if [[ -f /tmp/vm-disk-utils.sh ]]; then
			bash /tmp/vm-disk-utils.sh -b /data/ -s
			if [[ $? -eq 0 ]]; then
				sed -i 's/disk1//' /etc/fstab
				umount /data/disk1
				mount /dev/md0 /data
			fi
			break
		else
			echo "download vm-disk-utils.sh failed. try again."
			continue
		fi
	done
		
}

config_haproxy() {
    haproxyConfigFile="/usr/local/haproxy/haproxy.cfg"
    cat > ${haproxyConfigFile} 
    global         
        maxconn 4096           
        chroot /usr/local/haproxy
            uid 99                 
            gid 99               
        daemon                  
        pidfile /usr/local/haproxy/haproxy.pid  
    defaults             
        log    global
            log     127.0.0.1       local3        
        mode    http         
        option  httplog       
            option  dontlognull  
            option  httpclose    
        retries 3           
        option  redispatch   
        maxconn 2000                     
        timeout connect     5000           
        timeout client     50000          
        timeout server     50000          
    frontend http-in                       
        bind *:80
            mode    http 
            option  httplog
            log     global
            default_backend httppool 
        
    backend httppool                    
        balance source
    EOF


	for ((k=1;k<=$webNodeCount;k++))
	do
		let ip=3+$k
		sed -i "\$a server  web${k} 10.0.0.${ip}:80  weight 5 check inter 2000 rise 2 fall 3" ${haproxyConfigFile}
		sed -i '$s/^/       /' ${haproxyConfigFile}
	done	

	#start haproxy
	/usr/local/haproxy/sbin/haproxy -f /usr/local/haproxy/haproxy.cfg
}
