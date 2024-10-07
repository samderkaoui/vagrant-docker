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