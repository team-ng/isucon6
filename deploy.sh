#!/bin/bash
set -ex
IPADDR=$1
USERNAME=$USER
ssh isucon@$IPADDR "/home/isucon/notify.sh $USERNAME 'deploying...' && cd /home/isucon/deploy && git pull && ~/.local/perl/bin/carton install && sudo systemctl restart mysql && sudo service memcached restart && sudo systemctl restart isuxi.perl && sudo systemctl restart nginx && sudo sysctl -p && /home/isucon/notify.sh $USERNAME 'deploy done'"
