#!/bin/bash

#         =======================================================================
#                              Arch GNU/Linux update script.
#         Author: SandfordAE
#         Version: 2.4
#         =======================================================================


#         An Arch update script designed to automate as much of the process of
#         updating Arch without blindly agreeing to every update.

#         1. Soft Dependency Checks: Gracefully checks for optional tools (yay,
#            reflector, npm, docker) and skips corresponding steps with warning
#            messages if they are not installed.

#         2. Mirrorlist Optimization: Asks which countries' mirrors you would like to
#            use, then automatically uses reflector to find the top 10 fastest HTTPS
#            mirrors in the configured country and saves them to
#            /etc/pacman.d/mirrorlist.

#         3. Pacman Synchronization & Upgrade: Refreshes package databases
#            (sudo pacman -Syy) and updates official repositories (sudo pacman -Syu).

#         4. AUR Updates: Updates AUR packages using yay, offering standard yay prompt
#            options for package differences and clean builds.

#         5. Gemini CLI Update: Checks for and applies updates to the global
#            @google/gemini-cli package via npm if a newer version is available.

#         6. Docker Container Updates: Uses Watchtower to check for and pull
#            latest images for running containers, recreating them gracefully.

#         7. Cache Cleanup: Cleans up the package cache using paccache -r (if available),
#            falling back to "sudo pacman -Sc --noconfirm".

#         8. Re-synchronization & Summary: Refreshes databases once more and shows a
#            system-wide package status summary using "yay -Ps" (if yay is available).






# --- Colors ---

COLOR_RESET='\e[0m'

COLOR_BLUE='\e[1;94m'
COLOR_GREEN='\e[1;92m'
COLOR_RED='\e[1;91m'
COLOR_WHITE='\e[1;97m'
COLOR_YELLOW='\e[1;33m'





# --- Helper Functions / Print Statements ---

print_step() {
    echo -e "${COLOR_RED}==> ${COLOR_BLUE}$1${COLOR_RED} <== ${COLOR_RESET}"
}


print_success() {
    echo -e "${COLOR_GREEN}<== SUCCESS ==>  ${COLOR_WHITE}$1${COLOR_RESET}"
}


print_running() {
    echo -e "${COLOR_YELLOW}RUNNING COMMAND:${COLOR_WHITE} $1${COLOR_YELLOW} ${COLOR_RESET}"
}


print_warning() {
    echo -e "${COLOR_YELLOW}==> WARNING: $1${COLOR_RESET}"
}


print_error() {
    echo -e "${COLOR_RED}==> ERROR: $1${COLOR_RESET}" >&2
    exit 1
}






# --- Dependency Check ---

check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed. Please install it to continue."
    fi
}


# --- Configuration ---



#            If you run the command:
#            " reflector --list-countries | { read -r header; echo '$header'; sort -bnr -k 3; } "
#            You will be given a list of mirror servers.
#            Then select your mirror via Country or Code.


#            ***EXAMPLE***
#            -------------------- ---- -----
#            Country              Code Count
#            -------------------- ---- -----
#            United States          US   197
#            Germany                DE   151
#            France                 FR    62
#            Netherlands            NL    52
#            Canada                 CA    44
#            United Kingdom         GB    34
#            Sweden                 SE    29
#            Switzerland            CH    25
#            Finland                FI    19
#            Portugal               PT    14
#            Spain                  ES     9
#            -------------------- ---- -----



DEFAULT_COUNTRY="GB"




# --- Functions ---


update_mirrorlist() {
    local country="$1"
    print_step "Optimizing the (Country: ${country}) mirrorlist"
    echo
    print_running "sudo reflector --country '${country}' --latest 10 --protocol https --sort rate"
    echo
    sudo reflector --country "${country}" --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || print_error "Failed to update pacman mirrorlist."
    echo
}



prompt_mirror_optimization() {
    local opt_mirrors
    local selected_country

    if ! command -v reflector &> /dev/null; then
        print_warning "reflector is not installed. Skipping mirrorlist optimization."
        echo
        return
    fi

    # Ask the user, defaulting to No (N)
    read -t 5 -rp "Optimize pacman mirrorlist? [y/N]: " opt_mirrors
    opt_mirrors=${opt_mirrors:-N}
    echo

    # Ask the user which mirror they wish to use
    if [[ "$opt_mirrors" =~ ^[Yy]$ ]]; then
        read -rp "Choose a source for your mirrorlist:(GB, DE, US, FR) [Default: ${DEFAULT_COUNTRY}]: " selected_country
        selected_country=${selected_country:-$DEFAULT_COUNTRY}
        echo
        update_mirrorlist "$selected_country"
        refresh_pacman
    else
        echo
        print_warning "Skipping mirrorlist optimization."
    fi
}




