#!/bin/bash

#Date: 10/09/2024
#Author: Matthias Soh
#Purpose: To combine previously written scripts together into a seamless and working whole, to fulfull Network Research Project requirements.
#For more detailed information on the script, refer to the documentation.

#Set remote server IP and credentials for testing purposes
RSERVER_IP=''
RSERVER_LOGIN=''
RSERVER_PWD=''

#Color codes for *asthetics*
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m'

#--------------------------------------
#FUNCTION DEFINITIONS

#Function Name: remoteCommands()
#Function Purpose: Simultaneously log into the remote server and send the requested commands
#Function Author: Matthias
remoteCommands()
{
	echo -e "\n[~] Logging into remote server, running WHOIS and NMAP on target IP."
	echo -n "[*] Server uptime: " 
	
	#Logs into remote server using SSH pass, sends the appropriate commands
	sshpass -p$RSERVER_PWD ssh -o StrictHostKeyChecking=no $RSERVER_LOGIN@$RSERVER_IP "uptime && whois $targetIP > whois_$targetIP.txt && nmap -Pn $targetIP > nmap_$targetIP.txt"
	
	echo "[~] Transferring files to local server"
	#Transfers the respective files to local server, while adding an appropriate entry to the log file
	#Section for transfering the WHOIS lookup
	wget -qc ftp://$RSERVER_LOGIN:$RSERVER_PWD@$RSERVER_IP/whois_$targetIP.txt
	echo "`TZ='Asia/Singapore' date` WHOIS Lookup for $targetIP saved to whois_$targetIP.txt" >> data.log
	echo -e "\n[*] WHOIS lookup for $targetIP saved to whois_$targetIP.txt."	
	
	#Section for transfering the WHOIS lookup
	wget -qc ftp://$RSERVER_LOGIN:$RSERVER_PWD@$RSERVER_IP/nmap_$targetIP.txt
	echo "`TZ='Asia/Singapore' date` NMAP Lookup for $targetIP saved to nmap_$targetIP.txt" >> data.log
	echo -e "\n[*] NMAP lookup for $targetIP saved to nmap_$targetIP.txt."
	
}

#Function Name: nipeStateCheck()
#Function Purpose: Checks that the NIPE service is running properly. Terminates the script if NIPE isn't running, prints spoofed ID if it is.
#Function Author: Matthias
nipeStatCheck()
{
	if [[ $nipeStatus != "true" ]]
	then
		#Restarts NIPE once, otherwise there's a risk of an infinite loop of service failures
		perl nipe.pl restart
		nipeStatus=$(perl nipe.pl status | grep 'Status:' | awk '{printf $3}')
		
		if [[ $nipeStatus == "true" ]]
		then
			nipeLocation
		else
			echo "[!] Nipe service non-functional, terminating script."
			exit
		fi
	else
		nipeLocation
	fi
}
#Function Name: nipeLocation()
#Function Purpose: Passes the spoofed IP to GEOIPLOOKUP, and displays both IP and location of the spoofed IP
#Function Author: Matthias
nipeLocation()
{	
	nipeIP=$(perl nipe.pl status | grep 'Ip' | awk '{printf $3}')
	nipeGeo=$(geoiplookup $nipeIP | awk '{printf $(NF-0)}')
	echo "[+] Nipe status functioning properly. User is annonymous."
	echo "[*] Spoofed IP address is $nipeIP and spoofed location is $nipeGeo."
}
#Function Name: nipeInstall()
#Function Purpose: Runs all commands required to install NIPE. Commands taken from https://www.notion.so/cfcapac/Network-Research-2b7d934d5c9c4c8aaa8c0ffce18e7b49#22725bcfa16f449ab147182bf7eea0e4
#Function Author: Matthias
nipeInstall()
{
	#Clones entire installation directory and moves it to the nipe folder
	git clone https://github.com/htrgouvea/nipe && cd nipe
	#Install code and library dependencies
	cpanm --installdeps . --y
	#Installs more dependencies [Unclear what this does]
	cpan install Config::Simple --y
	#Installs Nipe
	perl nipe.pl install
}

