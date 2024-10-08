#!/bin/bash

# # https://gitlab.com/xavki/docker-generator

#---------------------------------------------------------------#
#- author            : DERKAOUI Samir			        #
#- creating date     : 12/12/2023                               #
#- Last modification : 12/12/2023                               #
#- Version           : 1.0                                      #
#-                                                              #
#- Ce fichier permet de générer des conteneurs selon les besoin #
#-   ex: ./dockerisator.sh -p ou --portainer                    #
#-   Le tout est généré avec des volumes de données persistantes#
#-   dans le dossier dockerisator. Le network docker est aussi  #
#-   nommé dockerisator et chaque conteneur à un ip fixe.       #
#-  (./dockerisator.sh --ip pour connaitre les ip actives)      #
#-                                                              #
#-                                                              #
#- V 0.1 : création du script                                   #
#- V 1.0 : Script testé et validé                               #
#---------------------------------------------------------------#

DIR="${HOME}/dockerisator"
USER_SCRIPT=$USER
USER_DOCKER="vagrant"

# Fonctions ###########################################################

help_list() {
  echo "Usage:

  ${0##*/} [-h][-p][--portainer]

Options:

  -h, --help
    can I help you ?

  -a, --api
    run api for test

  -i, --ip
    list ip for each container

  -sec, --secure
    secure docker daemon (do it in sudo !)

  -rmf, --removeforce
    remove all container running or not

  -rm, --remove
    remove all container that are not running

  -pru, --pruner
    remove all unused images

  -c, --ctop
    install ctop (top pour conteneur)

  -p, --portainer
    run portainer

  -j, --jenkins
    run jenkins container

  -jdood, --jenkinsdood
    run jenkins container mapped to local docker

  -jdind, --jenkinsdind
    run jenkins container mapped to local dind image 

  -g, --gitlab
    run gitlab

  -r, --runner
    run runner

  -pg, --postgres
    run postgres
  
  -pr, --prometheus
    run prometheus

  -gr, --grafana
    run grafana

  -gl, --graylog
    run graylog

  -lk, --loki
    run loki
  "
}

parse_options() {
  case $@ in
    -h|--help)
      help_list
      exit
     ;;
    -a|--api)
      api
      ;;
    -i|--ip)
      ip
      ;;
    -c|--ctop)
      ctop
      ;;
    -p|--portainer)
      portainer
      ;;
    -j|--jenkins)
      jenkins
      ;;
    -jdood|--jenkinsdood)
      jenkinsdood
      ;;
    -jdind|--jenkinsdind)
      jenkinsdind
      ;;
    -g|--gitlab)
      gitlab
      ;;
    -r|--runner)
      runner
      ;;
    -pg|--postgres)
      postgres
      ;;
    -pr|--prometheus)
      prometheus
      ;;
    -gr|--grafana)
      grafana
      ;;
    -gl|--graylog)
      graylog
      ;;
    -lk|--loki)
      loki
      ;;
    -rmf|--removeforce)
      removeforce
      ;;
    -rm|--remove)
      remove
      ;;
    -pru|--prune)
      prune
      ;;
    -sec|--secure)
      secure
      ;;
    *)
      echo "Unknown option: ${opt} - Run ${0##*/} -h for help.">&2
      exit 1
  esac
}

secure() {
echo "
  {
   \"userns-remap\": \"default\",
   \"no-new-privileges\": true,
   \"live-restore\": true
  }
" > /etc/docker/daemon.json

# creation user remapé
groupadd -g 500000 dockremap && 
groupadd -g 501000 dockremap-user && 
useradd -u 500000 -g dockremap -s /bin/false dockremap && 
useradd -u 501000 -g dockremap-user -s /bin/false dockremap-user

echo "dockremap:500000:65536" >> /etc/subuid && 
echo "dockremap:500000:65536" >>/etc/subgid



# ajout user
sudo usermod -aG docker $USER_DOCKER


# restart docker et daemon
sudo systemctl daemon-reload && sudo systemctl restart docker
}


prune() {
docker image prune -a
}

removeforce() {
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
}

remove() {
docker rm $(docker ps -a -q)
}


