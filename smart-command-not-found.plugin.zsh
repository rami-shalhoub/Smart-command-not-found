# ────────────────────────────────────────────────
# Smart Cross-Distro Command Installer for Zsh
# Fast search → dynamic package list height + colour
# ────────────────────────────────────────────────
#!-------------------------------------------------------------------------------------
#! Disclaimer: this plugin was written with the assist of AI, the code has been checked
#!             for malicious activities, and it doesn't collect any data.
#!             In case of a bug, security vulnerability, or user data privacy violation
#!             do not hesitate to submit a pull request
#!-------------------------------------------------------------------------------------

   autoload -U colors && colors

command_not_found_handler() {
local cmd="$1"
local found=false
local sources=()
local sep="${fg[cyan]}──────────────────────────────${reset_color}"

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

# ─── APT ─────────────────────────────
if command -v apt-cache &>/dev/null; then
   local apt_result
   apt_result=$(apt-cache search "^${cmd}$" 2>/dev/null || apt-cache search "$cmd" 2>/dev/null)
   [ -n "$apt_result" ] && echo "  ${fg[green]}✔ Found in APT${reset_color}" && sources+=("APT::$apt_result") && found=true
fi

# ─── DNF ─────────────────────────────
if command -v dnf &>/dev/null; then
   local dnf_result
   dnf_result=$(dnf search "$cmd" 2>/dev/null | grep -E '^[[:alnum:]-]+\.' | head -n 20)
   [ -n "$dnf_result" ] && echo "  ${fg[green]}✔ Found in DNF${reset_color}" && sources+=("DNF::$dnf_result") && found=true
fi

# ─── Pacman ──────────────────────────  
if command -v pacman &>/dev/null; then
   local pac_result
   pac_result=$(pacman -Ss "$cmd" 2>/dev/null | grep -E '^[a-z0-9/]+ ' | head -n 20)
   [ -n "$pac_result" ] && echo "  ${fg[green]}✔ Found in Pacman${reset_color}" && sources+=("Pacman::$pac_result") && found=true
fi

# ─── Zypper ──────────────────────────
if command -v zypper &>/dev/null; then
   local zyp_result
   zyp_result=$(zypper search "$cmd" 2>/dev/null | grep -E '^[[:space:]]*[il-] |^[[:space:]]*[|] ')
   [ -n "$zyp_result" ] && echo "  ${fg[green]}✔ Found in Zypper${reset_color}" && sources+=("Zypper::$zyp_result") && found=true
fi

# ─── Homebrew ────────────────────────
if command -v brew &>/dev/null; then
   local brew_result
   brew_result=$(brew search "$cmd" 2>/dev/null | head -n 20)
   [ -n "$brew_result" ] && echo "  ${fg[green]}✔ Found in Homebrew${reset_color}" && sources+=("Homebrew::$brew_result") && found=true
fi

# ─── Flatpak ─────────────────────────
if command -v flatpak &>/dev/null; then
   local flat_result
   flat_result=$(flatpak search "$cmd" 2>/dev/null | head -n 20)
   if [[ -n "$flat_result" ]] && ! echo "$flat_result" | grep -qi "no matches\|not found\|error"; then
      echo "  ${fg[green]}✔ Found in Flatpak${reset_color}" && sources+=("Flatpak::$flat_result") && found=true
   fi
fi

# ─── Snap ────────────────────────────
if command -v snap &>/dev/null; then
   local snap_result
   snap_result=$(snap find "$cmd" 2>/dev/null | head -n 20)
   [ -n "$snap_result" ] && echo "  ${fg[green]}✔ Found in Snap${reset_color}" && sources+=("Snap::$snap_result") && found=true
fi

# ─── NIX ─────────────────────────────
if command -v nix-env &>/dev/null; then
   local nix_result
   nix_result=$(nix-env -qaP "$cmd" 2>/dev/null | head -n 20)
   [ -n "$nix_result" ] && echo "  ${fg[green]}✔ Found in Nix${reset_color}" && sources+=("Nix::$nix_result") && found=true
fi

# ─── Results ─────────────────────────

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

echo "${fg[blue]}📦 Package list...${reset_color}"

local package_list=""
for src in "${sources[@]}"; do
   local pm="${src%%::*}"
   local data="${src#*::}"
   while IFS= read -r line; do
      # Only process non-empty lines and remove any trailing whitespace
      if [[ -n "${line// }" ]]; then
      package_list+="${fg[green]}$pm${reset_color} → ${fg[yellow]}$line${reset_color}\n"
      fi
   done <<< "$data"
done

local line_count
line_count=$(echo -e "$package_list" | wc -l)
local height

# Dynamically adjust fzf height based on content and terminal size
local term_height=$(tput lines)
local min_height=8  # Minimum height in lines
local max_lines=$(( term_height * 80 / 100 ))  # Max 80% of terminal height
local content_lines=$(( line_count + 4 ))  # Add space for borders and prompts

# Calculate ideal height in lines
if (( content_lines < min_height )); then
   content_lines=$min_height
elif (( content_lines > max_lines )); then
   content_lines=$max_lines
fi

# Convert to percentage of terminal height
local pct=$(( content_lines * 100 / term_height ))
height="${pct}%"

# TODO: add dynamic number changing based on where the pointer is in the list e.g. 1/9 2/9 ...
local chosen
if command -v fzf &>/dev/null; then
   package_list=$(echo -e "$package_list" | sed '/^[[:space:]]*$/d')
   chosen=$(echo -e "$package_list" | fzf --ansi --prompt="📦 Select package to install: " \
    --height="$height" --border --header="Results for '$cmd'")
else
   echo -e "$package_list"
   echo -n "Enter the package name to install: "
   read chosen
fi

[[ -z "$chosen" ]] && { echo "${fg[red]}❌ No package selected.${reset_color}"; return 0; }

# ────Package Selection Parsing─────────────────────────────
local manager package
# Extract manager (first word before the arrow)
manager=$(echo "$chosen" | grep -o '^[A-Za-z]*' | head -1)

# Remove ANSI color codes and manager prefix
local clean_chosen=$(echo "$chosen" | sed -E 's/^[A-Za-z]+ → //' | sed -E 's/\x1B\[[0-9;]*[mGK]//g')

# Extract package name based on package manager format
case "$manager" in
    APT)
        # APT: "package - description" → take first word
        package=$(echo "$clean_chosen" | awk '{print $1}')
        ;;
    DNF)
        # DNF: "package.arch description" → take first word and remove .arch
        package=$(echo "$clean_chosen" | awk '{print $1}' | sed 's/\..*$//')
        ;;
    Pacman)
        # Pacman: "repo/package version description" → take repo/package part
        package=$(echo "$clean_chosen" | awk '{print $1}')
        ;;
    Zypper)
        # Zypper: complex table format - take the package name column
        package=$(echo "$clean_chosen" | awk '{print $2}')
        ;;
    Homebrew)
        # Homebrew: usually just package names
        package=$(echo "$clean_chosen" | awk '{print $1}')
        ;;
    Flatpak)
        # Flatpak: "application ID version branch description" → take application ID
        package=$(echo "$clean_chosen" | awk '{print $1}')
        ;;
    Snap)
        # Snap: "package version developer notes" → take first word
        package=$(echo "$clean_chosen" | awk '{print $1}')
        ;;
    Nix)
        # Nix: "attribute.name package-name-version" → take attribute.name
        package=$(echo "$clean_chosen" | awk '{print $1}')
        ;;
    *)
        # Fallback: take first word
        package=$(echo "$clean_chosen" | awk '{print $1}')
        ;;
esac

# Final cleanup
package=$(echo "$package" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Remove any trailing characters that might cause issues
package=$(echo "$package" | sed 's/[:\/].*$//')

if [[ -z "$manager" || -z "$package" ]]; then
   echo "${fg[red]}❌ Failed to parse package selection.${reset_color}"
   echo "${fg[red]}Debug: manager='$manager', package='$package'${reset_color}"
   return 1
fi

echo "${fg[cyan]}➡ Installing '${fg[yellow]}$package${fg[cyan]}' via ${fg[green]}$manager${reset_color}..."

case "$manager" in
   APT) if command -v nala &>/dev/null; then
          sudo nala install "$package"
        else
          sudo apt install "$package"
        fi ;; 
   DNF) sudo dnf install "$package" ;;
   Pacman) sudo pacman -S "$package" ;;
   Zypper) sudo zypper install "$package" ;;
   Homebrew) brew install "$package" ;;
   Flatpak) flatpak install -y flathub "$package" ;;
   Snap) sudo snap install "$package" ;;
   Nix) nix-env -iA nixpkgs."$package" ;;
   *) echo "${fg[red]}❌ Unsupported package manager: $manager${reset_color}" ;;
esac
}
