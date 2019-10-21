#!/bin/bash
if [ $(hostname) = "zabbix.server" ]; then
rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm
yum clean all 
    yum install -y postgresql-server postgresql-contrib zabbix-server-pgsql zabbix-web-pgsql zabbix-agent zabbix-get zabbix-sender
    # configure PostgreSQL
    postgresql-setup initdb
    sudo systemctl start postgresql
    #sudo -u postgres createuser zabbix
    sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD 'zabbix'";
    sudo -u postgres createdb -O zabbix zabbix
    zcat /usr/share/doc/zabbix-server-pgsql*/create.sql.gz | sudo -u zabbix psql zabbix
    cat > /var/lib/pgsql/data/pg_hba.conf  <<HBA
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    zabbix          zabbix          127.0.0.1/32            password
local   all             all                                     peer
host    all             all             ::1/128                 md5
HBA
    # configure Zabbix
    sudo sed -i "s|^DBName=zabbix|DBName=zabbix|; /^# DBPassword=/a \\\\nDBPassword=zabbix" /etc/zabbix/zabbix_server.conf
    sudo sed -i "s|#DBHost=localhost|DBHost=127.0.0.1|" /etc/zabbix/zabbix_server.conf
    sudo sed -i "s|# php_value date.timezone Europe/Riga|php_value date.timezone Europe/Minsk|" /etc/httpd/conf.d/zabbix.conf
cat << EOF > /etc/httpd/conf.d/zabbix.conf
#
# Zabbix monitoring system php web frontend
#
#Alias /zabbix /usr/share/zabbix
<VirtualHost *:80>
DocumentRoot /usr/share/zabbix
ServerName 192.168.56.101
</VirtualHost>
<Directory "/usr/share/zabbix">
    Options FollowSymLinks
    AllowOverride None
    Require all granted

    <IfModule mod_php5.c>
        php_value max_execution_time 300
        php_value memory_limit 128M
        php_value post_max_size 16M
        php_value upload_max_filesize 2M
        php_value max_input_time 300
        php_value max_input_vars 10000
        php_value always_populate_raw_post_data -1
        php_value date.timezone Europe/Minsk
    </IfModule>
</Directory>

<Directory "/usr/share/zabbix/conf">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/app">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/include">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/local">
    Require all denied
</Directory>
EOF
# enable and start services
    sudo systemctl enable zabbix-server 
    sudo systemctl start zabbix-server 
    sudo systemctl enable postgresql 
    sudo systemctl restart postgresql
    sudo systemctl enable zabbix-agent 
    sudo systemctl start zabbix-agent 
    sudo systemctl restart httpd 
else
rpm -Uvh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-2.el7.noarch.rpm
yum clean all 
yum -y install zabbix-agent zabbix-get zabbix-sender
sed -i "s/Server=127.0.0.1/Server=192.168.56.101/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=192.168.56.101/" /etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix server/Hostname=zabbix.server/" /etc/zabbix/zabbix_agentd.conf
cat <<EOF >> /etc/zabbix/zabbix_agentd.conf
SourceIP=192.168.56.101
EnableRemoteCommands=1
StartAgents=10
Timeout=30
AllowRoot=1
EOF
service zabbix-agent restart
cd /vagrant/
./z_agent.sh
fi
