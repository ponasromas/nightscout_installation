#!/bin/bash
# tested on Ubuntu 22.04 on ORacle free tier ARM server

# Initial vars from user
read -p "Enter title (usually the name of the person): " title
read -p "Enter display units (mg/dl or mmol/L (or just mmol)): " display_units
read -p "Enter Nightscout URL or IP address: " url
read -p "Enter API secret (admin password): " api_secret
read -p "MongoDB user: " mongo_user
read -p "MongoDB database name: " mongo_db

mongo_password=$(date | md5sum | awk '{ print $1 }')

# just remove it.
apt remove -y ufw

# Install helpers
apt install -y gnupg nano firewalld git python3 nodejs npm gcc

# Setup firewall
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --zone=public --add-port=80/tcp --permanent

# Required lib for mongo
wget http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_arm64.deb
apt install -y ./libssl1.1_1.1.1f-1ubuntu2.16_arm64.deb

# Install mongo key
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

apt update
apt install -y mongodb-org

systemctl enable mongod.service
systemctl start mongod.service

# Deploy new DB in mongo
mongosh <<EOF
use nightscout
db.createUser({user: "${mongo_user}", pwd: "${mongo_password}", roles:["readWrite"]})
quit()
EOF

# Clone and install CGM Nightscout
git clone https://github.com/nightscout/cgm-remote-monitor.git /root
npm --prefix /root/cgm-remote-monitor install /root/cgm-remote-monitor

# CREATE launch script
cat >/root/cgm-remote-monitor/start.sh <<EOL
#!/usr/bin/bash

# WEB
export CUSTOM_TITLE="${title}"
export DISPLAY_UNITS="${display_units}"
export MONGO_CONNECTION="mongodb://${mongo_user}:${mongo_password}@localhost:27017/${mongo_db}"
export BASE_URL="${url}"
export INSECURE_USE_HTTP=true
export PORT=80
export API_SECRET="${api_secret}"

# DEVICE
export PUMP_FIELDS="reservoir, battery, clock, status, device"
export DEVICESTATUS_ADVANCED=true
export ENABLE="careportal dbsize rawbg iob maker bwp cage iage sage boluscalc pushover treatmentnotify loop pump profile food openaps bage override speech cors"

# TIME
export TIME_FORMAT=24

# INIT SETTINGS
export NIGHT_MODE=false
export SHOW_PLUGINS="careportal"
export SHOW_RAWBG="never"
export THEME="colors"

# start server
node server.js
EOL

chmod +x /root/cgm-remote-monitor/start.sh

cat >/etc/systemd/system/nightscout.service <<EOL
[Unit]
Description=Nightscout Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/cgm-remote-monitor
ExecStart=/root/cgm-remote-monitor/start.sh

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable nightscout.service
systemctl start nightscout.service

echo "Done, visit: ${url} . Your API secret (admin password): ${api_secret}"
echo "Anytime you want to change server start variables, edit /root/cgm-remote-monitor/start.sh script and restart nightscout service."

exit 0