update_pacman() {
    print_step "Synchronizing pacman package databases and updating system..."
    echo
    print_running "sudo pacman -Syu"
    echo
    sudo pacman -Syu || print_error "Failed to update pacman packages."
    echo
    print_success "Pacman packages updated successfully."
}




update_yay() {
    if command -v yay &> /dev/null; then
        print_step "Updating AUR packages with yay..."
        echo
        print_running "yay -Syu"
        echo
        yay -Syu || print_error "Failed to update AUR packages."
        echo
        print_success "AUR packages updated successfully."
    else
        print_warning "yay is not installed. Skipping AUR package updates."
    fi
}




update_gemini_cli() {
    if ! command -v npm &> /dev/null; then
        print_warning "npm is not installed. Skipping Gemini CLI update."
        return
    fi

    # Check if Gemini CLI is installed globally
    if ! npm list -g @google/gemini-cli --depth=0 &>/dev/null; then
        print_warning "Gemini CLI is not installed globally. Skipping update."
        return
    fi

    print_step "Checking for Gemini CLI updates..."
    echo

    # Check if an update is available
    if npm outdated -g @google/gemini-cli | grep -q "@google/gemini-cli"; then
        print_running "sudo npm install -g @google/gemini-cli@latest"
        echo
        sudo npm install -g @google/gemini-cli@latest || print_warning "Failed to update Gemini CLI."
        echo
        print_success "Gemini CLI updated successfully."
    else
        print_success "Gemini CLI is already up to date."
    fi
}




update_docker_containers() {
    # Check if docker command is available
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. Skipping container updates."
        return
    fi

    # Check if docker daemon is running
    if ! systemctl is-active --quiet docker; then
        print_warning "Docker daemon is not running. Skipping container updates."
        return
    fi

    local update_docker
    read -t 5 -rp "Update Docker/Portainer containers with Watchtower? [y/N]: " update_docker
    update_docker=${update_docker:-N}
    echo

    if [[ "$update_docker" =~ ^[Yy]$ ]]; then
        # Dynamically fetch the current Docker API version
        local docker_api_version
        docker_api_version=$(docker version -f '{{.Server.APIVersion}}')

        print_step "Updating Docker containers and Portainer stacks (API: ${docker_api_version})..."
        echo
        print_running "docker run --rm -e DOCKER_API_VERSION=${docker_api_version} -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once --cleanup"
        echo

        docker run --rm \
          -e DOCKER_API_VERSION="${docker_api_version}" \
          -v /var/run/docker.sock:/var/run/docker.sock \
          containrrr/watchtower --run-once --cleanup || print_warning "Failed to update some Docker containers."

        echo
        print_success "Docker container and stack updates complete."
    else
        echo
        print_warning "Skipping Docker container updates."
    fi
}





clean_cache() {
    print_step "Cleaning up package cache..."
    if command -v paccache &> /dev/null; then
        echo
        print_running "sudo paccache -r"
        echo
        sudo paccache -r || print_warning "Failed to clean package cache with paccache."
    else
        echo
        print_running "pacman -Sc --noconfirm"
        echo
        print_warning "'paccache' is not installed. Skipping smart cache cleaning."
        echo
        print_step "Running 'pacman -Sc' instead. This will remove all uninstalled packages from the cache."
        sudo pacman -Sc --noconfirm
    fi
    echo
    print_success "Package cache cleaned."
}





refresh_pacman() {
    print_step "Synchronizing pacman package databases to confirm updating"
    echo
    print_running "sudo pacman -Syy"
    echo
    sudo pacman -Syy || print_error "Failed to refresh pacman."
    echo
    print_success "Pacman package list refreshed successfully."
}





show_summary() {
    print_step "Displaying update summary..."
    echo
    if command -v yay &> /dev/null; then
        print_running "yay -Ps"
        echo
        yay -Ps
    else
        print_warning "yay is not installed. Cannot display detailed AUR/system summary."
    fi
    echo
    print_success "System update and optimization complete."
}







# --- Script ---


main() {

    print_step "Starting Arch update script..."
    echo

    prompt_mirror_optimization
    echo

    update_pacman
    echo

    update_yay
    echo

    update_gemini_cli
    echo

    update_docker_containers
    echo

    clean_cache
    echo

    refresh_pacman
    echo

    show_summary
    echo

}


main
