#!/bin/bash
cd "/home/ubuntu"
#sudo wget "http://128.130.172.215/salsa/upload/files/DaasService/IoT/solo-install.sh"
#sudo chmod +x ./solo-install.sh
#sudo ./solo-install.sh >> /tmp/salsa.artifact.log
#sudo wget "http://128.130.172.215/salsa/upload/files/DaasService/IoT/chef-mqtt_broker.tar.gz" >> /tmp/salsa.artifact.log
#sudo tar -xzf ./chef-mqtt_broker.tar.gz >> /tmp/salsa.artifact.log
#sudo echo "Untarred mqttbroker " >> /tmp/salsa.artifact.log
#sudo chef-solo -c ./chef-mqtt_broker/solo.rb >> /tmp/salsa.artifact.log

sudo apt-get install openjdk-7-jre-headless -y
sudo wget "http://www.apache.org/dyn/closer.cgi?filename=/activemq/5.14.0/apache-activemq-5.14.0-bin.tar.gz&action=download" -O apache-activemq-5.14.0-bin.tar.gz
sudo tar -xvzf apache-activemq-5.14.0-bin.tar.gz
sudo  ln -sf ./apache-activemq-5.14.0/bin/activemq /etc/init.d

sudo ./apache-activemq-5.14.0/bin/activemq setup /etc/default/activemq

sudo ./apache-activemq-5.14.0/bin/activemq start
