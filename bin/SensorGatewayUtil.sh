#!/bin/bash
# This script is used for building custom simulated sensors/gateways that compatible with iCOMOT platform
# The util will generate the sensors or gateways artifacts which is ready-to-use in iCOMOT
# usage: ./SensorGatewayUtil.sh <sensor|gateway> [Options|sensorOptions|gatewayOptions]

PWD=`pwd`
TARGET="iCOMOT-simulated-devices"
PDIR=$TARGET/protected

function printCopyright() {
	echo -e "SensorGatewayUtil.sh version 0.1"
  echo -e "Copyright 2015 - Distributed Systems Group, Vienna University of Technology"
	echo -e "  "
}

function printHelp() {				
        echo -e "Usage : $0 <sensor|gateway> [Options|SensorOptions|GatewayOptions]"
        echo -e "   sensor|gateway : to create sensor artifact or gateway artifact"
				echo -e "   Options "
        echo -e "     -i|--interactive                : Run the utility in interactive mode"
        echo -e "     -r|--remote <iCOMOT-repository> : If stated, the artifact will be uploaded to iCOMOT-repository"
        echo -e "     -n|--name <sensor/gateway name> : The name of sensor or gateway"
				echo -e "     -h|--help                       : Print this message and exit"
        echo -e "   SensorOptions  "
        echo -e "     -s|--dataset <data set URI>     : The source of data set (can be URL or local file)"
        echo -e "                                       Default: searching for ./data.csv"
        echo -e "     -l|--maxlines <max lines>       : The maximum number of lines for the simulated data"
        echo -e "     -c|--columns <list of columns>  : The columns of dataset to attract. E.g: -c 1,3,4. Note: the $"
        echo -e "     -p|--protocol <sensor protocol> : Set the sensor protocol. Supported: dry, mqtt, coap, smap"
        echo -e "     -f|--frequency <frequency>      : Set the sensor frequency"
        echo -e "   GatewayOptions  "
        echo -e "     -bi|--baseImage <Dockefile URL> : The Dockerfile that configures the components of the gateway."
        echo -e "                                       Default: searching for ./Dockerfile"
        echo -e "     -ng|--noGovOps                  : Do not include rtGovOpt components"
        echo -e " "        
}

errorMsg="unknown"
function printError() {
	echo -e "\e[7mError: $errorMsg \e[0m"
	printHelp
	exit 1
}


function createSensor(){
	echo "Generating sensor code ..."
	mkdir -p $TARGET/$NAME
	mkdir -p $PDIR
	#Add README
	touch $PDIR/README
	echo "This directory is created automatically by iCOMOT. Please do not change its content manually..." > $PDIR/README
	
	echo "Gathering artifacts..."
	if [ -f ../examples/sensors/sensor.tar.gz ]; then
		cp ../examples/sensors/sensor.tar.gz $PDIR
	else 	
  	wget https://github.com/tuwiendsg/iCOMOT/raw/master/examples/sensors/sensor.tar.gz -O $PDIR/sensor.tar.gz
  fi
  if [ $DATASET == ^http://.* ]; then
  	wget $DATASET
  	if [ $? -nq 0 ]; then
  		echo "Error: Cannot get dataset at URL: $DATASET"
  		exit 2
  	fi
  elif [ -f $DATASET ]; then    
  	echo "Getting dataset at local host: $DATASET"
    cp $DATASET $TARGET/$NAME
  else
  	echo "Error: Cannot get dataset at local: $DATASET"
  	exit 2
  fi
  	
	# Generate script to run the sensor
	FILE=$TARGET/$NAME/run_sensor_$NAME.sh
	
	# Generate the wire.xml string
	PROTOCOL_CONF='at.ac.tuwien.infosys.cloudconnectivity.dryrun.Dryrun'
	FREQUENCY_CONF="<property name=\"updateRate\" value=\"$FREQUENCY\"/>"
	case $PROTOCOL in
		dry)
			PROTOCOL_CONF='at.ac.tuwien.infosys.cloudconnectivity.dryrun.Dryrun'
		  ;;
		mqtt)
		  PROTOCOL_CONF='at.ac.tuwien.infosys.cloudconnectivity.mqtt.MQProducer'
		  ;;
		coap)
		  PROTOCOL_CONF='coapClient.CoapMock'
		  ;;
		smap)
		  PROTOCOL_CONF='smapClient.SmapMock'
		  ;;
		*)		
	esac
	PROTOCOL_CONF="<bean id=\"producer\" class=\"$PROTOCOL_CONF\" />"
	
	cat > $FILE << generatedScript
