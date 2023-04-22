#!/bin/bash

set -e
COL='\033[1;32m'
NC='\033[0m' # No Color
echo -e "${COL}Setting up moonraker"

read -p "Do you have \"Plugin extras\" installed? (y/n): " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${COL}\nPlease go to settings and install plugin extras${NC}"
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

echo -e "${COL}Installing dependencies...\n${NC}"
# install required dependencies
apk add curl curl-dev jpeg-dev python3-dev py3-lmdb py3-wheel

echo -e "${COL}Downloading moonraker\n${NC}"
curl -o moonraker.zip -L https://github.com/Arksine/moonraker/archive/refs/heads/master.zip

echo -e "${COL}Extracting moonraker\n${NC}"
unzip moonraker.zip
echo -e "${COL}Finished extracting\n${NC}"
rm -rf moonraker.zip
mv moonraker-master /moonraker

cd /moonraker/

# pip3 install -U pip setuptools wheel

for n in tornado pyserial pillow lmdb libnacl paho-mqtt pycurl streaming-form-data
do
  sed -i "s#$n.*#$n#" ./scripts/moonraker-requirements.txt
done
pip3 install -r scripts/moonraker-requirements.txt

false | cp -i /moonraker/docs/moonraker.conf /moonraker.conf 2>/dev/null

echo -e "${COL} Applying special sauce${NC}"
sed -i 's/max_dbs=MAX_NAMESPACES)/max_dbs=MAX_NAMESPACES, lock=False)/' /moonraker/moonraker/components/database.py

mkdir -p /root/extensions/moonraker
cat << EOF > /root/extensions/moonraker/manifest.json
{
        "title": "Moonraker plugin",
        "description": "Requires Klipper, and becomes usefull after installing Mainsail"
}
EOF
mkdir /root/gcode_files
# printer.cfg:
# [virtual_sdcard]
# path: ~/gcode_files

cat << EOF > /root/extensions/moonraker/start.sh
#!/bin/sh
LD_PRELOAD=/home/octoprint/ioctlHook.so python3 /moonraker/moonraker/moonraker.py -c /moonraker.conf -l /tmp/moonraker.log
EOF

cat << EOF > /root/extensions/moonraker/kill.sh
#!/bin/sh
pkill -f 'moonraker\.py'
EOF
chmod +x /root/extensions/moonraker/start.sh
chmod +x /root/extensions/moonraker/kill.sh
chmod 777 /root/extensions/moonraker/start.sh
chmod 777 /root/extensions/moonraker/kill.sh

cat << EOF ${COL}
Moonraker installed!
Make sure you have Klipper installed and configured.
Moonraker requires certain klipper settings: https://github.com/Arksine/moonraker/blob/master/docs/installation.md#klipper-configuration-requirements
Moonraker (example) config is at /moonraker.conf and must be edited.
Please kill the app and restart it again to see it in extension settings${NC}
EOF
