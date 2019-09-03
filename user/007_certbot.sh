#!/bin/sh

cd ~/ && git clone https://github.com/certbot/certbot
cd ~/certbot && sudo ./certbot-auto
