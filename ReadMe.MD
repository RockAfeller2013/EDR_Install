# Carbon Black EDR Vagrant Auto Install


Created:   	  2024
Created by:    Roshan Ratnayake - detectx.com.au



.DESCRIPTION

Install Carbon Black On Prem EDR using Hashicorp Vagrant
This GIT repo does not contain the Carbon Blac EDR RPM or license file, you need to request them from your local SE.

Tested and working with Vmware workstation 17.5.0 build-22583795 and Vagrant for VMware Vagrant 2.4.0 , 
vagrant-scp (0.5.9, global), vagrant-vmware-desktop (3.0.3, global)

.Install Vagrant SCP Plugin

vagrant plugin install vagrant-scp

## CentOS Vagrant
Create 'vagrant.ini'
https://app.vagrantup.com/generic/boxes/centos8
create a folder, then create vagrant.ini
Username and Password osboxes.org/osboxes.org
https://www.osboxes.org/faq/what-are-the-credentials-for-virtual-machine-image/


## Get Red Hat 8 [RHEL 8.1-8.9 (64-bit)] Develop Edition
https://console.redhat.com/insights/image-builder/imagewizard?source=RHD#SIDs=&tags=
Installation source - 
https://cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os/
https://console.redhat.com/insights/content?origin=red_hat
https://access.redhat.com/management/systems
https://developers.redhat.com/products/rhel/overview

## Doanload Red Hat Linux DVD 
Register on Red Hat Linux Developer, click on below link, select Red Hat Enterprise 8.4.0, x86_64, DVD iso, Download 9.43 GB)
https://developers.redhat.com/products/rhel/download#rhel-new-product-download-list-61451
https://access.cdn.redhat.com/content/origin/files/sha256/ea/ea5f349d492fed819e5086d351de47261c470fc794f7124805d176d69ddf1fcd/rhel-8.4-x86_64-dvd.iso?_auth_=1705372554_77829b6bde1e94d2255df005d7f848d5
subscription-manager register --username <username> --password <password> --auto-attach
subscription-manager register --username roshan.ratnayake@broadcom.com --password 7zE3I.VA-976D6 --auto-attach
https://access.redhat.com/solutions/253273

## CentOS 7.9 (Tested and Working)
https://mirror.aarnet.edu.au/pub/centos/7.9.2009/isos/x86_64/
https://mirror.aarnet.edu.au/pub/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso



## CentOS 
http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os/
https://mirror.cs.pitt.edu/centos-vault/8.4.2105/isos/x86_64/
Minimal

## vagrant/vagrant
Username – osboxes
Password – osboxes.org
For Root user account
Password – osboxes.org

For some stupid reason the root password doesnt work, so you have to reset it for this vagrant file.