ip() {
for i in $(docker ps -q); do docker inspect -f "{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} - {{.Name}}" $i;done
}

api() {
docker run -d --name httpbin -p 9999:80 kennethreitz/httpbin
}

ctop() {
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
echo "installation de ctop terminé"
}





loki() {
echo
echo "Install loki"

echo "1 - Create directories ${DIR}/loki/etc"
mkdir -p $DIR/loki/etc
chmod 775 -R $DIR/loki/

echo "2 - Create config file loki-config.yaml "
echo "
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

ingester:
  wal:
    enabled: true
    dir: /tmp/wal
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h       # Any chunk not receiving new logs in this time will be flushed
  max_chunk_age: 1h           # All chunks will be flushed when they hit this age, default is 1h
  chunk_target_size: 1048576  # Loki will attempt to build chunks up to 1.5MB, flushing first if chunk_idle_period or max_chunk_age is reached first
  chunk_retain_period: 30s    # Must be greater than index read cache TTL if using an index cache (Default index read cache TTL is 5m)
  max_transfer_retries: 0     # Chunk transfers disabled

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/boltdb-shipper-active
    cache_location: /tmp/loki/boltdb-shipper-cache
    cache_ttl: 24h         # Can be increased for faster performance over longer query periods, uses more disk space
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks

compactor:
  working_directory: /tmp/loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s

ruler:
  storage:
    type: local
    local:
      directory: /tmp/loki/rules
  rule_path: /tmp/loki/rules-temp
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
" > $DIR/loki/etc/loki-config.yaml


echo "3 - Create docker compose for loki "
echo "
version: '3'
services:
  loki:
    image: grafana/loki:latest
    restart: always
    ports:
      - "3100:3100"
    volumes:
      - loki_etc:/etc/loki
    command: -config.file=/etc/loki/loki-config.yaml
#   logging:
#     driver: loki
#     options:
#       loki-url: http://loki:3100/loki/api/v1/push
#       mode: non-blocking
#       max-buffer-size: 4m
#       loki-retries: "99999"
    networks:
      dockerisator:
        ipv4_address: 192.168.111.30
volumes:
  loki_etc:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/loki/etc/
networks:
  dockerisator:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.111.0/24 
" > $DIR/docker-compose-loki.yml

echo "4 - Run loki "
docker compose -f $DIR/docker-compose-loki.yml up -d

echo "
localhost:3100 for Grafana
"

}


portainer () {
echo
echo "Démarrer Portainer"

echo "1 - Create directories ${DIR}/portainer/"
mkdir -p $DIR/portainer/

echo "2 - Create docker-compose file"
echo "
version: '3'
services:
  portainer:
    container_name: portainer
    restart: always
    ports:
    - "9000:9000"
    - "9443:9443"
    image: portainer/portainer-ce:latest
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - portainer_data:/data
    networks:
      dockerisator:
        ipv4_address: 192.168.111.2
volumes:
  portainer_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/portainer/
networks:
  dockerisator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.111.0/24
" >$DIR/docker-compose-portainer.yml

echo "3 - Démarrer Portainer "
docker compose -f $DIR/docker-compose-portainer.yml up -d

}

runner () {
echo
echo "Remove portainer"
docker rm -f portainer

echo "1 - Create directories ${DIR}/runner/"
mkdir -p $DIR/runner/

echo "2 - Create docker-compose file"
echo "
version: '3'
services:
  gitlab-runner:
    image: gitlab/gitlab-runner
    container_name: gitlab-runner
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - git_runner_data:/etc/gitlab-runner'
    networks:
      dockerisator:
        ipv4_address: 192.168.111.4
volumes:
  git_runner_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/runner/
networks:
  dockerisator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.111.0/24
" >$DIR/docker-compose-runner.yml

echo "3 - Démarrer Runner "
docker compose -f $DIR/docker-compose-runner.yml up -d

}

