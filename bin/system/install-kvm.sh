#!/bin/bash

# Install kvm
sudo pacman -S --noconfirm qemu-full libvirt virt-manager dmidecode dnsmasq --needed
sudo systemctl enable libvirtd.service
sudo systemctl start libvirtd.service
sudo usermod -aG libvirt $(whoami)
lsmod | grep kvm