sudo apt-get install -y -qq nfs-common
sudo mkdir -p /mnt/carles
if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    sudo mount $1:/mnt/carles /mnt/carles
    ln -sf /mnt/carles ~/carles
else
    echo "Invalid IP address"
    exit 1
fi