jenkins() {

echo
echo "Install Jenkins"

echo "1 - Create directories ${DIR}/jenkins/"
mkdir -p $DIR/jenkins/

echo "2 - Create docker-compose file"
echo "
version: '3'
services:
  jenkins:
    image: 'jenkins/jenkins:lts'
    container_name: jenkins
    restart: always
    user: 0:0
    ports:
      - '8080:8080'
      - '443:8443'
      - '50000:50000'
    volumes:
      - 'jenkins_data:/var/jenkins_home/'
    networks:
      dockerisator:
        ipv4_address: 192.168.111.10
volumes:
  jenkins_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/jenkins/
networks:
  dockerisator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.111.0/24
" >$DIR/docker-compose-jenkins.yml

echo "3 - Démarrer Jenkins "
docker compose -f $DIR/docker-compose-jenkins.yml up -d


}

jenkinsdood() {

echo
echo "Install Jenkins Docker outside of docker to use the docker of the dockerhost"

echo "1 - Create directories ${DIR}/jenkinsdood/"
mkdir -p $DIR/jenkinsdood/

echo "2 - Create Dockerfile"
cat <<EOF >$DIR/Dockerfile
FROM jenkins/jenkins:lts
USER root
RUN apt-get update && \
    apt-get -y install apt-transport-https \
                        ca-certificates \
                        curl \
                        gnupg-agent \
                        software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian \$(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get -y install docker-ce-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
USER jenkins
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]
EOF

echo "3 - Create docker-compose file"
echo "
version: '3'
services:
  jenkins:
    image: 'jenkins-docker:v1.1'
    container_name: jenkinsdood
    restart: always
    user: 0:0
    ports:
      - '8080:8080'
      - '443:8443'
      - '50000:50000'
    volumes:
      - 'jenkins_data_dood:/var/jenkins_home/'
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock
    networks:
      dockerisator:
        ipv4_address: 192.168.111.10
volumes:
  jenkins_data_dood:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/jenkinsdood/
networks:
  dockerisator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.111.0/24
" >$DIR/docker-compose-jenkins-dood.yml

echo "4 - Build Jenkins Docker Image"
docker build -t jenkins-docker:v1.1 $DIR

echo "5 - Start Jenkins"
docker compose -f $DIR/docker-compose-jenkins-dood.yml up -d

}

jenkinsdind() {

echo
echo "Install Jenkins Docker in docker to use the docker of the container"

echo "1 - Create directories ${DIR}/jenkinsdind/"
mkdir -p $DIR/jenkinsdind/
mkdir -p $DIR/dockerdind/
mkdir -p $DIR/certs/

echo "2 - Create Dockerfile"
cat <<EOF >$DIR/Dockerfile
FROM jenkins/jenkins:lts
USER root
RUN apt-get update && \
    apt-get -y install apt-transport-https \
                        ca-certificates \
                        curl \
                        gnupg-agent \
                        software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian \$(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get -y install docker-ce-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
USER jenkins
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]
EOF

cat server.crt server.key > server.pem

echo "4 - Create docker-compose file"
echo "
version: '3'
services:
  jenkins:
    image: 'jenkins-docker:v1.1'
    privileged: true
    container_name: jenkinsdind
    restart: always
    user: root
    ports:
      - '8080:8080'
      - '443:8443'
      - '50000:50000'
    volumes:
      - 'jenkins_data_dind:/var/jenkins_home/'
      - certs:/certs
    environment:
      - DOCKER_HOST=tcp://docker:2376
      - DOCKER_TLS_VERIFY=1
      - DOCKER_CERT_PATH=/certs/client/

  docker:
    image: docker:dind
    privileged: true
    ports:
      - "2375:2376"
      - "1337:8888"
    volumes:
      - docker_data:/var/lib/docker
      - certs:/certs
    environment:
      - DOCKER_TLS_CERTDIR=/certs
volumes:
  jenkins_data_dind:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/jenkinsdind/

  docker_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/dockerdind/
      
  certs:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/certs/
" >$DIR/docker-compose-jenkins-dind.yml

echo "5 - Build Jenkins Docker Image"
docker build -t jenkins-docker:v1.1 $DIR

echo "6 - Start Jenkins"
docker compose -f $DIR/docker-compose-jenkins-dind.yml up -d

echo " plus qu'a lancer : docker run -d -p 8888:80 nginx:latest     ... ainsi en accedant a l'ip de mon HOST:1337 je redirige sur le 8888 de mon dind qui redirigera sur le conteneur fraichement crée !!"

}


