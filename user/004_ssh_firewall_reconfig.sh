#!/bin/sh

function change_setting () {
  TARGET=$1
  KEYWORD=$2
  VALUE=$3

  EXIST=`grep "^${KEYWORD}" ${TARGET}`
  EXIST_COMMENT=`grep "^#${KEYWORD}" ${TARGET}`

  if [ ${#EXIST} -ne 0 ]; then
    sed -i '/^'${KEYWORD}'/c '${KEYWORD}' '${VALUE}'' ${TARGET}
  elif [ ${#EXIST_PERMIT_COMMENT} -ne 0 ]; then
    sed -i '/^#'${KEYWORD}'/c '${KEYWORD}' '${VALUE}'' ${TARGET} 
  else
    echo -e "${KEYWORD} ${VALUE}" >> ${TARGET}
  fi
}

echo "This script file must be executed after su command."
echo -n "Are you ready? [y/n] "
read ANSWER

case ${ANSWER} in
    y)
      break
      ;;
    *)
      echo "The script was blocked."
      exit
      break
      ;;
esac

echo
echo "* Install semanage"
yum -y install policycoreutils-python

echo
echo "* SSH configuration"

SSH_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG_BACKUP="/etc/ssh/sshd_config_backup"
PORT_NUMBER=""

echo -n "Do you want to change ${SSH_CONFIG}? [y/n] "
read ANSWER1

case ${ANSWER1} in
  n)
    echo "SSH configuration was skipped."
    break
    ;;
  y)
    if [ -f ${SSH_CONFIG_BACKUP} ]; then
      echo -n "\"${SSH_CONFIG_BACKUP}\" already exists. Continue anyway? [y/n] "
      read ANSWER2
    fi

    case ${ANSWER2} in
      n)
        echo "SSH configuration was skipped."
        break
        ;;
      y)
        cp -i ${SSH_CONFIG} ${SSH_CONFIG_BACKUP}

        echo -n "Change port number (just Enter for no change): "
        read PORT_NUMBER

        echo -e "These settings were changed.\n"

        # Port
        if [ ${#PORT_NUMBER} -ne 0 ]; then
          change_setting ${SSH_CONFIG} Port ${PORT_NUMBER}
          grep "^Port" ${SSH_CONFIG}
        fi

        # PermitRootLogin
        change_setting ${SSH_CONFIG} PermitRootLogin no
        grep "^PermitRootLogin" ${SSH_CONFIG}

        # PasswordAuthentication
        change_setting ${SSH_CONFIG} PasswordAuthentication no
        grep "^PasswordAuthentication" ${SSH_CONFIG}

	# ChallengeResponseAuthentication
        change_setting ${SSH_CONFIG} ChallengeResponseAuthentication no
        grep "^ChallengeResponseAuthentication" ${SSH_CONFIG}

	# PermitEmptyPasswords
        change_setting ${SSH_CONFIG} PermitEmptyPasswords no
        grep "^PermitEmptyPasswords" ${SSH_CONFIG}

	# SyslogFacility
        change_setting ${SSH_CONFIG} SyslogFacility AUTHPRIV
        grep "^SyslogFacility" ${SSH_CONFIG}

	# LogLevel
        change_setting ${SSH_CONFIG} LogLevel VERBOSE
        grep "^LogLevel" ${SSH_CONFIG}

	# TCP Port Forwarding
        #change_setting ${SSH_CONFIG} AllowTcpForwarding no
        #grep "^AllowTcpForwarding" ${SSH_CONFIG}

	# AllowStreamLocalForwarding
        #change_setting ${SSH_CONFIG} AllowStreamLocalForwarding no
        #grep "^AllowStreamLocalForwarding" ${SSH_CONFIG}

	# GatewayPorts
        #change_setting ${SSH_CONFIG} GatewayPorts no
        #grep "^GatewayPorts" ${SSH_CONFIG}

	# PermitTunnel
        #change_setting ${SSH_CONFIG} PermitTunnel no
        #grep "^PermitTunnel" ${SSH_CONFIG}

        echo

        echo "Edit \"AllowUsers\" if you need."
        echo
        break
        ;;
      *)
        echo "Cannot understand \"${ANSWER2}\"."
        exit
        break
        ;;
    esac
    break
    ;;
  *)
    echo "Cannot understand \"${ANSWER1}\"."
    exit
    break
    ;;