Start the VM and press 'e' to edit
find linux and press END and add rd.break then Ctrl + X to boot with modifed settings
mount -o remount,rw /sysroo
chroot /sysroot
passwrd (it must be complex otherwise, boot will fail
touch /.autorelabel
exit
reboot


## Disable ipv6
https://linuxhint.com/disable_ipv6_centos8/



# vagrant.ini

Vagrant.configure("2") do |config|
  config.vm.box = "generic/centos8"
end

## Create a Snapshot

vagrant halt --force
vagrant snapshot save <SNAPSHOT_NAME>
vagrant snapshot save centos_ready_before_cb_install
vagrant snapshot list
vagrant snapshot restore <SNAPSHOT_NAME>

## Install server

del Vagrantfile
vagrant init generic/centos8
vagrant up
vagrant status
vagrant global-status
vagrant ssh-config

## Copy file from local to server

vagrant scp /path/to/local/file/on/your/machine default:/path/on/vagrant/machine
https://stackoverflow.com/questions/32410299/how-to-copy-file-from-a-vagrant-machine-to-localhost
copy the license and rpm to the same directory as the scp command doesnt handle paths very well

vagrant scp ./1.txt default:~
vagrant scp carbon-black-2024-1-10.lic default:~
vagrant scp "carbon-black-release-1.0.4-1-Carbon Black Inc._I149104.x86_64.rpm" default:~

## SSH into CentOS and configure machine

vagrant ssh
vagrant ssh-config | findstr "HostName"

## ------------------------------------------------------------------------------------------------------------------------------------------------

# Insure your DNS resolution is working to local hostname and edit /etc/hosts insure to stay out of the block within BEGIN/END.

hostnamectl set-hostname cbresponse
systemctl restart systemd-hostnamed
hostname


nano /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.193.136     cbresponse cbresponse.local

# {{BEGIN - CB Server}}
# The block within these BEGIN/END tags is managed by VMware Carbon Black EDR
# Server configuration tools. DO NOT EDIT within BEGIN/END comment tags as the
# content of this section may get automatically regenerated.

127.0.0.1           CB-SERVER-CLUSTER-HEAD-NODE

# {{END - CB Server}}



192.168.193.136     cbresponse cbresponse.local

systemctl restart systemd-hostnamed
nslookup CB-SERVER-CLUSTER-HEAD-NODE

# Set timezone on Redhat
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/chap-configuring_the_date_and_time#sect-Configuring_the_Date_and_Time-timedatectl-Time_Zone
 
timedatectl list-timezones | grep Australia
timedatectl set-timezone Australia/Brisbane
timedatectl set-ntp yes
date +%r



# Set up server

sudo systemctl disable firewalld
sudo systemctl restart udev.service
sudo hostnamectl set-hostname cbresponse
sudo systemctl restart systemd-hostnamed
sudo timedatectl set-ntp true
sudo yum install bind-utils

sudo lvdisplay
ip address
vmware-toolbox-cmd-v


# Install CB Response
# install as root or use sudo

sudo rpm -ivh carbon-black-release-1.0.4-1-Carbon Black Inc._I149104.x86_64.rpm
cat /etc/yum.repos.d/CarbonBlack.repo
sudo yum module disable postgresql redis python38 python39
sudo yum install cb-enterprise
cat /usr/share/cb/cbinit
sudo /usr/share/cb/cbinit
reboot
/usr/share/cb/cbssl backup --out <backup_file_name>



# Start Cb Response Server

systemctl start cb-enterprise
systemctl status cb-enterprise
systemctl restart cb-enterprise

service cb-enterprise start
/usr/share/cb/cbservice cb-enterprise start


https://<your server address>/
https://192.168.193.135:443
https://192.168.193.136:443



# /usr/share/cb/cbinit --help Usage: cbinit
# /usr/pgsql-13/bin/pg_ctl -D /var/cb/data/pgsql -l logfile start
# cat /usr/share/cb/cbinit
[Config]
root_storage_path=/var/cb/data
admin_username=admin
admin_first_name=Threat
admin_last_name=Hunter
admin_email=aw@organization.org
admin_password=Sup3r$3cr3+ / password
service_autostart=0
force_reinit=1
default_sensor_server_url=https://127.0.0.1:443
alliance_comms_enabled=1
alliance_statistics_enabled=1
alliance_bit9_hashes_enabled=1
alliance_bit9_binaries_enabled=1

https://192.168.193.133:443
https://192.168.193.135:443

# Troubleshooting

https://community.carbonblack.com/t5/Knowledge-Base/EDR-Server-How-To-Manually-Stop-Service-When-Stopping-cb/ta-p/108873
https://community.carbonblack.com/t5/Knowledge-Base/EDR-How-to-Restart-Server-Services/ta-p/41294
https://community.carbonblack.com/t5/Knowledge-Base/EDR-How-to-Manually-Start-Server-Services/ta-p/111510
https://community.carbonblack.com/t5/Knowledge-Base/EDR-How-To-Generate-Server-Diagnostic-Logs-for-On-Prem/ta-p/62165
https://community.carbonblack.com/t5/Knowledge-Base/EDR-RabbitMQ-failing-to-start-with-invalid-credentials/ta-p/72993

sudo /usr/share/cb/cbservice cb-enterprise stop
killall -KILL -u cb
ps -ef | grep cb
sudo /usr/share/cb/cbservice cb-enterprise start
sudo /usr/share/cb/cbservice cb-enterprise restart


systemctl start cb-enterprise
systemctl status cb-enterprise
service cb-enterprise start
/usr/share/cb/cbservice cb-enterprise start

journalctl -xe 
journalctl -fexu cb-enterprise
/var/log/messages
/usr/share/cb/cbrabbitmqctl list_users

/usr/share/cb/cbcheck selinux -a
/use/share/cb/cbcheck firewall -a

service cb-enterprise status
service cb-enterprise start
service cb-enterprise restart


systemctl status cb-enterprise
systemctl start cb-enterprise
systemctl restart cb-enterprise 
systemctl status cb-enterprise.service


sudo /usr/share/cb/cbdiag --post



yum clean all
yum update cb-enterprise

Check the status of running services
  service cb-enterprise status
Manually stop each running services in order of this list
  /usr/share/cb/cbservice cb-nginx stop
  /usr/share/cb/cbservice cb-enterprised stop
  /usr/share/cb/cbservice cb-allianceclient stop
  /usr/share/cb/cbservice cb-liveresponse stop
  /usr/share/cb/cbservice cb-datastore stop
  /usr/share/cb/cbservice cb-sensorservices stop
  /usr/share/cb/cbservice cb-coreservices stop
  /usr/share/cb/cbservice cb-solr stop
  /usr/share/cb/cbservice cb-rabbitmq stop
  /usr/share/cb/cbservice cb-redis stop
  /usr/share/cb/cbservice cb-datagrid stop
  /usr/share/cb/cbservice cb-pgsql stop
Once services are confirmed to be stopped, kill any additional running services such as epmd
  killall -KILL -u cb
Clear any failed status in systemctl 
  systemctl reset-failed cb-enterprise

To check for any orphaned cb services use:
  ps -ef | grep cb
NOTE: cbdaemon and event-forwarder services should not affect the startup and shutdown of server services
  killall -KILL -u cb kills any processes owned by the cb user. A similar effect can be achieved by manually killing any pids returned with the above ps command


/usr/share/cb/cbservice cb-pgsql start
/usr/share/cb/cbservice cb-datagrid start
/usr/share/cb/cbservice cb-redis start
/usr/share/cb/cbservice cb-rabbitmq start
/usr/share/cb/cbservice cb-solr start
/usr/share/cb/cbservice cb-coreservices start
/usr/share/cb/cbservice cb-sensorservices start
/usr/share/cb/cbservice cb-datastore start
/usr/share/cb/cbservice cb-liveresponse start
/usr/share/cb/cbservice cb-allianceclient start
/usr/share/cb/cbservice cb-enterprised start
/usr/share/cb/cbservice cb-nginx start


/etc/cb/cb.conf



  # Putty

  putty -ssh root@192.168.193.133 -pw Wicked1!