gitlab() {

echo
echo "Install Gitlab"

echo "1 - Create directories ${DIR}/gitlab/ and $DIR/runner"
mkdir -p $DIR/gitlab/{config,data,logs}
mkdir $DIR/runner

echo "2 - Create docker-compose file"
echo "
version: '3.0'
services:
  web:
    image: 'gitlab/gitlab-ce:latest'
    container_name: gitlab
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.example.com'
    expose: 
      - 5000
    ports:
      - 80:80
      - 443:443
      - 5000:5000
    volumes:
      - gitlab_config:/etc/gitlab/
      - gitlab_logs:/var/log/gitlab/
      - gitlab_data:/var/opt/gitlab/
    networks:
      dockerisator:
        ipv4_address: 192.168.111.3  

volumes:
  gitlab_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/gitlab/data
  gitlab_logs:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/gitlab/logs
  gitlab_config:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/gitlab/config
  runner_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/runner/data

networks:
  dockerisator:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.111.0/24 
" >$DIR/docker-compose-gitlab-runner.yml

echo "3 - Démarrer Gitlab"
docker compose -f $DIR/docker-compose-gitlab-runner.yml up -d

echo "Add ip of gitlab container and url gitlab.example.com in YOUR /etc/hosts"
echo "Add ip of gitlab container and url gitlab.example.com in RUNNER /etc/hosts"

}

postgres() {

echo
echo "Install Postgres"

echo "1 - Create directories ${DIR}/postgres/"
mkdir -p $DIR/postgres/

echo "
version: '3.0'
services:
  web:
   image: postgres:latest
   container_name: postgres
   environment:
   - POSTGRES_USER=myuser
   - POSTGRES_PASSWORD=myuserpassword
   - POSTGRES_DB=mydb
   ports:
   - 5432:5432
   volumes:
   - postgres_data:/var/lib/postgresql/data/
   networks:
     dockerisator:
       ipv4_address: 192.168.111.20 
volumes:
  postgres_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/postgres
networks:
  dockerisator:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.111.0/24 
" >$DIR/docker-compose-postgres.yml

echo "2 - Run Postgres"
docker compose -f $DIR/docker-compose-postgres.yml up -d

echo "
Credentials:
		user: myuser
		password: myuserpassword
		db: mydb
		port: 5432

command : psql -h <ip> -u myuser mydb

"

}

prometheus() {
echo
echo "Install Prometheus"

echo "1 - Create directories ${DIR}/prometheus/{etc,data}"
mkdir -p $DIR/prometheus/etc
mkdir -p $DIR/prometheus/data
chmod 775 -R $DIR/prometheus/

echo "2 - Create config file prometheus.yml "
echo "
global:
  scrape_interval:     5s # By default, scrape targets every 15 seconds.
  evaluation_interval: 5s # By default, scrape targets every 15 seconds.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first.rules"
  # - "second.rules"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
- job_name: 'node'
  static_configs:
  #- targets: ['172.37.1.1:9100']
" > $DIR/prometheus/etc/prometheus.yml


echo "3 - Create docker compose for prometheus "
echo "
version: '3'
services:
  prometheus:
    image: quay.io/prometheus/prometheus:v2.0.0
    container_name: prometheus
    volumes:
     - prometheus_etc:/etc/prometheus/
     - prometheus_data:/prometheus/
    command: '--config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus'
    ports:
     - 9090:9090
    networks:
      dockerisator:
        ipv4_address: 192.168.111.5  
volumes:
  prometheus_etc:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/prometheus/etc/
  prometheus_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/prometheus/data/
networks:
  dockerisator:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.111.0/24 
" > $DIR/docker-compose-prometheus.yml

echo "4 - Run Prometheus "
docker compose -f $DIR/docker-compose-prometheus.yml up -d

echo "
localhost:9090 for access
"

}

