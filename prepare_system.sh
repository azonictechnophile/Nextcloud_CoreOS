#!/bin/bash -uxe
#
# Prepare system for Nextcloud installation
#

# root or not
if [[ $EUID -ne 0 ]]; then
  SUDO='sudo -H'
else
  SUDO=''
fi


  $SUDO rpm-ostree install cronie python3-pip firewalld open-vm-tools
        
  set +x
  echo
  echo "------------------------------------------------------"
  echo
  echo "   Fedora Core OS System ready to install Nextcloud."
  echo
  echo "------------------------------------------------------"
  echo
