#!/bin/bash

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S')]: $*" >&2
}

print_menu() {
  echo "Menu:"
  for ((i=0; i<${#options[@]}; i++)); do
    echo "$(($i+1))) ${options[$i]}"
  done
  echo
  echo "Enter the number corresponding to the option from the list"
}

select_option() {
  local -n arr=$1
  arr+=("Help" "Back")
  PS3="> "
  select opt in "${arr[@]}"; do
    case $opt in
      Back) return 0;;
      Help) echo "Enter the number corresponding to the option from the list";;
      *) return $REPLY;;
    esac
  done
}

manage_ports() {
  echo "Select the function of interest: "
  local options2=("Modify an existing service port" "Add a new port for a service" "Display all services")
  select_option options2
  local res=$?
  [ $res == 0 ] && return

  if [ $res == 1 ]; then
    read -p "Enter the service name: " name
    name="${name:-port_t}"
    echo "List of ports for the service:"
    semanage port -l -n | grep "$name"
    read -p "Enter the old service port: " port
    if [ -z "$port" ]; then
      echo "Error: Port number cannot be empty" >&2
      return
    fi
    semanage port -d -t "$name" -p tcp "$port"
    [ $? -ne 0 ] && return

    read -p "Enter the new service port: " newport
    if [ -z "$newport" ]; then
      echo "Error: New port number cannot be empty" >&2
      return
    fi
    semanage port -a -t "$name" -p tcp "$newport"

  elif [ $res == 2 ]; then
    read -p "Enter the service name: " name
    if [ -z "$name" ]; then
      echo "Error: Service name cannot be empty" >&2
      return
    fi
    read -p "Enter the new port for the service: " port
    if [ -z "$port" ]; then
      echo "Error: Port number cannot be empty" >&2
      return
    fi
    semanage port -a -t "$name" -p tcp "$port"

  else
    semanage port -l -n | cut -d" " -f1 | uniq -u | less
  fi
}

manage_files() {
  echo "Select the function of interest: "
  local options2=("Relabel a directory" "Start a full filesystem relabel on reboot" "Change the domain of a file or directory")
  select_option options2
  local res=$?
  [ $res == 0 ] && return

  if [ $res == 1 ]; then
    read -p "Enter the directory name: " path
    if [ -d "$path" ]; then
      restorecon -Rvv "$path"
    else
      echo "$path is not a directory"
    fi

  elif [ $res == 2 ]; then
    touch /.autorelabel

  else
    read -p "Enter the path to the file/directory: " filepath
    if [ -z "$filepath" ]; then
      err "Path cannot be empty"
      return
    fi
    if [ ! -e "$filepath" ]; then
      err "Path does not exist"
      return
    fi
    read -p "Enter the new domain: " newdomain
    semanage fcontext -a -t "$newdomain" "$filepath(/.*)?"
    [ $? -ne 0 ] && return
    restorecon -Rv "$filepath"
  fi
}

manage_switches() {
  echo "Select the function of interest: "
  local options2=("Display the list of switches" "Modify a switch")
  select_option options2
  local res=$?
  [ $res == 0 ] && return

  if [ $res == 1 ]; then
    getsebool -a
  else
    readarray -t bools < <(getsebool -a | cut -d' ' -f1)
    select_option bools
    res=$?
    [ $res == 0 ] && return
    bool=${bools[res - 1]}
    state=$(getsebool "$bool" | cut -d" " -f3)
    echo "Current state: $state"
    read -p "Toggle (y/n)? " answer
    if [ "$answer" == "y" ]; then
      newstate="off"
      [ "$state" == "off" ] && newstate="on"
      setsebool -P "$bool" "$newstate"
    fi
  fi
}

if [ "$EUID" -ne 0 ]; then
  echo "Administrator privileges required"
  exit 1
fi

options=("Manage Ports" "Manage Files" "Manage Switches" "Help" "Exit")

while true; do
  print_menu
  select_option options
  choice=$?
  case $choice in
    0) break;;
    1) manage_ports;;
    2) manage_files;;
    3) manage_switches;;
    *) echo "Invalid command: $choice";;
  esac
done
