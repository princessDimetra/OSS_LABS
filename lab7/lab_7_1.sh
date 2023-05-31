#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "ERROR!"
  exit 1
fi

function HELP() {
  cat <<HELP
Управление системными службами и журналами (systemctl, journalctl)

1) Поиск системных служб
2) Вывести список процессов и связанных с ними systemd служб
3) Управление службами
4) Поиск событий в журнале
5) Справка
6) Выход

HELP
}



function show_proc_and_sluchb() {
  systemctl list-units --type=service --all --no-legend --no-pager | grep '.service' | awk '{print $1}' | while read -r service; do
    service_pid=$(systemctl show -p MainPID "$service" | cut -d= -f2)
    if [ "$service_pid" != "0" ]; then
      echo "Процесс PID $service_pid, служба: $service"
    fi
  done
}

function manage() {
  readarray -t services < <(systemctl list-units --type=service --all --no-legend --no-pager | awk '{print $1}')
  services+=(Справка Назад)

  while true; do
    echo "Выберите службу:"
    select service in "${services[@]}"; do
      case $service in
        Назад) break 2;;
        Справка)
          echo "Введите число, соответствующее выбранной службе"
          ;;
        *)
          if [[ -z $service ]]; then
            echo "Ошибка: введите число из списка"
          else
            while true; do
              echo "Выберите действие:"
              echo "1) Включить службу"
              echo "2) Отключить службу"
              echo "3) Запустить/перезапустить службу"
              echo "4) Остановить службу"
              echo "5) Вывести содержимое юнита службы"
              echo "6) Отредактировать юнит службы"
              echo "7) Назад"
              read -r action

              case $action in
                1)
                  systemctl enable "$service"
                  ;;
                2)
                  systemctl disable "$service"
                  ;;
                3)
                  systemctl restart "$service"
                  ;;
                4)
                  systemctl stop "$service"
                  ;;
                5)
                  systemctl cat "$service" | less
                  ;;
                6)
                  systemctl edit "$service"
                  ;;
                7)
                  break
                  ;;
                *)
                  echo "Ошибка: введите число из списка"
                  ;;
              esac
            done
          fi
          ;;
      esac
    done
  done
}


function search_in_journal() {
  echo -n "Введите имя службы (оставить пустым — любая служба): "
  read service_name
  echo "Степень важности (см. man journalctl):"
  echo "1) emerg"
  echo "2) alert"
  echo "3) crit"
  echo "4) err"
  echo "5) warning"
  echo "6) notice"
  echo "7) info"
  echo "8) debug"
  echo "9) Назад"
  read -r priority

  case $priority in
    1) priority="emerg";;
    2) priority="alert";;
    3) priority="crit";;
    4) priority="err";;
    5) priority="warning";;
    6) priority="notice";;
    7) priority="info";;
    8) priority="debug";;
    9) return;;
    *) echo "Ошибка: введите число из списка"; return;;
  esac

  echo -n "Введите строку поиска: "
  read search_string

  if [ -z "$service_name" ]; then
    journalctl -p "$priority" --no-pager | grep -i "$search_string"
  else
    journalctl -u "$service_name" -p "$priority" --no-pager | grep -i "$search_string"
  fi
}

function poisk_service() {
  echo -n "Введите часть имени или имя службы: "
  read mask
  systemctl list-units --type=service --all --no-legend --no-pager | grep -i "$mask"
}

while true; do
  echo -e "\nВыберите действие:"
  echo "1) Поиск системных служб"
  echo "2) Вывести список процессов и связанных с ними systemd служб"
  echo "3) Управление службами"
  echo "4) Поиск событий в журнале"
  echo "5) Справка"
  echo "6) Выход"
  echo -n "> "
  read -r action
  echo -e "\n"

  case $action in
    1) poisk_service;;
    2) show_proc_and_sluchb;;
    3) manage;;
    4) search_in_journal;;
    5) HELP;;
    6) exit;;
    *) echo "ERROR";;
  esac
done
