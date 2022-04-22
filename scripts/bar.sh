#!/bin/dash

# ^c$var^ = fg color
# ^b$var^ = bg color

interval=0

# load colors
. ~/.config/chadwm/scripts/bar_themes/nord

cpu() {
  cpu_val=$(grep -o "^[^ ]*" /proc/loadavg)

  printf "^c$black^ ^b$green^ CPU"
  printf "^c$white^ ^b$grey^ $cpu_val"
}

pkg_updates() {
  #updates=$(doas xbps-install -un | wc -l) # void
  updates=$(checkupdates | wc -l)   # arch , needs pacman contrib
  # updates=$(aptitude search '~U' | wc -l)  # apt (ubuntu,debian etc)

  if echo "$updates" | grep -q "^0$"; then
    printf "^c$green^  Fully Updated"
  else
    printf "^c$green^  $updates"" updates"
  fi
}

get_volume() {
  percent="$(amixer sget Master | grep 'Front Left:' | \
    awk -F '[\\]\\[]' '{print $2}' | sed 's/\%$//')"

  if amixer sget Master | grep -q "off"; then
    volume_icon="婢"
  elif [ "$percent" -gt 69 ]; then
    volume_icon="墳"
  elif [ "$percent" -gt 29 ]; then
    volume_icon="奔"
  else
    volume_icon="奄"
  fi

  printf "^c$red^ $volume_icon "
  printf "^c$red^ $percent"
}

get_battery() {
  get_capacity="$(battery)"
  printf "^c$blue^ %s" "$get_capacity"
}

get_brightness() {
  printf "^c$red^   "
  printf "^c$red^%s\n" $(brightness)
}

mem() {
    printf "^c$blue^^b$black^  "
    printf "^c$blue^ $(free -h | awk '/^Mem/ { print $3 }' | sed s/i//g)"
}

wlan() {
	# case "$(cat /sys/class/net/wl*/operstate 2>/dev/null)" in
	# up) printf "^c$black^ ^b$blue^ 󰤨 ^d^%s" " ^c$blue^Connected" ;;
	# down) printf "^c$black^ ^b$blue^ 󰤭 ^d^%s" " ^c$blue^Disconnected" ;;
	# esac

  upstate=$(ip a | grep BROADCAST,MULTICAST | awk '{print $9}' | head -n 1)
  case "$(cat /sys/class/net/wl*/operstate 2>/dev/null)" in
  down)
      if [ "$upstate" = "DOWN" ]; then
          if [ "$(rfkill | grep 'blocked' | awk '{print $4 $5}' | \
              sed 's/unblocked//g' | uniq | wc -l)" -eq "1" ]; then
                  if [ "$(rfkill | grep 'blocked' | awk '{print $4 $5}' | \
                      sed 's/unblocked//g' | grep . | wc -l)" -gt "0" ]; then
                      printf "^c$black^ ^b$blue^ 泌 ^d^%s" "^c$blue^ off"
                      noupstate="yes"
                  fi
          elif rfkill list wifi | grep 'Soft blocked' | awk '{print $3}' | \
              grep -q 'yes'; then
                  printf "^c$black^ ^b$blue^ 󰤭 ^d^%s" "^c$blue^ off"
                  noupstate="yes"
          fi
          if ! echo "$noupstate" | grep -q "yes"; then
              printf "^c$black^ ^b$blue^ ﮤ ^d^ %s" "^c$blue^$upstate"
          fi
      else
          printf "^c$black^ ^b$blue^ ﮣ ^d^ %s" "^c$blue^$upstate"
      fi;;
  up)
          percent=$(awk '/^\s*w/ { print int($3 * 100 / 70) }' \
              /proc/net/wireless | sed 's/100/99/')

          printf "^c$black^ ^b$blue^ 󰤨 ^d^ %s" "^c$blue^$percent"
  esac
}

clock() {
	printf "^c$black^ ^b$darkblue^ 󱑆 "
	printf "^c$black^^b$blue^ $(date '+%H:%M') "
}

get_date() {
	printf "^c$black^ ^b$darkblue^   "
	printf "^c$black^^b$blue^ $(date '+%d.%m.%y')"
}

while true; do

  [ $interval = 0 ] || [ $(($interval % 3600)) = 0 ] && updates=$(pkg_updates)
  interval=$((interval + 1))

  sleep 1 && xsetroot -name "$updates $(get_volume) $(get_battery) $(get_brightness) $(cpu) $(mem) $(wlan) $(get_date) $(clock)"
done
