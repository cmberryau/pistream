HOSTNAME=pistreamer
STREAMING_USER=pi
YOUTUBELIVE_KEY=p9g3-f17p-j722-1d70

# change the root password

echo "Change the root password to something secure"

sudo passwd root

# change the default user (pi) password

echo "Change the root password to something secure"

sudo passwd $STREAMING_USER

# change the hostname

echo "Root password required for changing hostname + expanding filesystem"
echo "System will restart after this step is complete"

su root

echo $HOSTNAME > /etc/hostname

echo 127.0.0.1 $HOSTNAME > /etc/hosts
echo ::1 $HOSTNAME ip6-$HOSTNAME ip6-loopback >> /etc/hosts
echo ff02::1 ip6-allnodes >> /etc/hosts
echo ff02::2 ip6-allrouters >> /etc/hosts
echo 127.0.1.1 $HOSTNAME >> /etc/hosts

# expand the root filesystem, requires reboot

raspi-config --enable-camera
raspi-config --expand-rootfs

shutdown -r now

# upgrade

sudo apt-get update && sudo apt-get upgrade -y

# get ffmpeg deps & git

sudo apt-get -y --force-yes install autoconf automake build-essential libass-dev libfreetype6-dev \
    libtheora-dev libtool libvorbis-dev pkg-config texinfo zlib1g-dev libx264-dev git

# get ffmpeg sources

git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg

# configure, build and install ffmpeg (go get a few coffees)

cd ffmpeg

./configure --prefix="/usr/local/ffmpeg" --pkg-config-flags="--static" \
 --bindir="/usr/local/bin" --enable-gpl --enable-libx264

sudo make
sudo make install
sudo make distclean

cd ~

# create the var and etc directories for our streaming

sudo mkdir /var/local/pistream
sudo chown $STREAMING_USER.$STREAMING_USER /var/local/pistream

sudo mkdir /usr/local/etc/pistream
sudo chown $STREAMING_USER.$STREAMING_USER /usr/local/etc/pistream

# grab the service script and register it

git clone https://www.github.com/cmberryau/pistream

cd pistream

sudo cp pistream.sh /etc/init.d/pistream
sudo chown 755 /etc/init.d/pistream
sudo update-rc.d pistream defaults