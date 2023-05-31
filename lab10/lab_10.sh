#!/bin/bash

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S')]: $*" >&2
}

readinput() {
	local -n arr=$1
	arr+=("Help" "Back")
	select opt in "${arr[@]}"; do
	case $opt in
		Back) return 0;;
		Help) echo "Enter the number corresponding to the option from the list";;
		*)
			if [[ -z $opt ]]; then
				echo "Error: enter a number from the list" >&2
			else
				return $REPLY
			fi
			;;
	esac
	done
}

if [ "$EUID" -ne 0 ]; then
	echo "Not an administrator"
	exit
fi

PS3=$'\n> '
options=(
	"Audit Event Search"
	"Audit Reports"
	"Audit Subsystem Configuration"
	"Help"
	"Exit"
)

select opt in "${options[@]}"
do
	case $opt in
	"Audit Event Search")
		read -p "Enter the event type (if empty, then ALL): " eventtype
		if [ "$eventtype" == "" ]; then
			eventtype=ALL
		fi
		read -p "Enter the user ID (can be empty): " userid
		read -p "Enter the search string: " searchstring
		[ "$searchstring" == "" ] && searchstring="="
		if [ "$userid" == "" ]; then
			ausearch -m $eventtype | grep $searchstring -B 2
		else
			ausearch -m $eventtype -ui $userid | grep $searchstring -B 2
		fi
		;;

	"Audit Reports")
		echo "Select the information of interest: "
		options2=("User Login Report" "Violation Report")
		readinput options2
		res=$?
		[ $res == 0 ] && continue
		if [ $res == 1 ]; then
			echo "Generated user login report for the day, week, month, year (files auth_...)"
			aureport -au -ts today > auth_day
			aureport -au -ts this-week > auth_week
			aureport -au -ts this-month > auth_month
			aureport -au -ts this-year > auth_year
		else
			echo "Generated violation report for the day, week, month, year (files failed_...)"
			aureport --failed --user -ts today > failed_day
			aureport --failed --user -ts this-week > failed_week
			aureport --failed --user -ts this-month > failed_month
			aureport --failed --user -ts this-year > failed_year
		fi
		;;

	"Audit Subsystem Configuration")
		echo "Select the option of interest: "
		options2=("Add Directory/File to Watchlist" "Remove from Watchlist" "Watchlist Report")
		readinput options2
		res=$?
		[ $res == 0 ] && continue
		if [ $res == 1 ]; then
			read -p "Enter the path to the file/directory: " filepath
			if [ "$filepath" == "" ]; then
				err "Path cannot be empty"
				continue
			fi
			if [ ! -e $filepath ]; then
				err "Path does not exist"
				continue
			elif [ -d $filepath ]; then
				auditctl -a exit,always -F dir=$filepath -F perm=warx
			else
				auditctl -w $filepath -p warx
			fi
		elif [ $res == 2 ]; then
			echo "Select the path of interest"
			readarray -t paths < <(auditctl -l | cut -d " " -f2)
			readinput paths
			res=$?
			[ $res == 0 ] && continue
			path=${paths[res - 1]}
			auditctl -W $path
		else
			echo "Select the path of interest"
			readarray -t paths < <(auditctl -l | cut -d " " -f2)
			readinput paths
			res=$?
			[ $res == 0 ] && continue
			path=${paths[res - 1]}
			res=$(aureport --file | grep $path)
			[ "$res" == "" ] && res="No events"
			echo "${res}"
		fi
		;;

	"Help")
		echo "Enter the command of interest"
		;;

	"Exit")
		break
		;;

	*) echo "Invalid command";;
	esac
done
