#!/bin/bash
sudo setenforce 0 
sudo yum clean all
sudo yum -y update
sudo yum -y install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd