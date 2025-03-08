#!/bin/bash
sudo apt-get update
sudo apt-get install -y nodejs npm
git clone https://github.com/UnpredictablePrashant/TravelMemory.git /home/ubuntu
cd /home/ubuntu/backend
echo "MONGO_URI=mongodb://${MONGO_URI}:27017/travelmemory" > .env
npm install
npm start
