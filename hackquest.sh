#!/bin/bash

#requirements - ip, netdiscover, nmapautomator (modded for ffuf), metasploit console, alsa-utils (audio)

show_help() {
    echo "=================================="
    echo " HackQuest v0.1-Alpha - Help Menu"
    echo "=================================="
    echo "Description:"
    echo "  HackQuest is a gamified enumeration and exploitation script for penetration testers."
    echo "  It automates network discovery, scanning, and exploitation tasks while providing"
    echo "  an interactive menu-driven interface."
    echo
    echo "Usage:"
    echo "  sudo ./hackquest.sh"
    echo
    echo "Requirements:"
    echo "  - Must be run as root."
    echo "  - Required tools: ip, netdiscover, nmapAutomator (modded for ffuf), metasploit console, alsa-utils."
    echo
    echo "Features:"
    echo "  - Discover hosts on the network."
    echo "  - Perform detailed scans using nmapAutomator."
    echo "  - Manage and read scan results."
    echo "  - Launch shells and exploit sessions via Meterpreter."
    echo
    echo "Menu Options:"
    echo "  1. Basic Network Info         Display IP, hostname, and default gateway."
    echo "  2. Discover Hosts             Discover active hosts on the network."
    echo "  3. List Known Hosts           View hosts discovered during the session."
    echo "  4. PSR Scan Hosts		Run port, service, and recon scans on discovered hosts."
    echo "  5. Read PSR Results           Browse and view saved PSR Scan results."
    echo "  6. Launch Shell               Open an interactive shell."
    echo "  7. Launch Meterpreter         Start Meterpreter console (requires msfconsole)."
    echo "  8. Help                       Show this menu."
    echo
    echo "Notes:"
    echo "  - Ensure all required tools are installed and in the PATH."
    echo "  - The startup audio file must be in the same directory as HackQuest."
    echo
    echo "=================================="
}

# Function to ensure the script is run as root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "This script must be run as root. Please re-run with sudo or as the root user."
        exit 1
    fi
}
# Function to play audio when the script starts
play_startup_sound() {
    local audio_file="$PWD/startup.wav" # Replace with the path to your audio file

    # Check if the audio file exists
    if [[ -f "$audio_file" ]]; then
        # Play the audio file (using aplay, paplay, or another player)
        aplay "$audio_file" &>/dev/null & # Replace 'aplay' with your audio player if necessary
    else
        echo "Audio file not found: $audio_file"
    fi
}

# Menu items
MENU=("Select Interface" "Basic Network Info" "Discover Hosts" "List Known Hosts" "PSR Scan Hosts" "Read PSR Results" "Launch Shell (KB Required)" "Launch Meterpreter (KB Required)" "Help" "Exit")

# Function to display the menu with highlighting
show_menu() {
    clear
    echo "=========================="
    echo " HackQuest v0.1-Alpha "
    echo "=========================="
    for i in "${!MENU[@]}"; do
        if [[ $i -eq $CURRENT ]]; then
            # Highlight the selected option
            echo -e "\e[1;32m> ${MENU[i]}\e[0m"
        else
            echo "  ${MENU[i]}"
        fi
    done
}

