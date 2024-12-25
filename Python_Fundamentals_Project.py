#!/usr/bin/python3

#Python script to fulfil project requirements.

import string
import os

#1. Log Parse auth.log: Extract command usage.
#1.1. Include the Timestamp.
#1.2. Include the executing user.
#1.3. Include the command.
#2. Log Parse auth.log: Monitor user authentication changes.
#2.1. Print details of newly added users, including the Timestamp.
#2.2. Print details of deleted users, including the Timestamp.
#2.3. Print details of changing passwords, including the Timestamp.
#2.4. Print details of when users used the su command.
#2.5. Print details of users who used the sudo; include the command.
#2.6. Print ALERT! If users failed to use the sudo command; include the command.

#Date: 10/06/2024
#Author: Matthias Soh
#Purpose: To parse an auth.log file and output useful information as listed above.

#----------- HELPER FUNCTIONS -------------#
#These functions are used to streamline the script through code reusing.
#------------------------------------------#

#Function used to load data from a specified file
def loadFILE( fNAME ):
	if os.path.isfile(fNAME):
		#Loads the file into the variable file
		file=open(fNAME,'r')
		
		#The data is then read into the variable data, which is returned as an output
		data=file.readlines()	
		return(data)
		
		#The file is then closed
		file.close
	else:
		#If the file is not found, then the script closes
		print('Error! File '+fNAME+' not found!')
		quit()
#END FUNCDEF

#This function used to locate a specified SEARCH term and search in the srcDATA for the term,
#any matches are then appended to the output list.
def findCMD( SEARCH, srcDATA, outLST):
	#The function loops through the data
	for each in srcDATA:
		#For each instance of the search term found, it adds it to the output list
		if SEARCH in each:
			outLST.append(each)
			
#END FUNCDEF

#This function takes the input from the output list and iterates through the list, passing
#each item in the list to the specified function to further refine the results.
def printLST( outLST , funcFORMAT):
	for iterator in range(len(outLST)):
		funcFORMAT(outLST[iterator])
#END FUNCDEF

#This function is used to cut down on redundant code, as it was found that timestamping 
#output generally used the same code format. It takes a line of text as a list.
def getUDT( LINE ):
	#Creates a list of dates by month
	dateLST=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
	for i in range(len(dateLST)):	
		#If the log uses months first, then the user, date and time will be retrieved as follows
		if LINE[0] in dateLST:
			user=LINE[5]
			date=LINE[0]+' '+LINE[1]
			time=LINE[2]
		else:
			#Other wise it uses this method of retrieving 
			#The user name is usually the third element in the line.
			user=LINE[3]

			#The date is always the first element in the list, and is split using the char T
			temp=LINE[0].split('T')
			date=temp[0]
			
			#The string is further split to get the time
			temp2=temp[1].split('.')
			time=temp2[0]
	
	#The values are then returned to the output
	return date, time, user
#END FUNCDEF

#--------------------------MAIN FUNCTIONS------------------------------#
#These functions are what perform most of the work in the script, and are tailored for specific commands/search terms.
#----------------------------------------------------------------------#

#Function used to parse a line to find the command used and who used it, and when
def parseCMD( cmdLINE ):
	fLINE=cmdLINE.split()
	#temp=[]
	i=0
	cmd=''
	
	#Finds the location of 'COMMAND' in the line, and slices that till the end of the line
	for each in fLINE:
		#This is used to count the position of the 'cursor' until it reaches COMMAND
		i=i+1
		if 'COMMAND' in each:
			#Each element from that point is then added to the list.
			temp=fLINE[i-1:]			

	#Further splits the first item to only get the command used, and store it in the variable
	temp2=temp[0].split('/')
	cmd=temp2[-1]
	
	#Removes the COMMAND section
	temp.pop(0)
	
	#Appends any further command flags to the command
	for i in range(len(temp)):
		cmd=cmd+' '+temp[i]
		
	#GET date, time and user
	date,time,user=getUDT(fLINE)
	
	#Prints the output.
	print('The command \033[1;32;40m"'+cmd+'"\033[0;37;40m was used by '+user+' at ' +time+ ' on the ' +date+'.')		
#END FUNCDEF

#Function for formatting and displaying users added and by who
def addUSER( userLST, grpLST ):	
	
	#First, the function finds any new usernames used in the useradd command
	for i in range(len(userLST)):	
		fLINE=userLST[i].split()
		nUSER=fLINE[-1]
		#Then these new usernames are passed through the instances of groupadd commands
		for j in range(len(grpLST)):
			#Only if the username appears in BOTH the useradd list AND the groupadd list is it printed
			if nUSER in userLST[i] and nUSER in grpLST[j]:
							
				#GET date, time and user
				date,time,user=getUDT(fLINE)
				
				#Prints the output
				print('User '+nUSER+' was added by '+user+' at ' +time+ ' on the ' +date+'.')
				break
#END FUNCDEF	

#Function for formatting and displaying users deleted and by who
def delUSER( cmdLINE ):
	fLINE=cmdLINE.split()
	#The deleted username is always the last term in this line
	deleted=fLINE[-1]
			
	#GET date,time and user
	date,time, user=getUDT(fLINE)
			
	#prints the output
	print('User '+deleted+' was deleted by '+user+' at ' +time+ ' on the ' +date+'.')	
#END FUNCDEF