#END OF FUNCTION DEF
#--------------------------------------------

#--------------------------------------------
#START OF SCRIPT MAIN BODY
#--------------------------------------------

#Checks if the script is running in SUDO. As NIPE won't run in sudo, nor will the installation commands, running in SUDO is mandatory, so no point running the script without it.
if [ "$EUID" -ne 0 ]
then
	echo "Script must be run as root."
	exit
fi

#Force a list update in order to prevent errors during installation
echo "Starting script. Updated lists and locate database..."
apt-get -qq update
#Forces a db update, as the later variable relies on locate to properly find the nipe folder
updatedb
#Stores the location of the starting directory, for use later
startDir=$(pwd)
#Finds and stores the location of the NIPE directory, if it is installed. 
nipeDir=$(dirname $(locate nipe.pl))

#Checks if the listed package is installed, and sends the status to the variable
isInstalled=$(apt-cache policy geoip-bin | grep 'Installed' | awk '{printf $2}')

if [ "$isInstalled" == "(none)" ]
then
	#Runs the installation package if not installed. '2>/dev/null' was added to prevent the output from installation to keep output tidy. Doesn't truly work.
	echo -e "[-] ${PURPLE}GeoIP${NC} ${RED}not installed${NC}. Installing now."
	apt-get -qq install geoip-bin 2>/dev/null
	echo ''
else
	echo -e "[+] ${PURPLE}GeoIP${NC} already ${GREEN}installed${NC}. Skipping installation."
fi

#Same as above declaration
isInstalled=$(apt-cache policy tor | grep 'Installed' | awk '{printf $2}')

if [ "$isInstalled" == "(none)" ]
then
	echo -e "[-] ${PURPLE}TOR${NC} ${RED}not installed${NC}. Installing now."
	apt-get -qq install tor 2>/dev/null
	echo ''
else
	echo -e "[+] ${PURPLE}TOR${NC} already ${GREEN}installed${NC}. Skipping installation."
fi

#Same as above declaration
isInstalled=$(apt-cache policy sshpass | grep 'Installed' | awk '{printf $2}')

if [ "$isInstalled" == "(none)" ]
then
	echo -e "[-] ${PURPLE}SSHPASS${NC} ${RED}not installed${NC}. Installing now."
	apt-get -qq install sshpass 2>/dev/null
	echo ''
else
	echo -e "[+] ${PURPLE}SSHPASS${NC} already ${GREEN}installed${NC}. Skipping installation."
fi

#Because we previously searched for NIPE's directory, we call it now to check if it is installed
#If it is installed, the variable would not be empty
if [[ -z "$nipeDir" ]]
then
	echo -e "[-] ${PURPLE}Nipe${NC} ${RED}not installed${NC}. Installing now."
	nipeInstall
else
	echo -e "[+] ${PURPLE}Nipe${NC} is ${GREEN}installed${NC}. Checking status."
	echo -e '\n--------------------------------------------------------------\n'
	#Because it is installed, the script changes directory to NIPE's directory, as NIPE can only run it its install directory
	cd $nipeDir
fi

#Starts the service.
perl nipe.pl start
#Checks the status and stores the status in the variable
nipeStatus=$(perl nipe.pl status | grep 'Status:' | awk '{printf $3}')
nipeStatCheck

#Changes back to the original directory the script ran in. In theory this is only needed if NIPE is already installed, in order
#to prevent the script from running inside of the NIPE directory.
echo -e '\n--------------------------------------------------------------\n'
cd "$startDir"

#Prompt user to enter an IP/domain to scan
read -p "[!] Please enter an IP address or a domain name to scan: " targetIP

#Calls the Remote Commands function
remoteCommands
