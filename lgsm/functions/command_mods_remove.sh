#!/bin/bash
# LGSM command_mods_uninstall.sh function
# Author: Daniel Gibbs
# Contributor: UltimateByte
# Website: https://gameservermanagers.com
# Description: Uninstall mods along with mods_list.sh and mods_core.sh.

local commandname="MODS"
local commandaction="addons/mods"
local function_selfname="$(basename $(readlink -f "${BASH_SOURCE[0]}"))"

check.sh
mods_core.sh
fn_mods_check_installed

fn_print_header
echo "Remove addons/mods"
echo "================================="

## Displays list of installed mods
# Generates list to display to user
fn_mods_installed_list
for ((mlindex=0; mlindex < ${#installedmodslist[@]}; mlindex++)); do
	# Current mod is the "mlindex" value of the array we are going through
	currentmod="${installedmodslist[mlindex]}"
	# Get mod info
	fn_mod_get_info
	# Display mod info to the user
	echo -e "${cyan}${modcommand}${default} - \e[1m${modprettyname}${default} - ${moddescription}"
done

echo ""
# Keep prompting as long as the user input doesn't correspond to an available mod
while [[ ! " ${installedmodslist[@]} " =~ " ${usermodselect} " ]]; do
	echo -en "Enter an ${cyan}addon/mod${default} to ${green}install${default} (or exit to abort): "
	read -r usermodselect
	# Exit if user says exit or abort
	if [ "${usermodselect}" == "exit" ]||[ "${usermodselect}" == "abort" ]; then
			core_exit.sh
	# Supplementary output upon invalid user input
	elif [[ ! " ${availablemodscommands[@]} " =~ " ${usermodselect} " ]]; then
		fn_print_error2_nl "${usermodselect} is not a valid addon/mod."
	fi
done

fn_print_warning_nl "You are about to remove ${cyan}${usermodselect}${default}."
echo " * Any custom files/configuration will be removed."
while true; do
	read -e -i "y" -p "Continue? [Y/n]" yn
	case $yn in
	[Yy]* ) break;;
	[Nn]* ) echo Exiting; exit;;
	* ) echo "Please answer yes or no.";;
esac
done

currentmod="${usermodselect}"
fn_mod_get_info
fn_check_mod_files_list

# Uninstall the mod
fn_script_log "Removing ${modsfilelistsize} files from ${modprettyname}"
echo -e "removing ${modprettyname}"
echo -e "* ${modsfilelistsize} files to be removed"
echo -e "* location: ${modinstalldir}"
sleep 1
# Go through every file and remove it
modfileline="1"
tput sc
while [ "${modfileline}" -le "${modsfilelistsize}" ]; do
	# Current line defines current file to remove
	currentfileremove="$(sed "${modfileline}q;d" "${modsdir}/${modcommand}-files.txt")"
	# If file or directory exists, then remove it
	fn_script_log "Removing: ${modinstalldir}/${currentfileremove}"
	if [ -f "${modinstalldir}/${currentfileremove}" ]||[ -d "${modinstalldir}/${currentfileremove}" ]; then
		rm -rf "${modinstalldir}/${currentfileremove}"
		local exitcode=$?
	fi
	tput rc; tput el
	printf  "removing ${modprettyname} ${modfileline} / ${modsfilelistsize} : ${currentfileremove}..."
	((modfileline++))
done
tput rc; tput ed;
echo -ne "sed ${modprettyname} ${modfileline} / ${modsfilelistsize}..."
if [ ${exitcode} -ne 0 ]; then
	fn_print_fail_eol_nl
	core_exit.sh
else
	fn_print_ok_eol_nl
fi
sleep 0.5

# Remove file list
echo -en "removing ${modcommand}-files.txt..."
sleep 0.5
fn_script_log "Removing: ${modsdir}/${modcommand}-files.txt"
rm -rf "${modsdir}/${modcommand}-files.txt"
local exitcode=$?
if [ ${exitcode} -ne 0 ]; then
	fn_print_fail_eol_nl
	core_exit.sh
else
	fn_print_ok_eol_nl
fi

# Remove mods from installed mods list
echo -en "removing ${modcommand} from ${modslockfile}..."
sleep 0.5
fn_script_log "Removing: ${modcommand} from ${modsinstalledlist}"
sed -i "/^${modcommand}$/d" "${modsinstalledlistfullpath}"
local exitcode=$?
if [ ${exitcode} -ne 0 ]; then
	fn_print_fail_eol_nl
	core_exit.sh
else
	fn_print_ok_eol_nl
fi

# Oxide fix
# Oxide replaces server files, so a validate is required after uninstall
if [ "${engine}" == "unity3d" ]&&[[ "${modprettyname}" == *"Oxide"* ]]; then
	fn_print_information_nl "Validating to restore original ${gamename} files replaced by Oxide"
	fn_script_log "Validating to restore original ${gamename} files replaced by Oxide"
	exitbypass="1"
	command_validate.sh
	unset exitbypass
fi
echo "${modprettyname} removed"
fn_script_log "${modprettyname} removed"

core_exit.sh
