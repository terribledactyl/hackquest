# HackQuest v0.1-Alpha

Description:
  HackQuest is a gamified enumeration and exploitation script for penetration testers.
  It automates network discovery, scanning, and exploitation tasks while providing
  an interactive menu-driven interface. It's meant to be used in the context of a 
  Raspberry Pi with GameBoy-style inputs (i.e. A + B buttons, D-Pad). WIP

Usage:
  sudo ./hackquest.sh

Requirements:
  - Must be run as root.
  - Required tools: ip, netdiscover, nmapAutomator (modded for ffuf), metasploit console, alsa-utils.

Features:
  - Discover hosts on the network.
  - Perform detailed scans using nmapAutomator.
  - Manage and read scan results.
  - Launch shells and exploit sessions via Meterpreter.

Menu Options:
  1. Basic Network Info         Display IP, hostname, and default gateway.
  2. Discover Hosts             Discover active hosts on the network.
  3. List Known Hosts           View hosts discovered during the session.
  4. PSR Scan Hosts             Run port, service, and recon scans on discovered hosts.
  5. Read PSR Results           Browse and view saved PSR Scan results.
  6. Launch Shell               Open an interactive shell.
  7. Launch Meterpreter         Start Meterpreter console (requires msfconsole).
  8. Help                       Show this menu.

Notes:
  - Ensure all required tools are installed and in the PATH.
  - The startup audio file must be in the same directory as HackQuest.
