#!/bin/sh

state_file=/proc/acpi/button/lid/LID/state
wallpaper="$HOME/.config/hypr/wallpaper.png"
last_state=
last_outputs=

set_wallpapers() {
	result=0
	for output in $1; do
		hyprctl hyprpaper wallpaper "$output,$wallpaper,cover" || result=1
	done
	return "$result"
}

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/hypr-lid-monitor.lock"
flock -n 9 || exit 0

while true; do
	if read -r _ state < "$state_file" && [ "$state" != "$last_state" ]; then
		if [ "$state" = "closed" ]; then
			hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'
		else
			hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.5, disabled = false })'
		fi

		last_state=$state
	fi

	outputs=$(hyprctl monitors -j | jq -r '.[].name')
	if [ "$outputs" != "$last_outputs" ]; then
		sleep 0.2
		if set_wallpapers "$outputs"; then
			last_outputs=$outputs
		fi
	fi

	sleep 1
done
