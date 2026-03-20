#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
echo "AWS Auto Scaling Student Project" > /var/www/html/index.html
echo "Server Hostname: $(hostname)" >> /var/www/html/index.html

