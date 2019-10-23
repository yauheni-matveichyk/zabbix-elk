#!/usr/bin/bash

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
echo "
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
" > /etc/yum.repos.d/kibana.repo
sudo yum install -y kibana 
sudo systemctl daemon-reload
sudo systemctl enable kibana.service
sudo systemctl start kibana.service
echo "
[elasticsearch-7.x]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
" > /etc/yum.repos.d/elasticsearch.repo
sudo yum install -y elasticsearch 
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
cat << EOF > /etc/elasticsearch/elasticsearch.yml
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 192.168.56.101 
transport.host: localhost
EOF
sudo systemctl restart elasticsearch.service
cat << EOF > /etc/kibana/kibana.yml 
server.port: 5601
server.host: "192.168.56.101"
elasticsearch.hosts: ["http://192.168.56.101:9200"]
server.ssl.enabled: false
EOF
sudo systemctl restart kibana.service
