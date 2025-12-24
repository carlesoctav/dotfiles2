sudo apt-get install -y -qq nfs-kernel-server
sudo mkdir -p /mnt/carles
sudo chmod 755 /mnt/carles
internal_ip=$(hostname -I | awk '{print $1}')
echo "/mnt/carles  ${internal_ip}/24(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