# Function to select a network interface using arrow keys
select_interface() {
    local interfaces=($(ip -o link show | awk -F': ' '{print $2}')) # Get a list of network interfaces
    local current=0

    while true; do
        clear
        echo "=========================="
        echo " Select Network Interface "
        echo "=========================="
        for i in "${!interfaces[@]}"; do
            if [[ $i -eq $current ]]; then
                echo -e "\e[1;32m> ${interfaces[i]}\e[0m"  # Highlight the current selection
            else
                echo "  ${interfaces[i]}"
            fi
        done
        echo "=========================="
        echo "Use Up/Down arrows to navigate and Enter to select."

        # Read user input
        read -rsn1 key
        case "$key" in
            $'\x1b')  # Escape sequence
                read -rsn2 -t 0.1 key
                case "$key" in
                    "[A")  # Up arrow
                        ((current--))
                        if [[ $current -lt 0 ]]; then
                            current=$((${#interfaces[@]} - 1))
                        fi
                        ;;
                    "[B")  # Down arrow
                        ((current++))
                        if [[ $current -ge ${#interfaces[@]} ]]; then
                            current=0
                        fi
                        ;;
                esac
                ;;
            "")  # Enter key
                echo "Selected Interface: ${interfaces[current]}"
                SELECTED_INTERFACE="${interfaces[current]}"  # Set the selected interface as a global variable
                break
                ;;
        esac
    done
}


# Basic Network Functions
get_current_ip() {
	ip -o -f inet addr show $SELECTED_INTERFACE | awk '{print $4}' | cut -d'/' -f1
}

get_default_gateway() {
	ip route show dev $SELECTED_INTERFACE | grep default | awk '{print $3}'
}

# NetDiscover Enumeration
netdiscover_enum() {
	discovered_hosts=$(timeout 15 sudo netdiscover -i $SELECTED_INTERFACE -P | grep -oP '\d+\.\d+\.\d+\.\d+')
}

# NmapAutomator Full Scan - Ports and Services
nmap_full_enum() {
	for ip in $discovered_hosts; do
        	echo "Running nmapAutomator for IP: $ip"
        
        # Run nmapAutomator for the current IP
        nmapAutomator -T All -H "$ip" >"${ip}_nmapAutomator.txt"
        
        if [ $? -eq 0 ]; then
            echo "Results saved to ${ip}_nmapAutomator.txt"
        else
            echo "nmapAutomator failed for IP: $ip"
        fi
    done
}

# NmapAutomator file read
# Function to handle file selection and reading
read_file_menu() {
    # Filter files containing "nmapAutomator.txt"
    local files=($(ls | grep -F "nmapAutomator.txt"))
    
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No files containing 'nmapAutomator.txt' found in the current directory."
        read -p "Press Enter to return to the main menu..."
        return
    fi

    local file_current=0

    while true; do
        clear
        echo "=========================="
        echo " Nmap Files "
        echo "=========================="
        for i in "${!files[@]}"; do
            if [[ $i -eq $file_current ]]; then
                echo -e "\e[1;32m> ${files[i]}\e[0m"
            else
                echo "  ${files[i]}"
            fi
        done
        echo "=========================="
        echo "Use Up/Down arrows to navigate, Enter to read a file, or 'B' to go back."

        # Read user input
        read -rsn1 key
        case "$key" in
            $'\x1b')  # Escape sequence
                read -rsn2 -t 0.1 key
                case "$key" in
                    "[A")  # Up arrow
                        ((file_current--))
                        if [[ $file_current -lt 0 ]]; then
                            file_current=$((${#files[@]} - 1))
                        fi
                        ;;
                    "[B")  # Down arrow
                        ((file_current++))
                        if [[ $file_current -ge ${#files[@]} ]]; then
                            file_current=0
                        fi
                        ;;
                esac
                ;;
            "")  # Enter key
                clear
                echo "Contents of '${files[file_current]}':"
                if [[ -f "${files[file_current]}" ]]; then
                    more "${files[file_current]}"
                else
                    echo "Not a regular file or unable to read."
                fi
                read -p "Press Enter to return to the file list..."
                ;;
            "b")  # Back to main menu
                break
                ;;
        esac
    done
}

# Function to handle user selection
process_choice() {
    case $CURRENT in
        0) 
            select_interface
            ;;
        1)
            if [ -z "$SELECTED_INTERFACE" ]; then
            	printf "\nNo interface set! Use \"Select Interface\" function first.\n"
            else
            printf "\nCurrent IP: "
            get_current_ip
            printf "Hostname: "
            hostname
            printf "Default Gateway: "
            get_default_gateway
            printf "\n"
            fi
            ;;
        2)
            if [ -z "$SELECTED_INTERFACE" ]; then
            	printf "\nNo interface set! Use \"Select Interface\" function first.\n"
            else
            printf "\nDiscovering Hosts, please wait..."
            netdiscover_enum
            printf "\nDone! Use \"List Known Hosts\" to view hosts.\n"
            fi
            ;;
        3)
            if [ -z "$discovered_hosts" ]; then
            	printf "\nNothing discovered yet! Use \"Discover Hosts\" function first.\n"
            else
            	echo "Known Hosts: "
            	echo "$discovered_hosts"
            fi
            ;;
        4)
            if [ -z "$discovered_hosts" ]; then
            	printf "\nNothing discovered yet! Use \"Discover Hosts\" function first.\n"
            else
            	echo "Scanning Known Hosts..."
            	nmap_full_enum
            fi
            ;;
        5)
            read_file_menu
            ;;
        6)
       	    /bin/bash -p
       	    ;; 
       	7)
       	    msfconsole && init msfdb
       	    ;;
       	8)
       	    show_help | more
       	    ;;
        9)
            echo "Exiting HackQuest... Goodbye!"
            exit 0
            ;;
    esac
    read -p "Press Enter to return to the menu..."
}

# Main script
check_root
play_startup_sound
CURRENT=0
while true; do
    show_menu

    # Read user input
    read -rsn1 key  # Capture single keypress
    case "$key" in
        $'\x1b')  # Escape sequence
            read -rsn2 -t 0.1 key  # Read next two characters
            case "$key" in
                "[A")  # Up arrow
                    ((CURRENT--))
                    if [[ $CURRENT -lt 0 ]]; then
                        CURRENT=$((${#MENU[@]} - 1))
                    fi
                    ;;
                "[B")  # Down arrow
                    ((CURRENT++))
                    if [[ $CURRENT -ge ${#MENU[@]} ]]; then
                        CURRENT=0
                    fi
                    ;;
            esac
            ;;
        "")  # Enter key
            process_choice
            ;;
    esac
done
