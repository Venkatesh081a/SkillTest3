#!/bin/bash
sudo apt-get update
sudo apt-get install -y nodejs npm
git clone https://github.com/UnpredictablePrashant/TravelMemory.git /home/ubuntu
cd /home/ubuntu/frontend
sed -i 's|http://localhost:3000|http://<backend_ip>:3000|g' src/url.js
npm install
npm start
