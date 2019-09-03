#!/bin/sh

echo "* Create wheel user"

if [ $# -ne 1 ]; then
  echo -e "This script ONLY needs username as the argument."
  exit
fi

HOME_USERS="/home/users"
if [ ! -d ${HOME_USERS} ]; then
  mkdir /home/users
fi

USERNAME=$1

EXISTS=`getent passwd ${USERNAME}`
if [ ${#EXISTS} -ne 0 ]; then
  echo -e "User \"${USERNAME}\" is already exists."
  exit
fi

useradd -m -d /home/users/${USERNAME} -G wheel ${USERNAME}
passwd ${USERNAME}
grep wheel /etc/group

#INSTALL_SCRIPT=/home/users/${USERNAME}/install_script

#cp -r /root/install_script ${INSTALL_SCRIPT}
#chown -R ${USERNAME} ${INSTALL_SCRIPT}
#echo "Install script was copied to ${INSTALL_SCRIPT}"
