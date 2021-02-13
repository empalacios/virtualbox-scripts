#!/bin/bash
MINPARAMS=6

if [ $# -lt "$MINPARAMS" ]
then
  echo "Usage $0 vm_name vms_directory ostype disk_size ram_size install_image"
  echo "  vm_name:       Virtual machine's name"
  echo "  vms_directory: Base directory where the virtual machine's directory will be created"
  echo "  ostype:        Virtual machine's os type, one of \`vboxmanage list ostypes\`"
  echo "  disk_size:     Capacity of the virtual machine's drive, in Megabytes"
  echo "  ram_size:      Capacity of the virtual machine's RAM, in Megabytes"
  echo "  install_image: Path to the installation image (ISO)"
  exit 1
fi


vm_name=${1}
vms_directory=${2}
ostype=${3}
disk_size=${4}
ram_size=${5}
installation_image=${6}
disk_name=$vm_name.vdi


if [ ! -d "$vms_directory" ]
then
  echo "Error: base virtual machines directory $vms_directory doesn't exist."
  exit 1
fi

if [ "$disk_size" -le "0" ]
then
  echo "Error: disk capacity must be greater than zero (0) Megabytes"
  exit 1
fi

if [ "$ram_size" -le "0" -o "$ram_size" -gt "4096" ]
then
  echo "Error: RAM capacity must be a value between one (1) and four thousand ninety six (4096) Megabytes (1 Mb - 4 Gigabytes)"
  exit 1
fi

if [ ! -f "$installation_image" ]
then
  echo "Error: installation image $installation_image doesn't exist."
  exit 1
fi

vboxmanage showvminfo $vm_name &>/dev/null
if [ $? -eq 0 ]
then
  vboxmanage unregistervm $vm_name --delete
  echo "Deleted $vm_name"
fi


vboxmanage createvm --name $vm_name --register --ostype $ostype

vboxmanage modifyvm $vm_name --memory $ram_size \
  --vram 128 \
  --audiocontroller hda \
  --audiocodec stac9221 \
  --audioout on \
  --pae off \
  --usbohci on

#vrde is for remote desktop server
vboxmanage modifyvm $vm_name --vrde on

#nat networking
vboxmanage modifyvm $vm_name --nic1 nat --cableconnected1 on
echo "Created vm $vm_name: $ram_size MB RAM"

vboxmanage createhd --filename "$vms_directory/$vm_name/$disk_name" \
  --size $disk_size
vboxmanage storagectl $vm_name \
  --name 'SATA Controller' \
  --add sata \
  --controller IntelAhci \
  --bootable on
vboxmanage storageattach $vm_name \
  --storagectl 'SATA Controller' \
  --port 0 \
  --device 0 \
  --type hdd \
  --medium "$vms_directory/$vm_name/$disk_name"
echo "Created drive for $vm_name: $disk_size MB, location $vms_directory/$vm_name/$disk_name"
vboxmanage storagectl $vm_name \
  --name 'IDE Controller' \
  --add ide
vboxmanage storageattach $vm_name \
  --storagectl 'IDE Controller' \
  --port 0 \
  --device 0 \
  --type dvddrive \
  --medium "$installation_image"
echo "Created cdrom drive for $vm_name: mounted image $installation_image"

echo "Next steps"
echo "Start vm without GUI: vboxmanage startvm $vm_name --type=headless"
echo "View vm info:         vboxmanage showvminfo $vm_name"
echo "After installation"
echo "Remove Installation image from CDROM: vboxmanage storageattach $vm_name --storagectl 'IDE Controller' --port 0 --device 0 --medium none"
echo "Add image to CDROM Drive:             vboxmanage storageattach $vm_name --storagectl 'IDE Controller' --port 0 --device 0 --type dvddrive --medium <imagepath>"
echo "Remove CDROM Drive:                   vboxmanage storagectl $vm_name --name 'IDE Controller' --remove"
echo "Add Bidirectional Clipboard:          vboxmanage controlvm $vm_name clipboard bidirectional"
echo "Disconnect from network:              vboxmanage modifyvm $vm_name --nic1 null --cableconnected1 off"
