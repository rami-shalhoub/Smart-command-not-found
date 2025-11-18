#&###############################################################################
#&                    ______                               _                    #
#&                  .' ____ \                             / |_                  #
#&                  | (___ \_| _ .--..--.   ,--.   _ .--.`| |-'                 #
#&                   _.____`. [ `.-. .-. | `'_\ : [ `/'`\]| |                   #
#&                  | \____) | | | | | | | // | |, | |    | |,                  #
#&                   \______.'[___||__||__]\'-;__/[___]   \__/                  #
#&         ______                                                         __    #
#&       .' ___  |                                                       |  ]   #
#&      / .'   \_|  .--.   _ .--..--.   _ .--..--.   ,--.   _ .--.   .--.| |    #
#&      | |       / .'`\ \[ `.-. .-. | [ `.-. .-. | `'_\ : [ `.-. |/ /'`\' |    #
#&      \ `.___.'\| \__. | | | | | | |  | | | | | | // | |, | | | || \__/  |    #
#&      `.____ .' '.__.' [___||__||__][___||__||__]\'-;__/[___||__]'.__.;__]    #
#&                             ____  _____         _                            #
#&                            |_   \|_   _|       / |_                          #
#&                              |   \ | |   .--. `| |-'                         #
#&                              | |\ \| | / .'`\ \| |                           #
#&                             _| |_\   |_| \__. || |,                          #
#&                            |_____|\____|'.__.' \__/                          #
#&                   ________                               __                  #
#&                  |_   __  |                             |  ]                 #
#&                    | |_ \_|.--.   __   _   _ .--.   .--.| |                  #
#&                    |  _| / .'`\ \[  | | | [ `.-. |/ /'`\' |                  #
#&                   _| |_  | \__. | | \_/ |, | | | || \__/  |                  #
#&                  |_____|  '.__.'  '.__.'_/[___||__]'.__.;__]                 #
#&###############################################################################
#? ──────────────────────────────────────────────────────────--------------------
#? Smart Cross-Distro Command Installer for Zsh
#? Fast search → dynamic package list height + colour
#? ──────────────────────────────────────────────────────────-------------------
#!-------------------------------------------------------------------------------
#!                                        DISCLAIMER 
#!     this plugin was written with the assist of AI, the code has been checked
#!     for malicious activities, and it doesn't collect any data.
#!     In case of a bug, security vulnerability, or user data privacy violation
#!     do not hesitate to submit a pull request
#!-------------------------------------------------------------------------------

PLUGIN_DIR="${0:A:h}"
#^ Import Manager Functions
. "${PLUGIN_DIR}/src/managers/apt.sh"
. "${PLUGIN_DIR}/src/managers/dnf.sh"
. "${PLUGIN_DIR}/src/managers/pacman.sh"
. "${PLUGIN_DIR}/src/managers/aur.sh"
. "${PLUGIN_DIR}/src/managers/zypper.sh"
. "${PLUGIN_DIR}/src/managers/snap.sh"
. "${PLUGIN_DIR}/src/managers/flatpak.sh"
. "${PLUGIN_DIR}/src/managers/homebrew.sh"
. "${PLUGIN_DIR}/src/managers/nix.sh"
. "${PLUGIN_DIR}/src/managers/pip.sh"

#^ Import Rscresults Functions
. "${PLUGIN_DIR}/src/results/display.sh"
. "${PLUGIN_DIR}/src/results/parse.sh"
. "${PLUGIN_DIR}/src/results/install.sh"

# TODO: npm/pnpm/yarm support
MANAGERS=('apt' 'dnf' 'pacman' 'zypper' 'snap' 'flatpak' 'homebrew' 'nix')

autoload -U colors && colors

command_not_found_handler() {
   local cmd="$1"
   found=false
   sources=()

   echo "${fg[blue]}❌ Command '${fg[yellow]}$cmd${fg[blue]}' not found.${reset_color}"
   echo
   while true; do
      # Read a single keypress into 'reply' with a prompt, then print a newline
      read -k1 "reply?${fg[magenta]}Would you like to search for available packages? (Y/n) ${reset_color}"
      echo
      case $reply in
         [yY]) break ;;
         [nN]) echo "${fg[magenta]}Skipped installation.${reset_color}"; return 127 ;;
         *) ;;
      esac
   done


   echo "${fg[magenta]}🔍 Searching available package managers...${reset_color}"

   # ──────────────────────────────────────────────────────────
   #		Package Manager Searches  
   # ──────────────────────────────────────────────────────────
   managers=("${MANAGERS[@]}")

   for manager in "${managers[@]}"; do
      # First construct the function name
      get_"${manager}"_packages "$cmd"   
   done


   # ──────────────────────────────────────────────────────────
   #		Results  
   # ──────────────────────────────────────────────────────────
   $found || { echo "${fg[red]}No available sources found for '${cmd}'.${reset_color}"; return 127; }

   echo
   while true; do
      # Read a single keypress into 'reply' with a prompt, then print a newline
      read -k1 "reply?💡 Would you like to install '${cmd}'? (Y/n) "
      echo
      case $reply in
         [yY]) break ;;
         [nN]) echo "${fg[magenta]}Skipped installation.${reset_color}"; return 0 ;;
         *) ;;
      esac
   done

   # ──────────────────────────────────────────────────────────
   #		Package Display
   # ──────────────────────────────────────────────────────────
   chosen=""
   display_packages "$cmd" || return 0

   # ──────────────────────────────────────────────────────────
   #		Package Selection Parsing
   # ──────────────────────────────────────────────────────────
   selected_manager=""
   selected_package=""
   parse_package_selection "$chosen" || return 1

   # ──────────────────────────────────────────────────────────
   #		Package Installation
   # ──────────────────────────────────────────────────────────
   install_package "$selected_manager" "$selected_package"
}