# 🍂 Yet Another Basic Arch-linux Installer (yabai)
## What is yabai?
After more than 3 years using arch linux and installing the complete system manually, i decided to create this simple script to rise a complete Arch linux installation only with base, base devel, linux zen, network manager, zsh and neovim packages on a EFI system, for make my life easier. This script uses the same way of installation that is in the Arch wiki. Any suggestions or issues are appreciated 
## Instructions:
0) Is preferible run a format tool before start the script, i recomend dd to wipe the entry hard drive
   ```sh
   sudo dd if=/dev/zero of=/dev/sda bs=4M status=progress
   ```
1) Download the script into an Arch iso.
   ```sh
   curl -Lo yabai.sh https://git.io/JU3F3
   ```
2) Modify as you wish
3) run the script
   ```sh
   bash ./yabai.sh
   ```
4) Follow the steps for initialize the script and wait to enjoy your arch installation

## To-do list
* choose locale(rn you need to change it manually at the script)
* convert the disk route and partitions size to variables

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