# This script is generated by $0 to run the custom sensor. The data is embbeded at the end of this file. 
# The settings of the sensor is:
#    Dataset = $DATASET
#    Maxlines = $MAXLINES
#    Columns = $COLUMNS 
#    Protocol = $PROTOCOL 
#    Frequency = $FREQUENCY
# This script requires sensor.tar.gz in the same folder. If not, please uncomment following line.
# wget https://github.com/tuwiendsg/iCOMOT/raw/master/examples/sensors/sensor.tar.gz

cp ../protected/sensor.tar.gz .
tar -xvzf sensor.tar.gz
rm sensor.tar.gz	

# replace the data
sed '1,/^START OF DATA/d' \$0 > data.csv
mv data.csv config-files/data.csv

# configure the sensor in META-INF

sed -i 's#<bean id="producer" class="at.ac.tuwien.infosys.cloudconnectivity.dryrun.Dryrun" />#$PROTOCOL_CONF#' config-files/META-INF/wire.xml
sed -i 's#<property name="updateRate" value=.*#$FREQUENCY_CONF#' config-files/META-INF/wire.xml

# run the sensor
#java -cp 'bootstrap_container-0.0.1-SNAPSHOT-jar-with-dependencies.jar:*' container.Main
bash container_run.sh
exit 0

START OF DATA
generatedScript
	
	# add data to the end of the script. id is the data set, then the sensor name, afterward is the set of columns
	# add $ before each column number
  COL='$'`echo $COLUMNS | tr -d ' '`
  COL=`echo $COL | sed -e "s/,/,$/g"`
  
  # get the header
	head -1 $DATASET | awk -F',' -v OFS=',' '{print "id,name,"'$COL'}' >> $FILE
	
	# write the data
	DATASET_NAME_ONLY=`basename $DATASET | cut -d'.' -f1`
	if [ $MAXLINES -gt 0 ]; then 
		tail --lines=+2 $DATASET | head -n $MAXLINES |  awk -F',' -v OFS=',' '{print "'$DATASET_NAME_ONLY','$NAME',"'$COL'}' >> $FILE
	else 
		tail --lines=+2 $DATASET | awk -F',' -v OFS=',' '{print "'$DATASET_NAME_ONLY','$NAME',"'$COL'}' >> $FILE
	fi	

echo "The run script is generated: $FILE"
  echo "Sensor name: $NAME"
  echo "Dataset:   : $DATASET"

  RUNME="Y";
  default=$RUNME;  read -p "Should I run the sensor now? [$RUNME]: " RUNME; RUNME=${RUNME:-$default}
  if [ $RUNME == "Y" ]; then
    echo "Running the sensor ..."    
    chmod +x $FILE
    cd $TARGET/$NAME
    chmod +x ./run_sensor_$NAME.sh
    bash ./run_sensor_$NAME.sh
  else
    echo "Successfully created sensor $NAME"
    echo "You can run the sensor with ./$FILE"
  fi

  cd .. 
}

function createGateway(){
  echo "Generate gateway configuration ..."
  mkdir -p target/$NAME
	cd target/$NAME
  wget https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/gateways/Dockerfile-UB
  if [ NOGOVOPS=="false" ]; then
  	wget https://github.com/tuwiendsg/iCOMOT/raw/master/examples/gateways/rtGovOps-agents.tar.gz
  fi
  wget https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/gateways/decommission
  wget https://raw.githubusercontent.com/tuwiendsg/iCOMOT/master/examples/gateways/deploySensor.sh
  
  cd ..  
}

if [ $# -lt 1 ]; then
  errorMsg="Missing parameters..."
	printError
	exit 1
fi

if [ $1 == "sensor" ]; then
	METHOD="sensor"
elif [ $1 == "gateway" ]; then
  METHOD="gateway"
elif [ $1 == "-h" ] || [ $1 == "--help" ]; then
  printCopyright
	printHelp
	exit 0
else
  errorMsg="The first parameter is wrong, it can be either sensor or gateway"
  printError
  exit 1
fi

shift

# Get options
REMOTE="false"
REMOTE_URL=""
NAME=$METHOD
INTERACTIVE="false"

DATASET="./data.csv"
MAXLINES=0
COLUMNS=""
PROTOCOL="dry"
FREQUENCY="5"

GWBASEIMAGE="Dockerfile"
NOGOVOPS="no"


while test $# -gt 0; do
	case "$1" in		
	# general options
		-r|--remote)
			REMOTE="true"
			REMOTE_URL=$2
			shift 2
			;;
		-n|--name)
		  NAME=$2
		  shift 2
		  ;;
		-i|--interactive)
		  INTERACTIVE="true"
		  shift
		  ;;
		-d|--delete)
		  NAME=$2
		  DELETE="true"
		  shift 2
		  ;;  
		  
	# sensor options
		-s|--dataset)
		  DATASET=$2
		  shift 2
		  ;;
		-l|--maxlines)
		  MAXLINES=$2
		  shift 2
		  ;;
		-c|--columns)
		  COLUMNS=$2
		  shift 2
		  ;;
		-p|--protocol)
		  PROTOCOL=$2
		  shift 2
		  ;;		  
		-f|--frequency)
		  FREQUENCY=$2
		  shift 2
		  ;;		  
  # gateway options
		-bi|--baseImage)
			GWBASEIMAGE=$2
			shift 2
			;;
		-ng|--noGovOps)
		  NOGOVOPS="true"
		  shift
		  ;;		  		
		*)
			errorMsg="Wrong parameters"
			printError
			exit 1
    	break
      ;;
	esac
done

# interactive mode
if [ $INTERACTIVE == "true" ]; then
	echo "Interactive mode for creating $METHOD"
	read -p "Input a name for the sensor/gateway [$METHOD]: " NAME;   NAME=${NAME:-$METHOD}
	case $METHOD in
		sensor)
		  default=$DATASET;   read -p "Sensor dataset [$DATASET]: " DATASET;                                    DATASET=${DATASET:-$default}
		  while [ ! -f $DATASET ] && [ dataset != ^http://.* ]; do
		  	echo "Cannot find the dataset file: $DATASET. The dataset must be exist locally or an URL to download. Please enter another!"
			  default=$DATASET;   read -p "Dataset [$DATASET]: " DATASET;                                    DATASET=${DATASET:-$default}
		  done		  
		  
		  default=$MAXLINES;  read -p "Maximum lines to extract from the dataset (0 for all lines) [$MAXLINES]: " MAXLINES; MAXLINES=${MAXLINES:-$default}
		  default=$COLUMNS;   read -p "Columns to extract from the dataset (leave empty for all) []: " COLUMNS;         COLUMNS=${COLUMNS:-$default}
		  default=$PROTOCOL;  read -p "Sensor protocol [$PROTOCOL] (dry|mqtt|coap|smap): " PROTOCOL;              PROTOCOL=${PROTOCOL:-$default}
		  default=$FREQUENCY; read -p "Sensor frequency [$FREQUENCY]: " FREQUENCY;                                FREQUENCY=${FREQUENCY:-$default}
		  echo -e "\nCreating sensor with following settings: \n Dataset = $DATASET \n Maxlines = $MAXLINES \n Columns = $COLUMNS \n Protocol = $PROTOCOL \n Frequency = $FREQUENCY"			
			;;
		gateway)
			default=$GWBASEIMAGE; read -p "Docker file for base image [$GWBASEIMAGE]: $GWBASEIMAGE" GWBASEIMAGE; GWBASEIMAGE=${GWBASEIMAGE-default}
			PS3="Disable GovOps [$NOGOVOPS]?"
			select NOGOVOPS in yes no			
			do
				echo "Ok."
			done
			;;
		*)
		  errorMsg="Wrong method: $METHOD"
		  printError
		  exit 1
		  ;;
	esac
fi


if [ $DELETE == "true" ]; then
	rm -rf $TARGET/$NAME
	exit 0
fi


if [ $METHOD == "sensor" ]; then
  echo "Creating sensor ..."
  createSensor
elif [ $METHOD == "gateway" ]; then
  echo "Creating gateway ..."
  createGateway
fi