#Function for formatting and displaying whose passwords were changed and by who
def pwdCH( cmdLST ):
	pwdLST=[]
	userCHLST=[]
	
	#First it further refines the command list down to commands containing passwd
	for each in cmdLST:
		if 'passwd' in each:
			pwdLST.append(each)
	if len(pwdLST) > 0:
		print("\n\033[1;34;40m[!] The following passwords were changed in the log file:\033[0;37;40m")
		#Each of the elements in the password list is then split
		for i in range(len(pwdLST)):
			fLINE=pwdLST[i].split()
			#Because the username whose password is changed is always at the end of the list we take fLINE[-1]
			userCH=fLINE[-1]
			
			#GET date, time and user
			date,time,user=getUDT(fLINE)
			
			#Prints the output
			print('User '+userCH+' had their password changed by '+user+' at ' +time+ ' on the ' +date+'.')
	else:
		print("\n\033[1;34;40m[!] No passwords were changed in the log file:\033[0;37;40m")
#END FUNCDEF

#Function for formatting and displaying use of su command
def suUSED( cmdLINE ):
	fLINE=cmdLINE.split()
	
	#Who the users changed to, and changed from are always the same position
	userOG=fLINE[-1]
	userNEW=fLINE[-3]
	#The results could be further refined, but I opted not to because the userID is included by default
		
	#get date and time and user(unused)
	date,time, user=getUDT(fLINE)
	
	print('\033[1;31;40m'+userOG+'\033[0;37;40m changed to \033[1;31;40m'+userNEW+'\033[0;37;40m  at ' +time+ ' on the ' +date+'.')
#END FUNCDEF

#Function for formatting and displaying use of sudo command
def sudoUSED( cmdLST ):
	sudoLST=[]
	
	#Similar to finding changing of passwords, the sudo term is used to refine the commands used
	for each in cmdLST:
		#They are then appended to the sudo list
		if 'sudo' in each:
			sudoLST.append(each)
	if len(sudoLST) > 0:	
		print("\n\033[1;34;40m[!] The following commands were executed under the SUDO command in the log file:\033[0;37;40m")
		#Because the lines are basically the same as in the first function, we call parseCMD again
		for i in range(len(sudoLST)):
			parseCMD(sudoLST[i])
	else:
		print("\n\033[1;34;40m[!] No commands were executed under the SUDO command in the log file:\033[0;37;40m") 

#END FUNCDEF

#Function for formatting and displaying failed SUDO commands
def sudoFAIL( cmdLINE ):
	fLINE=cmdLINE.split()
	
	#GET date and time
	date,time,user=getUDT(fLINE)
	
	#Retrieve the user who used the command by further splitting the last string, overwritting the previous user value(which is wrong)
	temp=fLINE[-1].split('=')
	user=temp[1]
	
	print('\033[1;31;40mALERT! \033[0;37;40mAttempted SUDO usage by ' +user+ ' failed at ' +time+ ' on the ' +date+'.')
#END FUNCDEF

#-------------------------------------SCRIPT MAIN BODY-----------------------------------------#
#Load the file data
fileNAME=input('Enter the name of a log file:')
fileDATA=loadFILE(fileNAME)

#------------------- Section for finding commands used and printing who added them and when -----------------------#  [DONE]
print("\n\033[1;34;40m[!] The following commands were found in the log file:\033[0;37;40m")
cmdLST=[]
findCMD( 'COMMAND', fileDATA, cmdLST)
printLST( cmdLST, parseCMD)
cmdTOTAL=str(len(cmdLST))

print("\033[1;34;40m[-] A total of "+cmdTOTAL+" commands were found in the log file.\033[0;37;40m")

#------------------- Section for finding newusers added and printing who added them and when -----------------------#  [DONE]
#Create two lists to check for adduser and groupadd
uaddLST=[]
grpaddLST=[]

findCMD('adduser',fileDATA, uaddLST)
findCMD('groupadd',fileDATA,grpaddLST)
if len(uaddLST) > 0:
	print("\n\033[1;34;40m[!] The following users were added in the log file:\033[0;37;40m")
	#Call the function to seach for user names used in adduser AND who have a group added
	addUSER(uaddLST, grpaddLST)
else:
	print("\n\033[1;34;40m[!] No new users were added in the log file:\033[0;37;40m")

#------------------- Section for finding users deleted and printing who deleted them and when -----------------------#  [DONE]
udelLST=[]

findCMD('deluser',fileDATA,udelLST)
if len(udelLST) > 0:
	print("\n \033[1;34;40m[!] The following users were deleted in the log file:\033[0;37;40m")
	printLST( udelLST, delUSER)
else:
	print("\n\033[1;34;40m[!] No users were deleted in the log file:\033[0;37;40m")	

#------------------- Section for finding passwords changed and printing whose were changed, who changed them and when -----------------------#  [DONE]

pwdCH( cmdLST)

#------------------- Section for finding usage of the su command, who changed to who and when -----------------------#  [DONE]
suLST=[]
findCMD('(su:session): session opened', fileDATA, suLST)
if len(suLST) > 0:	
	print("\n\033[1;34;40m[!] The following uses of the su command were found in the log file:\033[0;37;40m")
	printLST( suLST, suUSED)
else:
	print("\n\033[1;34;40m[!] No uses of the su command were found in the log file:\033[0;37;40m")

#------------------- Section for finding usage of the SUDO command, by who and when -----------------------#  [DONE]
#Calls the sudo used function
sudoUSED(cmdLST)

#------------------- Section for identifying failed SUDO usage, and printing their user names and timestamps -----------------------#  [DONE]
print("")
suFLST=[]
findCMD('(sudo:auth): authentication failure',fileDATA, suFLST)
printLST( suFLST, sudoFAIL )