esac

echo "Press any key to continue ... "
read BUFFER
echo

echo
echo "* Firewall configuration"

FW_INACTIVE=`systemctl status firewalld.service | grep inactive`
if [ ${#FW_INACTIVE} -ne 0 ]; then
  echo "firewalld is inactive."
  echo -n "Activating firewalld ... "
  systemctl start firewalld.service
  echo "[done]"
fi

echo "This is your firewalld setting."
echo

firewall-cmd --list-all

echo "Do you want to change firewall settings?"
echo -n "( If you changed the SSH port number, you MUST choose 'y' ) [y/n] "
read ANSWER3

FW_CONFIG="/usr/lib/firewalld/services/ssh.xml"
FW_CONFIG_BACKUP="/etc/firewalld/services/ssh-${PORT_NUMBER}.xml"

case ${ANSWER3} in
  n)
    echo "firewalld configuration was skipped."
    break
    ;;
  y)
    echo "Changing firewall setting for SSH new port number ... "
    if [ ${#PORT_NUMBER} -eq 0 ]; then
      echo "SSH port number is not defined."
      echo -n "Enter the port number: "
      read PORT_NUMBER
      FW_CONFIG_BACKUP="/etc/firewalld/services/ssh-${PORT_NUMBER}.xml"
    fi

    EXEC_CHANGE=1
    if [ -f ${FW_CONFIG_BACKUP} ]; then
      echo -n  "${FW_CONFIG_BACKUP} already exists. Continue anyway? [y/n] "
      read ANSWER4
      case ${ANSWER4} in
        y)
          break
          ;;
        *)
          EXEC_CHANGE=0
          echo "[skipped]"
          break
          ;;
      esac
    fi

    if [ ${EXEC_CHANGE} -eq 1 ]; then
      firewall-cmd --permanent --remove-service=ssh
      cp ${FW_CONFIG} ${FW_CONFIG_BACKUP}
      #cat ${FW_CONFIG}
      sed -i '/port protocol/c \ \ <port protocol="tcp" port="'${PORT_NUMBER}'"/>' ${FW_CONFIG_BACKUP}
      firewall-cmd --permanent --add-service=ssh-${PORT_NUMBER}
      firewall-cmd --add-port=${PORT_NUMBER}/tcp --zone=public --permanent
      echo "[done]"
      echo "Changing SELinux setting ... "
      set -x
      semanage port --list | grep ssh
      semanage port --add --type ssh_port_t --proto tcp ${PORT_NUMBER}
      semanage port --list | grep ssh
      set +x
      echo "[done]"
      echo "firewall setting for SSH is changed as below."
      echo
      cat ${FW_CONFIG_BACKUP}
    fi

    break
    ;;
  *)
    echo "Cannot understand \"${ANSWER3}\"."
    exit
    break
    ;;
esac

echo
echo "This is final step."
echo -n "Are you sure to reload firewalld? [y/n] "
read ANSWER5
case ${ANSWER5} in
    y)
      systemctl enable firewalld.service
      firewall-cmd --reload
      echo "firewalld was reloaded."
      echo "firewalld active ports"
      firewall-cmd --list-ports --zone=public --permanent
      echo "SELinux SSH active ports"
      semanage port --list | grep ssh
      break
      ;;
    *)
      echo "firewalld was NOT reloaded."
      break
      ;;
esac

echo
echo -n "Are you sure to reload sshd? [y/n] "
read ANSWER6
case ${ANSWER6} in
    y)
      SSHD_INACTIVE=`systemctl status sshd.service | grep inactive`
      if [ ${#SSHD_INACTIVE} -ne 0 ]; then
        systemctl start sshd.service
      else
        systemctl restart sshd.service
      fi
      systemctl enable sshd.service
      echo "sshd was reloaded successfully."
      break
      ;;
    *)
      echo "sshd was NOT reloaded."
      break
      ;;
esac
