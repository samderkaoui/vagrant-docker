# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
    (1..NodeCount).each do |i|
      config.vm.define "worker#{i}" do |worker|
        worker.vm.box = "ubuntu/jammy64"
        worker.vm.synced_folder '.', '/vagrant' 
        worker.vm.hostname = "wazuh-agent#{i}"
        worker_ip = "192.168.10.#{i+50}"
        worker.vm.network "private_network", ip: worker_ip
        worker.vm.provider "virtualbox" do |v|
          v.name = "wazuh-agent#{i}"
          v.memory = 2048
          v.cpus = 2
        end
        worker.vm.provision "shell", inline: <<-SHELL
        # Modify SSH configuration
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config 
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config 
        sed 's@session\\s*required\\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
        sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
        sudo systemctl reload sshd
        # Stop UFW
        sudo systemctl stop ufw && sudo systemctl disable ufw
        # Update
        apt update -y && apt upgrade -y
    SHELL
      
        worker.vm.provision "shell", path: "./agent.sh"
      end



    end
  end
