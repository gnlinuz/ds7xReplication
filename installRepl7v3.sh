#!/bin/bash

# Use this script to create 2 DS 7 servers in replication and initialize
#
# Created on 30/01/2021
# Author = G.Nikolaidis
# Version 1.03
#
# Before execuete the script make sure you have installed Java version 11 or later
# the unzip utility, netstat 
# and include the DS-7.0.0.zip in the same directory where you execute the script




# Settings
# you can change the below settings to meet your installation requirments 
#
destPath=/opt/ds702Replication
hostName1=rep1.example.com
hostName2=rep2.example.com
serverId1=MASTER100
serverId2=MASTER200
installationProfile=ds-evaluation
generateUsers=100

installationZipFile=DS-7.0.2.zip
installationPassword=Password1

ldapPort1=2389
ldapsPort1=2636
adminPort1=5444
replPort1=8989
replPort2=8990
ldapPort2=3389
ldapsPort2=3636
adminPort2=6444



# Default paths better not change these
#
setupPath1=${destPath}1/opendj
setupPath2=${destPath}2/opendj
binPath1=$setupPath1/bin/
binPath2=$setupPath2/bin/
startDS1=$binPath1./start-ds
startDS2=$binPath2./start-ds


setupCommand1="$setupPath1/./setup --ldapPort $ldapPort1 --adminConnectorPort $adminPort1 --rootUserDN "uid=admin" --rootUserPassword $installationPassword --monitorUserPassword $installationPassword --deploymentKeyPassword $installationPassword --deploymentKey $deploymentKey --enableStartTLS --ldapsPort $ldapsPort1 --hostName $hostName1 --serverId $serverId1 --replicationPort $replPort1 --bootstrapReplicationServer $hostName1:$replPort1 --bootstrapReplicationServer $hostName2:$replPort2 --profile $installationProfile --set ds-evaluation/generatedUsers:$generateUsers --acceptLicense"

setupCommand2="$setupPath2/./setup --ldapPort $ldapPort2 --adminConnectorPort $adminPort2 --rootUserDN "uid=admin" --rootUserPassword $installationPassword --monitorUserPassword $installationPassword --deploymentKeyPassword $installationPassword --deploymentKey $deploymentKey --enableStartTLS --ldapsPort $ldapsPort2 --hostName $hostName2 --serverId $serverId2 --replicationPort $replPort2 --bootstrapReplicationServer $hostName1:$replPort1 --bootstrapReplicationServer $hostName2:$replPort2 --profile $installationProfile --set ds-evaluation/generatedUsers:$generateUsers --acceptLicense"


initReplication="$binPath1./dsrepl initialize --baseDN dc=example,dc=com --toServer $serverId2 --hostname $hostName1 --port $adminPort1 --bindDN "uid=admin" --bindPassword $installationPassword --trustAll --no-prompt"

tput civis

# Functions
#
progressBar()
{
sleepTime=$1
while ps |grep $! &>/dev/null; do
        printf '▇'
	#printf '\u2589'
        sleep ${sleepTime}
done
printf "\n"
}



unzipMessage()
{
if [ $? -eq 0 ];then
        printf "extraction successful..Done\n"
else
        printf "something went wrong while extracting the file!\n"
        printf "check your file might be corrupted, re download it.\n"
        printf "Installation failed!"
        exit -1
fi
}


setupMessage()
{
if [ $? -eq 0 ];then
        printf "setup DS successful..Done\n"
else
        printf "something went wrong while setup!\n"
        printf "Installation failed!"
        exit -1
fi
}



initialiseRepMessage()
{
if [ $? -eq 0 ];then
        printf "initialise replication successful..Done\n"
else
        printf "something went wrong while initialise replication!\n"
        printf "Installation failed!"
        exit -1
fi
printf "\n"
}




# Start
#
clear 
printf "Installing (2) DS7 Replication Servers.....\n"
printf "\n"


# check for Java environment
#
printf "Checking for Java environment..\n"
#printf "Java version: "; java -version 2>&1 |grep "version" | awk '{print $3}'
javaVer=`java -version 2>&1 | head -1 | cut -d'"' -f2 | sed '/^1\./s///' | cut -d'.' -f1`

if [ $javaVer -lt 11 ];then
	printf "You need to install Java version 11\n"
	printf "Execute sudo yum install java-11-openjdk\n"
	printf "Installation failed!\n"
	exit -1
else
	jdkVersion=`java -version 2>&1 |grep "version" | awk '{print $3}'`
	printf "compatible Java version $jdkVersion..Done\n"
fi





# Check if ports exists and LISTEN
#
netstat -V &>/dev/null

if [ $? -eq 0 ];then
	printf "netstat utility found..Done\n"
else
	printf "netstat utility not found, please use sudo yum/apt install net-tools\n"
	printf "installation aborted!\n"
        exit -1
fi

printf "Checking for ports...\n"

listeningPorts=($ldapPort1 $adminPort1 $ldapsPort1 $replPort1 $replPort2 $ldapPort2 $adminPort2 $ldapsPort2)
for p in "${listeningPorts[@]}"
do
#	result=`netstat -tulpn |grep -w $p| awk {'print $4'} |cut -c4-`
	result=`netstat -tulpn |grep -o -m 1 $p`
	if [ "$result" == "$p" ];then
		printf "Port $p exists and there will be conflict!\n"
		printf "installation aborted!\n"
		exit -1
	else
		printf "Checking port: $p ..Done\n"
	fi
