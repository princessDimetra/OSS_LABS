#!/bin/bash
echo "Execute the script only with root rights"
echo "Select an action from the list: "
showtable(){
	df -Th -x procfs -x tmfs -x devtmpfs -x sysfs
}
Mountsystem(){
	ls /dev
	read -p "Enter the device or file path: " device_file

	if [ ! -e $device_file ]; then
	  echo "File or device not found"
	  exit 1
	fi

	read -p "Enter the path to the mount directory: " mount_dir

	if [ ! -d $mount_dir ]; then
	  mkdir $mount_dir
	fi

	if [ "$(ls -A $mount_dir)" ]; then
	  echo "The mounting directory is not empty"
	  exit 1
	fi

	if [ -b $device_file ]; then
	  mount $device_file $mount_dir
	else
	  mount -o loop $device_file $mount_dir
	fi

	if [ $? -eq 0 ]; then
	  echo "Successful mounting!"
	else
	  echo "The mount attempt failed. Try again."
	fi
}
Unmountsystem(){
	PS3="Select the partition to unmount or enter the path: "
	options=($(find /dev -maxdepth 1 -type b -not -name 'loop*' -not -name 'ram*' -not -name 'dm-*' -printf "%f\n"))
	select opt in "${options[@]}" "Enter a path"; do
	    case $opt in
		"Enter a path")
		    read -p "Enter the path to the section:" device
		    break
		    ;;
		*)
		    device="/dev/$opt"
		    break
		    ;;
	    esac
	done
	if ! grep -qs "^$device " /proc/mounts; then
	    echo "The $device section is not mounted"
	    exit 1
	fi
	sudo umount $device
	echo "The $device partition is unmounted"
}
changeparameter(){
	filesystems=$(mount | grep -v "type tmpfs" | grep -v "type proc" | grep -v "type sysfs" | grep -v "type devpts" | grep -v "type debugfs" | grep -v "type securityfs" | grep -v "type cgroup" | grep -v "type pstore" | grep -v "type hugetlbfs" | grep -v "type mqueue" | awk '{print $1}')
	echo "Available file systems:"
	echo "$filesystems"
	echo "Enter the file number of the system or the path to it:"
	read choice
	if [[ $choice == /dev/* ]]; then
	    filesystem=$choice
	else
	    filesystem=$(echo "$filesystems" | sed -n "${choice}p")
	fi
	if [[ -z $filesystem ]]; then
	    echo "The file system is not selected."
	    exit 1
	fi
	echo "Select the mount mode:"
	echo "1 - Read Only"
	echo "2 - Read and Write"
	read mode_choice
	case $mode_choice in
	    1)
		mount -o remount,ro $filesystem
		echo "The file system has been switched to read-only mode."
		;;
	    2)
		mount -o remount,rw $filesystem
		echo "The file system has been switched to read and write mode."
		;;
	    *)
		echo "Incorrect choice."
		exit 1
		;;
	esac
	exit 0
}
mountingpar(){
	filesystems=$(mount | grep -v "type tmpfs" | grep -v "type proc" | grep -v "type sysfs" | grep -v "type devpts" | grep -v "type debugfs" | grep -v "type securityfs" | grep -v "type cgroup" | grep -v "type pstore" | grep -v "type hugetlbfs" | grep -v "type mqueue" | awk '{print $1}')
	echo "Available file systems:"
	echo "$filesystems"
	read -p "Enter the mounted file system: " selected_fs
	if echo "$filesystems" | grep -q "$selected_fs"; then
	    mount | grep "$selected_fs"
	else
	    echo "Error: The selected file system was not found."
	fi
}
info(){
	filesystem=$(lsblk -f | grep ext* | awk '{print $1}')
	echo "Select a file system:"
	select fs in $filesystem
	do
	    if [[ -n "$fs" ]]; then
		break
	    fi
	done
	echo "Detailed information about the file system $fs:"
	tune2fs -l /dev/$fs
}
PS3='>'
options=( "Output the file system showtable" "Mount the file system" "Unmount the file system" "Change the mounting parameters of the mounted file system" "Output the mounting parameters of the mounted file system" "Output detailed information about the file system ext* " "Exit") 
while true
do
	select opt in "${options[@]}"
	do
	case $opt in
		"Output the file system showtable")
			showtable
			break;;
		"Mount the file system")
			Mountsystem
			break;;
		"Unmount the file system")
			Unmountsystem
			break;;
		"Change the mounting parameters of the mounted file system")
			changeparameter
			break;;
		"Output the mounting parameters of the mounted file system")
			mountingpar
			break;;
		"Output detailed information about the file system ext* ")
			info
			break;;
		"Exit") exit;;
	*) echo "There is no such option";;
	esac
done
done