grafana() {
echo
echo "Install Grafana"

echo "1 - Create directories ${DIR}/grafana/{etc,data}"
mkdir -p $DIR/grafana/etc
mkdir -p $DIR/grafana/data
chmod 775 -R $DIR/grafana/

echo "2 - Create docker compose for grafana"

echo "
version: '3'
services:
  grafana:
    image: grafana/grafana
    container_name: grafana
    user: 0:0
    ports:
     - 3000:3000
    volumes:
     - grafana_data:/var/lib/grafana
     - grafana_etc:/etc/grafana/provisioning/
    networks:
      dockerisator:
        ipv4_address: 192.168.111.6  
volumes:
  grafana_etc:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/grafana/etc/
  grafana_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/grafana/data/
networks:
  dockerisator:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.111.0/24 
" > $DIR/docker-compose-grafana.yml

echo "3 - Run Grafana "
docker compose -f $DIR/docker-compose-grafana.yml up -d
sleep 30s

echo "
Default Credentials:
		user: admin
		password: admin
"

echo "4 - Auto setup for local prometheus"
curl --user admin:admin "http://localhost:3000/api/datasources" -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"test","isDefault":true ,"type":"prometheus","url":"http://localhost:9090","access":"proxy","basicAuth":false}'
curl --user admin:admin "http://localhost:3000/api/datasources" -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"test","isDefault":true ,"type":"loki","url":"http://localhost:3100","access":"proxy","basicAuth":false}'
echo "
localhost:3000 for access
"
}


graylog() {

echo
echo "Install Graylog"

echo "1 - Create directories ${DIR}/graylog/"
mkdir -p $DIR/graylog/{mongo,elastic,graylog}

echo "
version: '2'
services:
  mongodb:
    restart: always
    image: mongo:4.2
    networks:
      dockerisator:
        ipv4_address: 192.168.111.152  
    volumes:
      - mongo_data:/data/db

  elasticsearch:
    restart: always
    image: docker.elastic.co/elasticsearch/elasticsearch-oss:7.10.2
    #data folder in share for persistence
    volumes:
      - es_data:/usr/share/elasticsearch/data
    environment:
      - http.host=0.0.0.0
      - transport.host=localhost
      - network.host=0.0.0.0
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    mem_limit: 1g
    networks:
      dockerisator:
        ipv4_address: 192.168.111.151  

  graylog:
    image: graylog/graylog:4.2
    mem_limit: 1g
    cpus: 1.5
    cap_drop:
      - chown
      - dac_override
      - fowner
      - fsetid
      - kill
      - mknod
      - setpcap
      - setfcap
      - setuid
      - setgid
    volumes:
      - graylog_journal:/usr/share/graylog/data/journal
    environment:
      # CHANGE ME (must be at least 16 characters)!
      - GRAYLOG_PASSWORD_SECRET=Globulus123.Globulus123.
      # Password: Globulus123.
      # echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1
      - GRAYLOG_ROOT_PASSWORD_SHA2=b3db479e5e65b2a43c04ba32f6ae04cfc1a5e1fa7765d018ea5ed9b66dccd4c6
      - GRAYLOG_HTTP_EXTERNAL_URI=http://127.0.0.1:9000/
      - GRAYLOG_WEB_ENDPOINT_URI=http://127.0.0.1:9000/api
    entrypoint: /usr/bin/tini -- wait-for-it elasticsearch:9200 --  /docker-entrypoint.sh
    networks:
      dockerisator:
        ipv4_address: 192.168.111.150  
    links:
      - mongodb:mongo
      - elasticsearch
    restart: always
    depends_on:
      - mongodb
      - elasticsearch
    ports:
      # Graylog web interface and REST API
      - 9777:9000
      # Syslog TCP
      - 1514:1514
      # Syslog UDP
      - 1514:1514/udp
      # GELF TCP
      - 12201:12201
      # GELF UDP
      - 12201:12201/udp


volumes:
  mongo_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/graylog/mongo/
  es_data:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/graylog/elastic/
  graylog_journal:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ${DIR}/graylog/graylog/

networks:
  dockerisator:
   driver: bridge
   ipam:
     config:
       - subnet: 192.168.111.0/24
" >$DIR/docker-compose-graylog.yml

echo "2 - Run Graylog"
docker compose -f $DIR/docker-compose-graylog.yml up -d

echo "
localhost:9777 for access
"

}


# Let's Go !! parse args  ####################################################################

parse_options $@

ip