#!/bin/bash
timestamp=$(date '+%d%m%Y-%H%M%S')
myname=rajeshg
s3_bucket=upgrad-rajeshg
#update sources
sudo apt-get update

#apache presence on server or not
check_apache=`apt -qq list apache2 --installed |wc -l`

  if [ $check_apache == 0 ]
  then
        apt-get install apache2 -y
  fi

check_awscli=`apt -qq list awscli --installed |wc -l`

  if [ $check_awscli == 0 ]
  then
        apt-get install awscli -y
  fi

#check apache running or not
apache_status=`systemctl status apache2.service  | grep Active | awk '{ print $3 }'`

if [ $apache_status == "(dead)" ]
then
        systemctl enable apache2.service
fi

#check apache running status
if pgrep -x "apache2" >/dev/null
then
    echo "apache2 is running"
else
    systemctl start apache2
fi

#create tar file
cd /var/log/apache2 && tar -cvf /tmp/$myname-httpd-logs-$timestamp.tar *.log

if [ $? == 0 ]
then
        aws s3 cp /tmp/$myname-httpd-logs-$timestamp.tar s3://$s3_bucket/$myname-httpd-logs-$timestamp.tar
fi

#Task 3 - To keep logs in inventory.html
        size=`du -sh /tmp/$myname-httpd-logs-$timestamp.tar |  awk '{ print $1 }'`
        if [ -e /var/www/html/inventory.html ]
        then
        echo "<br>httpd-logs &nbsp;&nbsp;&nbsp; ${timestamp} &nbsp;&nbsp;&nbsp; tar &nbsp;&nbsp;&nbsp; $size" >> /var/www/html/inventory.html
        else
        echo "<b>Log Type &nbsp;&nbsp;&nbsp;&nbsp; Date Created &nbsp;&nbsp;&nbsp;&nbsp; Type &nbsp;&nbsp;&nbsp;&nbsp; Size</b><br>" > /var/www/html/inventory.html
        echo "<br>httpd-logs &nbsp;&nbsp;&nbsp; ${timestamp} &nbsp;&nbsp;&nbsp; tar &nbsp;&nbsp;&nbsp; ${size}" >> /var/www/html/inventory.html
        fi

# check cron file is exist of not, if it is doesn't exist then create it
# Note:- script will execute once in day at 11.59AM
if  [ ! -f  /etc/cron.d/automation ]
then
        echo "59 11 * * * root /root/Automation_Project/automation.sh" > /etc/cron.d/automation
fi

