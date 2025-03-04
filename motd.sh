#!/usr/bin/env bash

# - iNFO --------------------------------------
#
#   Author: wuseman <wuseman@nr1.nu>
# FileName: wbanner.sh
#  Created: 2023-08-29 (20:28:25)
# Modified: 2023-12-20 (11:50:00)
#  Version: 1.0
#  License: MIT
#
#      iRC: wuseman (Libera/EFnet/LinkNet)
#   GitHub: https://github.com/wuseman/
#
# ---------------------------------------------

message_of_the_day() {
	user="$LOGNAME"
	path="$PWD"
	home="$HOME"

	if [[ ! "$path" == /home* && ! "$path" == /usr/home* ]]; then
		exit 0
	fi

	lastlogin=$(last | head -n1 | awk '{print $3}')
	if [[ "$lastlogin" == ":0" ]]; then
		lastlogin="x11"
	fi

	last_login_ip="$(lastlog -u wuseman | awk 'NR==2{print $3}')"
	last_login_time=$(lastlog -u "$user" | awk 'NR == 2 {print $7}')
	current_date=$(date +"%Y-%m-%d")
	formatted_time=$(date -d "$last_login_time" +"%H:%M:%S" 2>/dev/null)
	formatted_date=$(date -d "$latest_login" +"%Y-%m-%d - %H:%M:%S")
	last_ip_login=$(lastlog -u "$user" | awk '/wuseman/ {print $3}' | tail -n 1)

	uptime=$(cut -d. -f1 /proc/uptime)
	up_days=$((uptime / 60 / 60 / 24))
	up_hours=$((uptime / 60 / 60 % 24))
	up_mins=$((uptime / 60 % 60))
	up_secs=$((uptime % 60))

	psa=$(($(ps -A h | wc -l) - 000))
	psu=$(($(ps U "$user" h | wc -l) - 002))
	verb="are"
	if [ "$psu" -lt 2 ]; then
		if [ "$psu" -eq 0 ]; then
			psu="none"
		else
			verb="is"
		fi
	fi

	loadavg=$(cat /proc/loadavg)
	sysload=($(echo "$loadavg" | awk '{print $1, $2, $3}'))

	memory_info=$(free -m | grep "Mem:")
	used_memory=$(echo "$memory_info" | awk '{print $3}')
	free_memory=$(echo "$memory_info" | awk '{print $4}')
	free_cached_memory=$(echo "$memory_info" | awk '{print $6}')
	used_virtual_memory=$(echo "$memory_info" | awk '{print $5}')
	free_virtual_memory=$(echo "$memory_info" | awk '{print $7}')

	disk_space_info=$(df -h | awk '$NF=="/" {print "Total: " $2, "Used: " $3, "Free: " $4}')
	used_disk_space=$(echo "$disk_space_info" | awk '{print $4}')
	free_disk_space=$(echo "$disk_space_info" | awk '{print $8}')

	ipv6_status=$(cat "/sys/module/ipv6/parameters/disable_ipv6")

	if [ "$ipv6_status" -eq 0 ]; then
		ipv6_message="IPv6: Enable"
	else
		ipv6_message="IPv6: Disable"
	fi

	network_interface=$(route | grep -m1 ^default | awk '{print $NF}')
	network_speed=$(cat "/sys/class/net/$network_interface/speed")
	wan_ip=$(curl -s ifconfig.me)
	lan_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | awk '{print $2}' | grep -v '127.0.0.1' | head -n1)
	if [ -n "$wan_ip" ]; then
		wanip="$wan_ip"
	else
		wanip="Offline"
	fi

	if [ -n "$lan_ip" ]; then
		lanip="$lan_ip"
	else
		lanip="Offline"
	fi

	if [ -n "$DISPLAY" ] && [ -t 1 ]; then
		gpu_info=$(glxinfo | grep "OpenGL renderer string")
		gpu_info=${gpu_info#*: }
		gpu_mem="$(glxinfo | grep -iP -o "(?<=Video memory: )\d+MB")"
	fi

	cpu_model=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | cut -d ':' -f 2 | sed -e 's/^[ \t]*//')
	cpu_architecture=$(uname -m)
	cpu_cores=$(nproc)
	if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq" ] && [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq" ]; then
		max_cpu_frequency=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq")
		current_cpu_frequency=$(cat "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq")
	else
		max_cpu_frequency="N/A"
		current_cpu_frequency="N/A"
	fi

	cpu_generation=$(awk -F ': | ' '/cpu family/ {print $3 "th"; exit}' /proc/cpuinfo)
	cache_size=$(awk '/cache size/ {print $4/1024 " MB"; exit}' /proc/cpuinfo)
	cpu_mhz=$(awk '/cpu MHz/ {print $4; exit}' /proc/cpuinfo)

	print_info() {
		info_name="$1:"
		info_value="$2"
		padding_length=$((16 - ${#info_name}))
		padding_dots=$(printf '%*s' "$padding_length" | tr ' ' '.')
		echo -e "  \033[35m$info_name\033[0m\033[36m $padding_dots\033[0m \033[36m$info_value\033[0m"
	}

	print_header_if_possible() {
		if command -v figlet >/dev/null 2>&1; then
			# Figlet is installed, create and print the header.
			local header
			#    header=$(figlet "$user")
			header=$(figlet "  $HOSTNAME")
			echo -e "\033[01;32m${header}\033[0m\n"
		fi
	}

	print_header_if_possible "$user"

	print_info "CPU" "$cpu_model ($cpu_architecture, $cpu_cores cores, $cpu_generation generation)"
	print_info "CPU Load" "${sysload[0]} (1 minute) ${sysload[1]} (5 minutes) ${sysload[2]} (15 minutes)"
	print_info "Disk Space" "$disk_space_info"
	if [ -n "$DISPLAY" ] && [ -t 1 ]; then
		print_info "GPU Info" "$gpu_info (Virtual Memory: $gpu_mem)"
	fi
	print_info "Last Login" "$current_date / $formatted_time from $last_login_ip"
	print_info "Memory" "Used: $used_memory MB  Free: $free_memory MB  Free Cached: $free_cached_memory MB"
	if [ -n "$used_virtual_memory" ] && [ "$used_virtual_memory" != "0" ]; then
		print_info "Virtual Memory" "Used: $used_virtual_memory MB  Free: $free_virtual_memory MB"
	fi

	print_info "Network Info" "NIC: $network_interface Speed: $network_speed ($ipv6_message) ($wanip/$lanip)"
	print_info "Processes" "$psa total running, $psu $verb yours"
	print_info "Uptime" "${up_days} days ${up_hours} hours ${up_mins} minutes ${up_secs} seconds"
	echo
}

message_of_the_day
