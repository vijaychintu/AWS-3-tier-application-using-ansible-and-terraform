#!/bin/bash
dnf update -y
echo "booting" > /var/www/html/index.html
mkdir -p /etc/ansible/facts.d
