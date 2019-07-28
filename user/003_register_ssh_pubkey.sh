#!/bin/sh

echo "* Register your client PC's SSH public key to this server"

echo "Before you run this script, check if you are NOT su."
echo "This script will be failed if you are su."
echo -n "Are you ready? [y/n] "

read ANSWER1

case ${ANSWER1} in
  y)
    break
    ;;
  *)
    echo "The script was blocked."
    exit
esac

echo
echo "Copy your client PC's public key to this server."
echo "Use below command (especially, the filename is important because"
echo "the settings after copying will be executed automatically)"
echo
echo "$ scp pubkey username@address:~/.ssh/temp_client_key"
echo
echo -n "Is copying completed? [y/n] "

read ANSWER2

echo

case ${ANSWER2} in
  n)
    echo "Please re-execute this script after the public key is copied."
    exit
    break
    ;;
  y)
    if [ ! -f "${HOME}/.ssh/temp_client_key" ]; then
      echo "public key not found."
      exit
    fi
    cat ${HOME}/.ssh/temp_client_key >> ${HOME}/.ssh/authorized_keys
    chmod 600 ${HOME}/.ssh/authorized_keys
    rm ${HOME}/.ssh/temp_client_key

    echo "SSH public key setting done."
    break
    ;;
  *)
    echo "Cannot understand \"${ANSWER}\"."
    break
    ;;
esac


