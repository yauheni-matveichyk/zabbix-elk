#!/usr/bin/bash
sudo yum install -y java-1.8.0-openjdk.x86_64
sudo yum install -y java-1.8.0-openjdk-devel
sudo mkdir -p /opt/tomcat
cd /tmp
sudo groupadd tomcat
sudo useradd -M -s /bin/nologin -g tomcat -d /opt/tomcat tomcat
wget http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-8/v8.5.47/bin/apache-tomcat-8.5.47.tar.gz
tar -zxvf apache-tomcat-8.5.47.tar.gz
cp -r /tmp/apache-tomcat-8.5.47/* /opt/tomcat/
sudo chown -R tomcat:tomcat /opt/tomcat*
sudo chmod -R g+x /opt/tomcat/conf/*
cat << EOF > /etc/systemd/system/tomcat.service
        sudo echo '
        [Unit]
        Description=Apache Tomcat Web Application Container
        After=syslog.target network.target
        [Service]
        Type=forking
        Environment=JAVA_HOME=/usr/lib/jvm/jre
        Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
        Environment=CATALINA_HOME=/opt/tomcat
        Environment=CATALINA_BASE=/opt/tomcat
        ExecStart=/opt/tomcat/bin/startup.sh
        ExecStop=/bin/kill -15 $MAINPID
        User=tomcat
        Group=tomcat
        [Install]
        WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat
mkdir -p /opt/tomcat/conf/Catalina/localhost/
    echo '
    <Context privileged="true" antiResourceLocking="false"
            docBase="${catalina.home}/webapps/manager">
        <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />
    </Context>
    ' > /opt/tomcat/conf/Catalina/localhost/manager.xml 

    rm -rf /opt/tomcat/conf/tomcat-users.xml 
    echo '
    <?xml version="1.0" encoding="UTF-8"?>
    <tomcat-users xmlns="http://tomcat.apache.org/xml"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
                version="1.0">
    <role rolename="manager-gui"/>
    <user username="tomcat" password="password" roles="manager-gui"/>
    <role rolename="admin-gui"/>
    <user username="tomcat" password="password" roles="manager-gui,admin-gui"/>
    </tomcat-users>
    ' > /opt/tomcat/conf/tomcat-users.xml 
systemctl restart tomcat
cd /opt/tomcat/webapps/
wget https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war
sleep 10
sudo systemctl restart tomcat
chmod -R 755 /opt/tomcat/
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
echo "
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
" > /etc/yum.repos.d/logstash.repo
sudo yum install -y logstash
sudo systemctl start logstash.service

sudo tee /etc/logstash/conf.d/tomcat.conf <<EOF
input {
  file {
    path => "/opt/tomcat/logs/catalina.*.log"
    start_position => "beginning"
  }
}

output {
  elasticsearch {
    hosts => ["192.168.56.101:9200"]
  }
  stdout { codec => rubydebug }
}
EOF
sudo systemctl restart logstash.service