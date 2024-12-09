#!/bin/bash



 
echo
echo '-=-=-=-=-=-=-=-=-=-=-=-=-=-=|    Update all Pacman and AUR packages    |-=-=-=-=-=-=-=-=-=-=-=-=-='
echo
echo
echo '||>>>  STEP 1/6    ||  Running "pacman -Syy" to update/synchronize the package list.         <<<||'
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo
# Update the package lists
sudo pacman -Syy
echo
echo
echo '||>>>  STEP 2/6    ||  Running "pacman -Syu --noconfirm" to upgade any installed packages.   <<<||'
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo
# Upgrade installed packages
sudo pacman -Syu --noconfirm
echo
echo
echo '||>>>  STEP 3/6    ||  Running "pacman -Scc --noconfirm" to remove any unused packages.      <<<||'
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
# Remove unused packages
sudo pacman -Scc --noconfirm
echo
echo
echo '||>>>  STEP 4/6    ||  Running "pacman -Syy" to synchronize the package list again.          <<<||'
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo
# Synchronize the package databases again
sudo pacman -Syy
echo
echo
echo '||>>>  STEP 5/6    ||  Running "yay -Syu --noconfirm" to update any existing Yay packages.   <<<||'
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo
# Update all yay packages
yay -Syu --noconfirm
echo
echo
echo '||>>>  STEP 6/6    ||  Running "yay -Ps" to display all existing and updated packages.       <<<||'
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo
# Show statistics for installed packages and system health
yay -Ps
echo
echo
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
echo '||>>>  COMPLETED !  ||   Arch has been "Optimized" and "Updated" successfully.               <<<||'
echo "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
