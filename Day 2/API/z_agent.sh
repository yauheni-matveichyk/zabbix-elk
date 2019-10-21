#!/bin/bash

HOSTNAME='zagent'
SERVER='192.168.56.101'
IP='192.168.56.102'
API='http://192.168.56.101/api_jsonrpc.php'
HOSTGROUPNAME='CloudHosts'
TEMPNAME='Template1'
ZABBIX_USER='Admin'
ZABBIX_PASS='zabbix'

authenticate() {
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"params\": {\"password\": \"$ZABBIX_PASS\", \"user\": \"$ZABBIX_USER\"}, \"jsonrpc\":\"2.0\", \"method\": \"user.login\",\"id\": 1}" $API 
}
token=$(authenticate) 
AUTH_TOKEN=$(echo $token | cut -d'"' -f 8)
echo $token
create_host_group(){
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\",\"method\":\"hostgroup.create\",\"params\":{\"name\": \"$HOSTGROUPNAME\"},\"auth\":\"$AUTH_TOKEN\",\"id\":0}" $API 
}
create_host_group > /dev/null

get_host_group_id() {
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\",\"method\":\"hostgroup.get\",\"params\":{\"output\": \"extend\",\"filter\":{\"name\":[\"$HOSTGROUPNAME\"]}},\"auth\":\"$AUTH_TOKEN\",\"id\":0}" $API 
}
hostgrpid=$(get_host_group_id)
HOSTGROUPID=$(echo $hostgrpid | cut -d'"' -f 10)

create_custom_template(){
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\",\"method\":\"template.create\",\"params\":{\"host\": \"$TEMPNAME\", \"groups\":{\"groupid\":\"$HOSTGROUPID\"}},\"auth\":\"$AUTH_TOKEN\",\"id\":0}" $API 
}
tempid=$(create_custom_template)
TEMP_ID=$(echo $tempid | cut -d '"' -f 10)

create_host(){
    curl -i -X POST -H 'Content-Type: application/json-rpc' -d "{\"jsonrpc\":\"2.0\",\"method\":\"host.create\",\"params\":{\"host\": \"$HOSTNAME\", \"interfaces\":[{\"type\":1,\"main\":1,\"useip\":1,\"ip\":\"$IP\",\"dns\":\"\",\"port\":\"10050\"}],\"groups\":[{\"groupid\":\"$HOSTGROUPID\"}],\"templates\":[{\"templateid\":\"$TEMP_ID\"}]},\"auth\":\"$AUTH_TOKEN\",\"id\":1}" $API 
}
hostid=$(create_host) >> /dev/null
