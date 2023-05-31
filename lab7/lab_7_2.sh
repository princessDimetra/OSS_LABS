#!/bin/bash

# Function to check file permissions
check_file_permissions() {
    local file="$1"
    local user="$2"
    local group="$3"

    if [ ! -f "$file" ]; then
        return
    fi

    file_owner=$(stat -c '%U' "$file")
    file_group=$(stat -c '%G' "$file")
    file_permissions=$(stat -c '%A' "$file")

    if [ "$file_owner" != "$user" ] && [ "${file_permissions:2:1}" = "w" ] && [ "$file_owner" != "root" ]; then
        echo "Security Violation: Service $unit, file $file has write permissions for user $file_owner."
    fi

    if [ "$file_group" != "$group" ] && [ "${file_permissions:5:1}" = "w" ]; then
        echo "Security Violation: Service $unit, file $file has write permissions for group $file_group."
    fi

    if [ "${file_permissions:8:1}" = "w" ]; then
        echo "Security Violation: Service $unit, file $file has write permissions for other users."
    fi

    acl_entries=$(getfacl -p "$file" | grep -E "^(user:|group:)" | grep -v -E "user::|group::")

    while IFS= read -r acl_entry; do
        acl_type=$(echo "$acl_entry" | cut -d':' -f1)
        acl_user_or_group=$(echo "$acl_entry" | cut -d':' -f2)
        acl_permissions=$(echo "$acl_entry" | cut -d':' -f3)

        if [ "$acl_type" = "user" ] && [ "$acl_user_or_group" != "$user" ] && echo "$acl_permissions" | grep -q "w"; then
            echo "Security Violation: Service $unit, file $file has write permissions via ACL for user $acl_user_or_group."
        elif [ "$acl_type" = "group" ] && [ "$acl_user_or_group" != "$group" ] && echo "$acl_permissions" | grep -q "w"; then
            echo "Security Violation: Service $unit, file $file has write permissions via ACL for group $acl_user_or_group."
        fi
    done <<< "$acl_entries"
}

# Main script
systemctl list-unit-files --type=service --full --no-legend | while read -r line; do
    unit=$(echo "$line" | awk '{print $1}')
    state=$(echo "$line" | awk '{print $4}')

    if [[ "$unit" == *@* ]]; then
        continue
    fi

    if [ "$state" = "disabled" ] || [ "$state" = "static" ]; then
        continue
    fi

    #echo -e "\nProcessing service: $unit"
    user=$(systemctl show -p User --value "$unit")
    [ -z "$user" ] && user="root"
    group=$(systemctl show -p Group --value "$unit")
    [ -z "$group" ] && group="root"

    unit_path=""
    if [ -f "/usr/lib/systemd/system/$unit" ]; then
        unit_path="/usr/lib/systemd/system/$unit"
    elif [ -f "/etc/systemd/system/$unit" ]; then
        unit_path="/etc/systemd/system/$unit"
    fi
    override_path="/etc/systemd/system/$unit.d/override.conf"

    check_files=("$unit_path")
    [ -f "$override_path" ] && check_files+=("$override_path")

    for file in "${check_files[@]}"; do
        check_file_permissions "$file" "$user" "$group"
    done

    exec_start=$(systemctl show -p ExecStart --value "$unit")
    exec_start_pre=$(systemctl show -p ExecStartPre --value "$unit")

    commands=()

    if [[ -n "$exec_start" ]]; then
        while IFS= read -r line; do
            cmd=$(echo "$line" | sed -n 's/^.*[^-]path=\([^ ;]*\).*$/\1/p')
            if [[ -n "$cmd" ]] && [[ -e "$cmd" ]]; then
                commands+=("$cmd")
                check_files+=("$cmd")
            fi
        done <<< "$exec_start"
    fi

    if [[ -n "$exec_start_pre" ]]; then
        while IFS= read -r line; do
            cmd_pre=$(echo "$line" | sed -n 's/^.*path=\([^ ;]*\).*$/\1/p')
            if [[ -n "$cmd_pre" ]]; then
                commands+=("$cmd_pre")
                check_files+=("$cmd_pre")
            fi
        done <<< "$exec_start_pre"
    fi

    for file in "${check_files[@]}"; do
        check_file_permissions "$file" "$user" "$group"
    done

    for cmd in "${commands[@]}"; do
        executable=$cmd

        if [ -n "$executable" ]; then
            if [ "$(stat -c '%a' "$executable" | cut -c1)" = "4" ] && [ "$(stat -c '%U' "$executable")" = "root" ] && [ "$user" != "root" ]; then
                echo "Security Violation: Service $unit, SUID file $executable is executed by user $user."
            fi
        fi
    done
done