These scripts were created while undergoing the Cybersecurity Career Kickstart programme conducted by the Centre for Cybersecurity. Each of the three scripts were written in the process of completing their specific modules, and each is designed to cater to a specific set of requirements, dictated by the project requirements at the time.

Network Research  Script
This script was written to send commands to a specified remote server, and transfer the results of the commands back to the main host. This transfer is accomplished by outputting the results of the command to text files, and then having the host download said text files from the remote server. In the process, the script checks to see if the necessary packages required are present, if they are not then it also installs them.

Python Fundamentals Project
This script was written, specifically in Python, in order to log and parse auth.log, a key file on many Linux systems. It works by checking each lines for specfic keywords often used in commands, such as cp, nano, service, apt-get. It then outputs these commands to the terminal.

Penetration Testing Script
This script was written to conduct a vulnerability assessment of a user-specified network target. The script scans the IP, checking for open TCP and UDP ports, and relaying the status of said ports and which services normally use them. It also conducts a test for weak passwords, accomplishing this through a brute force attack. The user must specify a list of usernames, but the script also includes a list of default passwords to test for. Finally, the script then checks the target for vulnerabilities, logging all found vulnerabilities to a text file. The script also writes its own log, which can be checked for more detailed results.
