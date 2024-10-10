#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# pull image 

sudo docker pull louislam/dockge:1
sudo docker pull louislam/uptime-kuma:1.23.15-alpine
sudo docker pull portainer/portainer-ce:latest
sudo docker pull pihole/pihole:latest
sudo docker pull mysql:8.0
sudo docker pull semaphoreui/semaphore:v2.10.22

# stop systemd-resolved for Pihole

sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved




# Create docker-compose.yml file
cat << EOF > /home/vagrant/docker-compose.yml
version: '3'

services:
  dockge:
    image: louislam/dockge:1
    restart: always
    ports:
      - 5001:5001
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
      - /opt/stacks:/opt/stacks
    environment:
      - DOCKGE_STACKS_DIR=/opt/stacks

  uptime-kuma:
    image: louislam/uptime-kuma:1.23.15-alpine
    container_name: uptime-kuma
    volumes:
      - uptime_vol:/app/data
    ports:
      - 3001:3001
    restart: always

  portainer:
    container_name: portainer
    restart: always
    ports:
      - "9000:9000"
      - "9443:9443"
    image: portainer/portainer-ce:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /portainer_data:/data

  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp" # dns
      - "53:53/udp" # dns
      - "8888:80/tcp" # interface web
    environment:
      TZ: 'Europe/Paris'
      WEBPASSWORD: 'Globulus123.' # mot de passe de l'interface web /admin
    volumes:
      - '/srv/docker/pihole/etc-pihole:/etc/pihole/'
      - '/srv/docker/pihole/etc-dnsmasq.d:/etc/dnsmasq.d/'

    restart: always

  mysql:
    restart: always
    image: mysql:8.0
    hostname: mysql
    volumes:
      - semaphore-mysql:/var/lib/mysql
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: 'yes'
      MYSQL_DATABASE: semaphore
      MYSQL_USER: semaphore
      MYSQL_PASSWORD: semaphore

  semaphore:
    restart: always
    ports:
      - 3000:3000
    image: semaphoreui/semaphore:v2.10.22
    environment:
      GIT_SSL_NO_VERIFY: "true"
      SEMAPHORE_DB_USER: semaphore
      SEMAPHORE_DB_PASS: semaphore
      SEMAPHORE_DB_HOST: mysql
      SEMAPHORE_DB_PORT: 3306
      SEMAPHORE_DB_DIALECT: mysql
      SEMAPHORE_DB: semaphore
      SEMAPHORE_PLAYBOOK_PATH: /tmp/semaphore/
      SEMAPHORE_ADMIN_PASSWORD: Globulus123.
      SEMAPHORE_ADMIN_NAME: admin
      SEMAPHORE_ADMIN_EMAIL: admin@localhost
      SEMAPHORE_ADMIN: admin
      SEMAPHORE_ACCESS_KEY_ENCRYPTION: u0aKdC+eL9GeylV0whAz0pkC5MO9Yx4EcaZcNfeLLfE=
      SEMAPHORE_LDAP_ACTIVATED: 'no'
    depends_on:
      - mysql

volumes:
  semaphore-mysql:
  uptime_vol:

EOF

# Run docker-compose
sudo docker compose -f /home/vagrant/docker-compose.yml up -d

# github avec url's sympa pour blocage
echo " https://gitlab.com/malware-filter/urlhaus-filter#malicious-url-blocklist "

# mes liens pihole
echo " https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts "
echo " https://easylist.to/easylist/easylist.txt "
echo " https://easylist.to/easylist/easyprivacy.txt "
echo "  https://secure.fanboy.co.nz/fanboy-cookiemonster.txt "
echo " https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-agh-online.txt " 
