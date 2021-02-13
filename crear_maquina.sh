#!/bin/bash
vbox_dir=/home/user/VirtualBox\ VMs
vm_name=alpine
# one of `vboxmanage list ostypes`
ostype=Linux26_64
memory=512
disk_name=$vm_name.vdi
disk_size=102400
so_installation_image=/home/user/Downloads/alpine-standard-3.8.0-x86_64.iso

vboxmanage showvminfo alpine &>/dev/null
if [ $? -eq 0 ]
then
  vboxmanage unregistervm $vm_name --delete
  echo "Deleted $vm_name"
fi
vboxmanage createvm --name $vm_name --register --ostype $ostype

vboxmanage modifyvm $vm_name --memory $memory \
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
echo "Created vm $vm_name: $memory MB RAM"

vboxmanage createhd --filename "$vbox_dir/$vm_name/$disk_name" \
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
  --medium "$vbox_dir/$vm_name/$disk_name"
echo "Created drive for $vm_name: $disk_size MB, location $vbox_dir/$vm_name/$disk_name"
vboxmanage storagectl $vm_name \
  --name 'IDE Controller' \
  --add ide
vboxmanage storageattach $vm_name \
  --storagectl 'IDE Controller' \
  --port 0 \
  --device 0 \
  --type dvddrive \
  --medium "$so_installation_image"
echo "Created cdrom drive for $vm_name: $disk_size MB, location $so_installation_image"

echo "Next steps"
echo "Start vm without GUI: vboxmanage startvm $vm_name --type=headless"
echo "View vm info:         vboxmanage showvminfo $vm_name"
echo "After installation"
echo "Remove Installation image from CDROM: vboxmanage storageattach alpine --storagectl 'IDE Controller' --port 0 --device 0 --medium none"
echo "Add image to CDROM Drive:             vboxmanage storageattach alpine --storagectl 'IDE Controller' --port 0 --device 0 --type dvddrive --medium <imagepath>"
echo "Remove CDROM Drive:                   vboxmanage storagectl alpine --name 'IDE Controller' --remove"
echo "Add Bidirectional Clipboard:          vboxmanage controlvm $vm_name clipboard bidirectional"
echo "Disconnect from network:              vboxmanage modifyvm $vm_name --nic1 null --cableconnected1 off"
