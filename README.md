# Jeedomboard as Serial Gateway

## Summary
The goal is to transform an old Jeedom Mini+ hardware equipped with a EnOcean interface on the GPIO port into a simple serial server to share the local this EnOcean interface over the network and access it from an home automation system.
  
[Jeedom Mini+](https://blog.jeedom.com/1193-presentation-de-la-box-jeedom-mini/) is a small home automation appliance based on a Jeedomboard designed by [Jeedom team](https://www.jeedom.com).  
The jeedomboard has been build by [SolidRun](https://www.solid-run.com) based on [HummingBoard iMX6](https://solidrun.atlassian.net/wiki/spaces/developer/pages/197493454/i.MX6+Based+Products).

## Part 1 - Operating System
### Installation
- To flash the uSD card, use a trusted application like [Balena Etcher](https://www.balena.io/etcher/).
- Download Debian Bullseye available for this platform: [sr-imx6-debian-bullseye-20220712-cli-sdhc.img.xz](https://solid-run-images.sos-de-fra-1.exo.io/IMX6/Debian/sr-imx6-debian-bullseye-20220712-cli-sdhc.img.xz).
  - Feel free to take another OS release on the [SolidRun image repository](https://images.solid-run.com/IMX6/Debian).
- Flash the Debian image on a uSD card (I recommend at least 4GB).
- Boot the hardware with the fresh SD card.
  - Default user: debian and password: debian
  - Connect directly in SSH if you have the @IP from your local DHCP server (@MAC may change compared to the original distrib).
  - If needed, use local KVM and display your @IP using <code>ip addr show</code>.

### Configuration
```
locale
sudo locale-gen en_US.UTF-8
sudo export LANGUAGE="en_US.UTF-8"
sudo export LANG="en_US.UTF-8"
locale

sudo apt update
sudo apt dist-upgrade
sudo systemctl mask serial-getty@ttymxc0.service
sudo echo "EnOceanGW" > /etc/hostname
sudo reboot

sudo apt install ntpdate ntp
timedatectl
sudo timedatectl set-timezone Europe/Zurich
timedatectl
ntpq -p
date

sudo apt install man-db
sudo apt install bash-completion
sudo apt install vim
```
  

## Part 2 - Serial Server & Client
### Download the file from my github
1) Clone, download or ugly copy+paste the four files on your systems.
2) Move the ser2net* files to Jeedomboard Serial Server.
3) Move the socat* files to Jeedom Home Automation system.

### Serial Server with ser2net (on the Jeedomboard)
Customized installation of ser2net:
- Control the automatic startup with systemd and not init.d.
- Delayed startup (1min) of ser2net to have the serial interface available.
```
sudo apt install ser2net

sudo systemctl stop ser2net
sudo mv /etc/init.d/ser2net ~/ser2net.initd.backup
sudo mv /etc/ser2net.yaml ~/ser2net.yaml.backup
sudo systemctl daemon-reload

sudo mv ser2net.yaml /etc/default/
sudo chown root:root /etc/default/ser2net.yaml
sudo chmod 644 /etc/default/ser2net.yaml
sudo mv ser2net.service /etc/systemd/system/
sudo mv ser2net.timer /etc/systemd/system/
sudo chown root:root /etc/systemd/system/ser2net.*
sudo chmod 755  /etc/systemd/system/ser2net.*

sudo systemctl daemon-reload
sudo systemctl enable ser2net.timer
sudo systemctl start ser2net.service
```
Verify if service is running and other troubleshooting commands:
```
netstat -lntu
sudo systemctl status ser2net.timer
sudo systemctl status ser2net.service
```

### Serial Client with socat (on the Home Automation system, debian-based)
Installation of socat and custom deamonization with systemd.
```
sudo apt install socat

sudo mv socat-ttyenocean0.sh /usr/bin/
sudo chown root:root /usr/bin/socat-ttyenocean0.sh
sudo chmod 755 /usr/bin/socat-ttyenocean0.sh
mv socat-ttyenocean0.service /etc/systemd/system/
sudo chown root:root /etc/systemd/system/socat-ttyenocean0.service
sudo chmod 755 /etc/systemd/system/socat-ttyenocean0.service

sudo systemctl daemon-reload
sudo systemctl enable socat-ttyenocean0.service
sudo systemctl start socat-ttyenocean0.service
```
Verify if service is running and other troubleshooting commands:
```
sudo systemctl status socat-ttyenocean0.service
tail /var/log/socat-ttyenocean0.log
```