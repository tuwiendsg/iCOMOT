# This script is generated by SensorGatewayUtil.sh to run the custom sensor. The data is embbeded at the end of this file. 
# This script enables the sensor to run in a gateway, which is compatible with iCOMOT
# The settings of the sensor is:
#    Dataset = evaporator_fouling.csv
#    Maxlines = 0
#    Columns = 1,2 
#    Protocol = mqtt 
#    Frequency = 5
# This script requires sensor.tar.gz in the same folder. If not, please uncomment following line.
# wget https://github.com/tuwiendsg/iCOMOT/raw/master/examples/sensors/sensor.tar.gz

if [ ! -f ./sensor.tar.gz ]; then
	echo "Sensor artifact does not found!" | tee /tmp/sensor.err
  exit 1;
fi

# prepare sensor artifact for the iCOMOT-compatible gateway
mkdir /tmp/sensor
mv ./sensor.tar.gz /tmp/sensor
cd /tmp/sensor
tar -xvzf ./sensor.tar.gz
touch sensor.pid
chmod 777 sensor.pid
rm sensor.tar.gz

# replace the data
sed '1,/^START OF DATA/d' $0 > data.csv
mv data.csv config-files/data.csv

# configure the sensor in META-INF

sed -i 's#<bean id="producer" class="at.ac.tuwien.infosys.cloudconnectivity.dryrun.Dryrun" />#<bean id="producer" class="at.ac.tuwien.infosys.cloudconnectivity.mqtt.MQProducer" />#' config-files/META-INF/wire.xml
sed -i 's#<property name="updateRate" value=.*#<property name="updateRate" value="5"/>#' config-files/META-INF/wire.xml

# With the distributed version, sensor is not started.
# bash ./container_run_bg.sh
exit 0

START OF DATA
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 12:00:01 AM,23.41
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 12:30:01 AM,23.41
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 01:00:01 AM,23.41
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 01:30:01 AM,23.41
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 02:00:01 AM,23.41
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 02:30:01 AM,23.41
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 03:00:01 AM,23.41
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 03:30:01 AM,23.41
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 04:00:01 AM,23.41
evaporator_fouling,fcu_ff1_space_temp,Apr 1 2011 04:30:01 AM,23.41