done





# Check for directories
#
for dir in {1..2}
do
	if [ -d $destPath${dir} ];then
		echo; printf "Directory already exists, please delete or rename it\n"
		printf "Installation abort!\n"
		exit -1
	else 
		printf "Creating directory $destPath${dir}...\n"
		mkdir $destPath${dir}
		if [ $? -eq 0 ];then
        		printf "Created successful..Done\n"
		else
			printf "Can not create directory $destPath${dir} check the directory permissions!\n"
			printf "Installation failed!\n"
        		exit -1
		fi
	fi
done




# Check if unzip utility exists
#
echo
printf "Checking for unzip utility...\n"
unzipVer=`unzip -v 2>&1`
if [ $? -eq 0 ];then
	printf "uzip util..Done\n"
else
	printf "Unzip utility is not installed, you need to install it\n"
	printf "Execute sudo yum install unzip\n"
	printf "Installation failed!\n"
	exit -1
fi




# Check if DS-7.0.0.zip file exist on the directory
#
printf "Checking for zip file..\n"
if [ -f "$installationZipFile" ];then
	printf "found,$installationZipFile..ok\n"
else
	printf "Can't find $installationZipFile file, please make sure to include\n"
	printf "the file on the same directory where you execute the script\n"
	printf "Installation failed!\n"
        exit -1
fi





# Unzip files to directories
#
printf "Unzipping files to directories...\n"
for dir in {1..2}
do
        unzip $installationZipFile -d $destPath${dir} 2>&1 >/dev/null &
	progressBar 0
	unzipMessage
done




# Create deployment key
#
printf "creating DEPLOYMENT_KEY...please wait it might take some time..\n"
export installationPassword
$binPath1./dskeymgr create-deployment-key --deploymentKeyPassword $installationPassword > $setupPath1/DEPLOYMENT_KEY
if [ $? -eq 0 ];then
	printf "creation successful..Done\n"
else
	printf "something went wrong creating the DEPLOYMENT_KEY!\n" 
	printf "Installation failed!\n"
        exit -1
fi
deploymentKey=$(cat $setupPath1/DEPLOYMENT_KEY |awk '{ print $1 }')
export deploymentKey
printf "DEPLOYMENT_KEY: $deploymentKey\n"





# Insert the 2 hostNames into /etc/hosts file
#
cp /etc/hosts /etc/hosts.backup
if [ $? -eq 0 ];then
	printf "backup /etc/hosts hosts.backup..Done\n"
else
	printf "backup /etc/hosts file hosts.backup..failed!\n"
	printf "must run as root\n"
	printf "installation..failed!\n"
	exit -1
fi
cat /etc/hosts |grep "$hostName1"
if [ $? -eq 0 ];then
        printf "hostNames already exist on /etc/hosts..Done"
else
	sed -i "/127.0.0.1/ s/$/ $hostName1 $hostName2/" /etc/hosts
	printf "insert hostNames into /etc/hosts..Done\n"
fi





# Create INSTALLATION text
#
printf "Installation instructions..\n\n\n$setupCommand1\n\n\n$setupCommand2\n\n\n$initReplication\n\n\nDEPLOYMENT_KEY:$deploymentKey\nPassword: $installationPassword\n" > $setupPath1/INSTALLATION 
printf "create $setupPath1/INSTALLATION file..done\n"






# Execute DS setup
#
printf "executing DS ./setup command...\n"

$setupPath1/./setup --ldapPort $ldapPort1 --adminConnectorPort $adminPort1 --rootUserDN "uid=admin" --rootUserPassword $installationPassword --monitorUserPassword $installationPassword --deploymentKeyPassword $installationPassword --deploymentKey $deploymentKey --enableStartTLS --ldapsPort $ldapsPort1 --hostName $hostName1 --serverId $serverId1 --replicationPort $replPort1 --bootstrapReplicationServer $hostName1:$replPort1 --bootstrapReplicationServer $hostName2:$replPort2 --profile $installationProfile --set ds-evaluation/generatedUsers:$generateUsers --acceptLicense 2>&1 >/dev/null &

progressBar 2
setupMessage


$setupPath2/./setup --ldapPort $ldapPort2 --adminConnectorPort $adminPort2 --rootUserDN "uid=admin" --rootUserPassword $installationPassword --monitorUserPassword $installationPassword --deploymentKeyPassword $installationPassword --deploymentKey $deploymentKey --enableStartTLS --ldapsPort $ldapsPort2 --hostName $hostName2 --serverId $serverId2 --replicationPort $replPort2 --bootstrapReplicationServer $hostName1:$replPort1 --bootstrapReplicationServer $hostName2:$replPort2 --profile $installationProfile --set ds-evaluation/generatedUsers:$generateUsers --acceptLicense 2>&1 >/dev/null &

progressBar 2
setupMessage


# starting DS servers
#
$startDS1
printf "Server1 started..Done\n\n\n"
$startDS2
printf "Server2 started..Done\n\n\n"





# Initialise replication
#
printf "starting replication initialisation please wait..\n"
sleep 10
$binPath1./dsrepl initialize --baseDN dc=example,dc=com --toServer $serverId2 --hostname $hostName1 --port $adminPort1 --bindDN "uid=admin" --bindPassword $installationPassword --trustAll --no-prompt
printf "Replication initialisation started..\n"



printf "installation successful..Done\n"
printf "Sagionara...\n"
tput cnorm

#END
