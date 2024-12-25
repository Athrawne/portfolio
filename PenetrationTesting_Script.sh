#!/bin/bash

#Date: 3/12/2024
#Author: Matthias Soh
#Purpose: To combine previously written scripts in a whole to fulfill Penetration Testing project requirements.

#Hard coded variables for testing purposes
#SCAN_TYPE='Z'
#TARGETIP="192.168.18.134"
#TARGETNAME="victim"
#TARGETDIR="VICTIM"

#Color codes for asthetics
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
BLUE='\033[0;36m'
LGREEN='\033[0;92m'
NC='\033[0m'

#------------------------------------------------------------------
#FUNCTION DEFINITIONS

#Function Name: basicMode()
#Function Purpose: Function called to run the scan in basic mode, i.e the requisite network scan, and the password tests.
#Function Author: Matthias
basicMode()
{
	echo -e "\n[${YELLOW}!${NC}] Running port scan on the specified target, ${YELLOW}$TARGETNAME${NC}, at ${YELLOW}$TARGETIP${NC}."
	echo "[`TZ='Asia/Singapore' date`] NMAP Scan started on $TARGETIP, alias $TARGETNAME" >> $logFILE
	echo "[`TZ='Asia/Singapore' date`] NMAP Scan flags:  -Pn --min-parallelism 100 --max-retries 1 --defeat-icmp-ratelimit -sTUV $TARGETIP -oX ./$TARGETDIR/nXML_$TARGETNAME.xml -oN ./$TARGETDIR/nmap_$TARGETNAME.txt" >> $logFILE
	#This is the scan used to map the ports on the target ip.	
	nmap -Pn --min-parallelism 100 --max-retries 1 --defeat-icmp-ratelimit -sTUV $TARGETIP -oX ./$TARGETDIR/nXML_$TARGETNAME.xml -oN ./$TARGETDIR/nmap_$TARGETNAME.txt
	echo "[`TZ='Asia/Singapore' date`] NMAP Scan finished." >> $logFILE
	
	#Stores the location of output logs.
	outXML="./$TARGETDIR/nXML_$TARGETNAME.xml"
	output="./$TARGETDIR/nmap_$TARGETNAME.txt"
	
	echo -e "[${YELLOW}!${NC}] Scan completed.\n"
	echo -e "[${YELLOW}!${NC}] Scan output saved to $output."
	echo -e "[${YELLOW}!${NC}] Scan xml output saved to $outXML.\n"
	
	passwordTest
}
#Function Name: fullMode()
#Function Purpose: Function called to run the scan in full mode. This also calls the basic mode, since it already calls the network scan, and the password tests.
#				   Full mode just also calls the function to assess vulnerabilties.
#Function Author: Matthias
fullMode()
{
	#Calls the basicMode function, as it contains the scan, and the password tests
	basicMode
	#The only thing fullMode really does is also call the function for vulnAssessment	
	vulnAssessment
}
#Function Name: passwordTest()
#Function Purpose: Function used to run brute force tests on the available ports and services, using password and user lists. A default password list is provided
#				   but the user must supply a user list. It first calls filterResults to check what services are available, and what the ports numbers are.
#Function Author: Matthias
passwordTest()
{
	#Call the function to filter the saved results to get the port numbers
	filterResults	
	
	#Because there is the chance that there are no open ports, only run the test of 
	#the total count is less than 4
	if [[ $noPorts == 4 ]];
	then
		echo -e "\n[${YELLOW}!${NC}] ${RED}No open ports found${NC}. Skipping password test.\n"
		echo "[`TZ='Asia/Singapore' date`] Password test skipped due to no available ports." >> $logFILE
	else	
		#---------PASSWORD FILE CHECKING----------#
		#This section prompts the user to specify their desired password list, and defaults to the included one if the file is invalid, or
		#nothing is chosen.
		echo -e "\n[${PURPLE}~${NC}]  Open ports for FTP, SSH or Telnet ${GREEN}found${NC}. Proceeding with password test."
		echo -e "[`TZ='Asia/Singapore' date`] Obtaining password list from user." >> $logFILE
		read -p "[?] Specify a password list to test against (leave blank for default): " PWDLST
		
		#Check if a file path has been specified
		if [ -z $PWDLST ];
		then
			#If nothing is specified set to the default password list
			echo -e "[${PURPLE}~${NC}]  Defaulting to ${GREEN}included password list${NC}."
			PWDLST="./defaults/PWD_LST.lst"
			echo -e "[`TZ='Asia/Singapore' date`] Password list set to $PWDLST." >> $logFILE
			
		#If a file path has been specified, then check if it is valid
		elif [ -r $PWDLST ];
		then
			echo -e  "[${PURPLE}~${NC}] Password list set to ${GREEN}$PWDLST${NC}"
			echo -e "[`TZ='Asia/Singapore' date`] Password list set to $PWDLST." >> $logFILE
		#Otherwise default to the default
		else
			echo -e  "[${PURPLE}~${NC}]  Specified file path is invalid. Defaulting to ${GREEN}included password list${NC}."
			PWDLST="./defaults/PWD_LST.lst"
			echo -e "[`TZ='Asia/Singapore' date`] Password list set to $PWDLST." >> $logFILE
		fi
		
		#--------USERNAME LIST CHECKING--------------#
		#This section checks that a valid, readable file path (-r) is supplied to the variable. Unlike the above section
		#a username list must be specified, because the password test uses the NSE's brute force scripts, which cannot take a single variable.
		
		#read -p "Specify to use a list or single user name: " USERIN
		
		#This section checks that the username list supplied is valid. If no valid file is supplied, then it continues to prompt
		#for a valid file until one is supplied.
		echo -e "[`TZ='Asia/Singapore' date`] Obtaining user name list from user." >> $logFILE
		read -p "[?] Specify a username list to test against: "	USERLST
		#Check if there is a specified username list
		if [ -z $USERLST ];
		then
			echo -e "[${RED}!${NC}]  A list of usernames ${RED}must${NC} be specified for this test.\n"
			echo -e "[`TZ='Asia/Singapore' date`] Invalid user name list specified Re-prompting." >> $logFILE
			
			#Enters a while loop, to ensure that the user specifies a valid, readable list of user names.		
			while :; do	
			read -p "[?] Specify a username list to test against: " USERLST
				if [ -z $USERLST ];
				then
					echo -e "[${RED}!${NC}]  A list of usernames ${RED}must${NC} be specified for this test.\n"
				echo -e "[`TZ='Asia/Singapore' date`] Invalid user name list specified Re-prompting." >> $logFILE
				#Test if the given file path is valid.
				elif [ -r $USERLST ];		
				then
					echo -e "[${PURPLE}~${NC}]  Username list set to ${GREEN}$USERLST${NC}.\n"
					echo -e "[`TZ='Asia/Singapore' date`] User name list set to $USERLST." >> $logFILE
					break
				else
				#Re-enters the while loop if the file path is invalid		
					echo -e "[${YELLOW}!${NC}] File path ${RED}invalid${NC}. Please specify a valid user name list.\n"
					echo -e "[`TZ='Asia/Singapore' date`] Invalid user name list specified Re-prompting." >> $logFILE
				fi
			done
		#Test if the given file path is valid
		elif [ -r $USERLST ];
		then
			echo -e "[${PURPLE}~${NC}]  Username list set to ${GREEN}$USERLST${NC}.\n"
			echo -e "[`TZ='Asia/Singapore' date`] User name list set to $USERLST." >> $logFILE
		#If the specified file path is not valid, then call the same while loop from above until a valid, readable file is specified	
		else
			echo -e "[${YELLOW}!${NC}] A list of usernames ${RED}must${NC} be specified for this test.\n"	
			echo -e "[`TZ='Asia/Singapore' date`] Invalid user name list specified Re-prompting." >> $logFILE	
			while :; do	
			read -p "[?] Specify a username list to test against: " USERLST
				if [ -z $USERLST ];
				then
					echo -e "[${YELLOW}!${NC}] A list of usernames ${RED}must${NC} be specified for this test.\n"
					echo -e "[`TZ='Asia/Singapore' date`] Invalid user name list specified Re-prompting." >> $logFILE
				#Test if the given file path is valid.
				elif [ -r $USERLST ];		
				then
					echo -e "[${PURPLE}~${NC}]  Username list set to ${GREEN}$USERLST${NC}.\n"
					echo -e "[`TZ='Asia/Singapore' date`] User name list set to $USERLST." >> $logFILE
					break
				else		
					echo -e "[${YELLOW}!${NC}] File path ${RED}invalid${NC}. Please specify a valid user name list.\n"
					echo -e "[`TZ='Asia/Singapore' date`] Invalid user name list specified Re-prompting." >> $logFILE
				fi
			done		
		fi	
		
		#----------ACTUAL PASSWORD CHECKING----------------#
		#Combine both the specified password file and username file into a single command line
		ARGS="passdb=$PWDLST,userdb=$USERLST"
		
		echo -e "[${PURPLE}~${NC}] ------------------- ${RED}Password Test${NC} --------------------[${PURPLE}~${NC}] "
		echo -e "[`TZ='Asia/Singapore' date`] Password list and user name list verified and set, beginning test." >> $logFILE
		
		#-----FTP Password Test-----#
		#All following tests function identically, so only comments will be present on the FTP one
		#Run through the array, testing for each of the specified ports.
		
		if [[ ${ftpPort[@]} ]];
		then
			echo -e "\n[${PURPLE}~${NC}]  Testing FTP password strength..."			
			for ports in ${ftpPort[@]};
			do
				#Calls on the NSE script to brute force the system with the previously specified args, and outputs two files, an xml and txt file
				echo "[`TZ='Asia/Singapore' date`] Testing FTP port number $ports for weak passwords ---------------" >> $logFILE
				nmap --script-args $ARGS --script=ftp-brute.nse -p $ports $TARGETIP -oN ./$TARGETDIR/FTPTEST_$ports.txt >> $logFILE
				#The name of the txt file is stored in this variable
				FTP_Out="./$TARGETDIR/FTPTEST_$ports.txt"
				
				#And then called as part of this command to filter out the user names found
				for each in $(cat $FTP_Out | grep 'Valid credentials' | awk '{printf "%s\\\n", $2}' | tr ':' ' ' | awk '{printf $2}' | tr '\\' ' ');
				do
					 echo -e "[${YELLOW}!${NC}] Username ${RED}$each${NC} has a ${RED}weak password${NC} for FTP services."
					 echo -e "[`TZ='Asia/Singapore' date`] Username $each found with weak password for FTP services." >> $logFILE
				done
			done
		else
			echo -e "[${PURPLE}~${NC}] No open FTP port found, skipping test."
			echo -e "[`TZ='Asia/Singapore' date`] Skipping FTP password test due to lack of open ports." >> $logFILE
		fi
		#-----------------------------#
		
		#------SSH Password Test------#
		if [ ${sshPort[@]} ];
		then
			echo -e "\n[${PURPLE}~${NC}]  Testing SSH password strength..."
			for ports in ${sshPort[@]};
			do
				echo "[`TZ='Asia/Singapore' date`] Testing SSH port number $ports for weak passwords ---------------" >> $logFILE
				nmap --script-args $ARGS --script=ssh-brute.nse -p $ports $TARGETIP -oN ./$TARGETDIR/SSHTEST_$ports.txt  >> $logFILE
				SSH_Out="./$TARGETDIR/SSHTEST_$ports.txt"
				
				for each in $(cat $SSH_Out | grep 'Valid credentials' | awk '{printf "%s\\\n", $2}' | tr ':' ' ' | awk '{printf $2}' | tr '\\' ' ');
				do
					echo -e "[${YELLOW}!${NC}] Username ${RED}$each${NC} has a ${RED}weak password${NC} for SSH services."
					 echo -e "[`TZ='Asia/Singapore' date`] Username $each found with weak password for SSH services." >> $logFILE
				done
				
			done
		else
			echo -e "[${PURPLE}~${NC}] No open SSH port found, skipping test."
			echo -e "[`TZ='Asia/Singapore' date`] Skipping SSH password test due to lack of open ports." >> $logFILE
		fi
		#-----------------------------#
		
		#----Telnet Password Test-----#	
		if [ ${telnetPort[@]} ];		
		then
			echo -e "\n[${PURPLE}~${NC}]  Testing Telnet password strength..."
			for ports in ${telnetPort[@]};
			do
				echo "[`TZ='Asia/Singapore' date`] Testing Telnet port number $ports for weak passwords ---------------" >> $logFILE
				nmap --script-args $ARGS --script=telnet-brute.nse -p $ports $TARGETIP -oN ./$TARGETDIR/TELNETTEST_$ports.txt  >> $logFILE
				TEL_Out="./$TARGETDIR/TELNETTEST_$ports.txt"
				
				for each in $(cat $TEL_Out | grep 'Valid credentials' | awk '{printf "%s\\\n", $2}' | tr ':' ' ' | awk '{printf $2}' | tr '\\' ' ');
				do
					echo -e "[${YELLOW}!${NC}] Username ${RED}$each${NC} has a ${RED}weak password${NC} for Telnet services."
					echo -e "[`TZ='Asia/Singapore' date`] Username $each found with weak password for Telnet services." >> $logFILE
				done
			done
		else
			echo -e "[${PURPLE}~${NC}] No open Telnet port found, skipping test."
			echo -e "[`TZ='Asia/Singapore' date`] Skipping Telnet password test due to lack of open ports." >> $logFILE
		fi
		#-----------------------------#
	fi
	
}
#Function Name: vulnAssessment()
#Function Purpose: Function used for vulnerability assessment by passing the xml file from nmap through to searchsploit.
#Function Author: Matthias
vulnAssessment()
{
	echo -e "\n[${PURPLE}~${NC}] -------------- ${RED}Vulnerability Assessment${NC} ---------------[${PURPLE}~${NC}] "
	echo -e "[${YELLOW}!${NC}] Checking ${YELLOW}$TARGETNAME${NC} for vulnerabilities ... "
	echo -e "[`TZ='Asia/Singapore' date`] Beginning vulnerability assessment, using searchsploit to check the NMAP scan xml file." >> $logFILE
	
	#----Searchsploit Vulnerability Checking----#
	#--disable-colour > This flag is used to disable the special characters used to highlight search terms
	#--nmap $outXML   > This flag is what is used to pass the XML file to searchsploit
	# 2>&1			  > This is added on to redirect ALL output to the specified file. Otherwise, it would be difficult to read the output file
	
	searchsploit --disable-colour --nmap $outXML >> ./$TARGETDIR/vulns_$TARGETNAME.txt 2>&1
	echo -e "[${YELLOW}!${NC}] Vulnerabilities logged to vulns_$TARGETNAME.txt \n" 	
	echo -e "[`TZ='Asia/Singapore' date`] Vulnerabilities logged to vulns_$TARGETNAME.txt" >> $logFILE
}
#Function Name: filterResults()
#Function Purpose: Utility function used to filter the nmap scan results for open service ports for FTP, SSH, RDP and Telnet
#Function Author: Matthias
filterResults()
{
	noPorts=0
	#Filter the scan results to filter out the respective service ports
	echo -e "[${PURPLE}~${NC}] ----------------- ${RED}Port Filtering${NC} ------------------[${PURPLE}~${NC}] "
	echo -e "[${PURPLE}~${NC}] Filtering scan results to find open service ports."
	
	#echo $output
	#----FTP Filter----#
	echo -e "\n[${YELLOW}!${NC}] Filtering for FTP ports..." 
	#All other port filters work identically so comments will only be on this filter
	#First the saved output file is grepped for the service, and filtered out to isolate the port number
	for ports in $(cat $output | grep "ftp" | grep "open" | awk '{printf $1}' | tr /tcp ' ' );
	do	
		#This number or numbers are added to the corresponding array
		ftpPort+=($ports);		
	done
	
	#If the first element of the array is empty, it means no port numbers have been found
	if [[ -z ${ftpPort[@]} ]];
	then
		#None are found so report that to the user 
		echo -e "[${PURPLE}~${NC}] No open FTP ports for ${BLUE}$TARGETNAME${NC} detected."
		echo -e "[`TZ='Asia/Singapore' date`] No open FTP ports found for $TARGETNAME." >> $logFILE
		#Increase the "no open ports" counter by one
		let "noPorts=noPorts+1"
	else
		#echo "False"
		#If there are ports found, print out each of the port numbers
		for ports in ${ftpPort[@]};
		do
			#echo "Falser"
			echo -e "[${YELLOW}!${NC}] Port $ports is ${GREEN}open${NC} for FTP services."
			echo -e "[`TZ='Asia/Singapore' date`] FTP Port $port found open for $TARGETNAME." >> $logFILE
		done
	fi
	#------------------#
	#----SSH Filter----#
	echo -e "\n[${YELLOW}!${NC}] Filtering for SSH ports..." 	
	for each in $(cat $output | grep "ssh" | grep "open" | awk '{printf $1}' | tr /tcp ' ' );
	do
		sshPort+=($each);	
	done	
	
	if [ -z ${sshPort[@]} ];
	then
		echo -e "[${PURPLE}~${NC}] No open SSH ports for ${BLUE}$TARGETNAME${NC} detected."
		echo -e "[`TZ='Asia/Singapore' date`] No open SSH ports found for $TARGETNAME." >> $logFILE
		let "noPorts=noPorts+1"
	else
		for ports in ${sshPort[@]};
		do
			echo -e "[${YELLOW}!${NC}] Port $ports is ${GREEN}open${NC} for SSH services."
			echo -e "[`TZ='Asia/Singapore' date`] SSH Port $port found open for $TARGETNAME." >> $logFILE
		done
	fi
	#------------------#
	#----RDP Filter----#	
	echo -e "\n[${YELLOW}!${NC}] Filtering for RDP ports..." 	
	for each in $(cat $output | grep "rdp" | grep "open" | awk '{printf $1}' | tr /tcp ' ' );
	do
		rdpPort+=($each);	
	done	
	
	if [ -z ${rdpPort[@]} ];
	then
		echo -e "[${PURPLE}~${NC}] No open RDP ports for ${BLUE}$TARGETNAME${NC} detected."
		echo -e "[`TZ='Asia/Singapore' date`] No open RDP ports found for $TARGETNAME." >> $logFILE
		let "noPorts=noPorts+1"
	else
		for ports in ${rdpPort[@]};
		do
			echo -e "[${YELLOW}!${NC}] Port $ports is ${GREEN}open${NC} for RDP services."
			echo -e "[`TZ='Asia/Singapore' date`] RDP Port $port found open for $TARGETNAME." >> $logFILE
		done
	fi
	#------------------#
	#----Telnet Filter----#	
	echo -e "\n[${YELLOW}!${NC}] Filtering for Telnet ports..." 
	for each in $(cat $output | grep "telnet" | grep "open" | awk '{printf $1}' | tr /tcp ' ' );
	do
		telnetPort+=($each);
	done		
		
	if [ -z ${telnetPort[@]} ];
	then
		echo -e "[${PURPLE}~${NC}] No open Telnet ports for ${BLUE}$TARGETNAME${NC} detected."
		echo -e "[`TZ='Asia/Singapore' date`] No open Telnet ports found for $TARGETNAME." >> $logFILE
		let "noPorts=noPorts+1"
	else
		for ports in ${telnetPort[@]};
		do
			echo -e "[${YELLOW}!${NC}] Port $ports is ${GREEN}open${NC} for Telnet services."
			echo -e "[`TZ='Asia/Singapore' date`] Telnet Port $port found open for $TARGETNAME." >> $logFILE
		done
	fi
	#------------------#
}
#Function Name: verifyIP()
#Function Purpose: Verifies that the user inputted IP is correct. Otherwise exits the script.
#Function Author: Matthias
#Reference: Based on this stackoverflow question: https://stackoverflow.com/questions/23675400/validating-an-ip-address-using-bash-script
verifyIP()
{
	#Takes in the specified IP address and begins testing it for validity
	#This function does not log events as it runs before the log is created.
	IP=$TARGETIP

    if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];
    then
        OIFS=$IFS 	# Save the actual IFS in a var named OIFS
        IFS='.'   	# IFS (Internal Field Separator) set to .
        IPA=($IP)  	# ¿Converts $ip into an array saving ip fields on it?
        IFS=$OIFS 	# Restore the old IFS

       if [[ ${IPA[0]} -le 255 && ${IPA[1]} -le 255 && ${IPA[2]} -le 255 && ${IPA[3]} -le 255 ]];  # If $ip[0], $ip[1], $ip[2] and $ip[3] are minor or equal than 255 then
       then
			echo -e "[${LGREEN}i${NC}] IP address entered is ${GREEN}valid${NC}.\n"
		else
			echo -e "[${YELLOW}!${NC}] IP address entered is ${RED}invalid${NC}. Exiting script.."
			exit 0
		fi
	else
		echo -e "[${YELLOW}!${NC}] IP address entered is ${RED}invalid${NC}. Exiting script.."
		exit 0

    fi
}
#Function Name: outProcess()
#Function Purpose: Function used to finalize the script output. Used to mainly prompt the user if they want to zip the output folder or not. It also processes the nmap
#				   output xml into a readable HTML file. It also runs the exit code that terminates the script.
#Function Author: Matthias
outProcess()
{
	#Turns the XML output into a human readable HTML format
	xsltproc $outXML >> ./$TARGETDIR/$TARGETNAME.html	
	echo -e "[${YELLOW}!${NC}] Complete script log can be found at $logFILE\n"
	#Queries the user if they want to zip up the contents of the output folder
	read -p "[?] Would you like to zip up the contents of the output folder? [Y/N] " USERIN
	
	if [ $USERIN == "Y" ] || [ $USERIN == "y" ];
		then
			#Prompts the user for a filename if desired
			read -p "[?] Specify the desired zip filename (leave blank for default): " ZIPNAME
			
			#Tests for if the variable is empty or not
			if [ -z $ZIPNAME ];
			then
				#Zips the folder into a zip of the same name, and ends the script.
				zip -r9 $TARGETDIR.zip ./$TARGETDIR
				echo -e "[${LGREEN}i${NC}] Output zipped to ${BLUE}$TARGETDIR.zip${NC}. Ending script."
				echo -e "[`TZ='Asia/Singapore' date`] Output zipped to $TARGETDIR.zip." >> $logFILE
				exit 1
			else
				#Zips the folder into the specified zip name, and ends the script.
				zip -r9 $ZIPNAME.zip ./$TARGETDIR
				echo -e "[${LGREEN}i${NC}] Output zipped to ${BLUE}$ZIPNAME.zip${NC}. Ending script."
				echo -e "[`TZ='Asia/Singapore' date`] Output zipped to $ZIPNAME.zip." >> $logFILE
				echo -e "[`TZ='Asia/Singapore' date`] Script complete. Ending script and log." >> $logFILE
				exit 1
			fi
		else
			#Ends the script, as no zipping is required
			echo -e "[${LGREEN}i${NC}] Ending script."
			echo -e "[`TZ='Asia/Singapore' date`] No ZIP file created." >> $logFILE
			echo -e "[`TZ='Asia/Singapore' date`] Script complete. Ending script and log." >> $logFILE
			exit 1
	fi
}
#Function Name: mainBody()
#Function Purpose: Used to run the script, and get the required inputs such as IP, name and output directory.
#Function Author: Matthias
mainBody()
{
	
	#Provide a brief description of the script, and explain the differences between basic and full mode.
	echo -e "[${LGREEN}i${NC}] Welcome to the enumeration utility. This script can run in either ${PURPLE}basic${NC} or ${BLUE}full${NC} mode."
	echo -e "[${LGREEN}i${NC}] In ${PURPLE}basic mode${NC}, it will scan for all open TCP and UDP ports, and test for weak passwords."
	echo -e "[${LGREEN}i${NC}] In ${BLUE}full mode${NC}, it will also check for vulnerabilities using searchsploit.\n"
	
	read -p "[?] Enter a target IP to scan: " TARGETIP
	echo -e "[${LGREEN}i${NC}] Verifying validity of IP address $TARGETIP."	
	verifyIP
		
	read -p "[?] Enter a name for the target: " TARGETNAME
	read -p "[?] Specify a directory to store the results: " TARGETDIR
	
	#Creates a log file to log all outputs
	logFILE="./$TARGETDIR/$TARGETNAME.log"	
	echo -e "[`TZ='Asia/Singapore' date`] Script started. Beginning log." >> $logFILE
	
	#Check that the IP address is valid, exit the script if it isn't
	
	#Checks if the directory specified already exists, and creates it if it doesn't.
	if [ -d $TARGETDIR ];
	then
		echo -e "[${LGREEN}i${NC}] Directory $TARGETDIR already exists. Skipping creation."
		echo -e "[`TZ='Asia/Singapore' date`] Directory $TARGETDIR not created as it already exists in this location." >> $logFILE
	else
		mkdir $TARGETDIR
		echo -e "[`TZ='Asia/Singapore' date`] Directory $TARGETDIR created." >> $logFILE		
	fi
	
	echo -e "\n[${LGREEN}i${NC}] The target to scan is $TARGETNAME, and the IP to scan is $TARGETIP. All output will be stored in $TARGETDIR."
	
	#Prompt the user to select the scan type desired, and execute the appropriate function
	while : ; do	
		read -p "[?] Enter [B] for a basic scan or [F] for full scan: " SCAN_TYPE
		
		if [ $SCAN_TYPE == "f" ] || [ $SCAN_TYPE == "F" ]; 
			then
				echo -e "[${LGREEN}i${NC}] Running in ${BLUE}full mode${NC} ..."
				fullMode
				outProcess
			elif [ $SCAN_TYPE == "b" ] || [ $SCAN_TYPE == "B" ];
			then
				echo -e "[${LGREEN}i${NC}] Running in ${PURPLE}basic mode${NC} ..."				
				basicMode
				outProcess	
			else
				echo -e "[!] Selection ${RED}invalid${NC}. Please select a valid choice.\n"
		fi		
	done
	
}
#END FUNCTION DEFINITIONS
#------------------------------------------------

#------------------------------------------------
#START OF SCRIPT MAIN BODY
#------------------------------------------------

mainBody

#------------------------------------------------
#END OF SCRIPT MAIN BODY
#------------------------------------------------
