#!/bin/bash
set -ex

if [ -f /var/lib/mysql/mysqld-slow.log ]; then
    sudo mv /var/lib/mysql/mysqld-slow.log /var/lib/mysql/mysqld-slow.log.$(date "+%Y%m%d_%H%M%S")
fi
if [ -f /var/log/nginx/access_log]; then
    sudo mv /var/log/nginx/access_log /var/log/nginx/isucon6.access_log.tsv.$(date "+%Y%m%d_%H%M%S")
fi
sudo systemctl restart mysql
sudo systemctl restart isuda.go.service
sudo systemctl restart isutar.go.service
sudo systemctl restart nginx
