# -*- mode: ruby -*-
# vi: set ft=ruby :

cluster = {
  "collins.genesis" => { :ip => "192.168.60.11", :cpus => 2, :mem => 4096 },
  "oscar.genesis" => { :ip => "192.168.60.12", :cpus => 2, :mem => 4096 }
}

Vagrant.configure("2") do |config|
  config.vm.define "phil.genesis" do |config|
    config.vm.box = "generic/ubuntu1804"
    config.vm.network :private_network, ip: "192.168.60.10"
    config.vm.provider :libvirt do |vb|
      vb.cpus = 4
      vb.memory = 8192
      vb.storage :file, :size => '20G'
      vb.storage :file, :size => '20G'
      vb.storage :file, :size => '20G'
    end
    config.vm.hostname = "phil.genesis"
    config.vm.synced_folder './', '/vagrant', type: 'rsync'
    config.vm.provision :shell, inline: <<-SHELL
      set -eux
      export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
      rm -rf /etc/resolv.conf
      echo "nameserver 8.8.8.8" > /etc/resolv.conf
      apt-get update
      apt-get dist-upgrade -y
      apt-get install -y cpu-checker
      kvm-ok

      cd /vagrant/scripts; time bash master.sh
    SHELL
  end

  cluster.each_with_index do |(hostname, info), index|
    config.vm.define hostname do |config|
      config.vm.box = "generic/ubuntu1804"
      config.vm.network :private_network, ip: "#{info[:ip]}"
      config.vm.provider :libvirt do |vb|
        vb.cpus = info[:cpus]
        vb.memory =info[:mem]
        vb.storage :file, :size => '20G'
        vb.storage :file, :size => '20G'
        vb.storage :file, :size => '20G'
      end
      config.vm.hostname = hostname
      config.vm.synced_folder './', '/vagrant', type: 'rsync'
      config.vm.provision :shell, inline: <<-SHELL
        set -eux
        export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
        rm -rf /etc/resolv.conf
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        apt-get update
        apt-get dist-upgrade -y
        apt-get install -y cpu-checker
        kvm-ok

        cd /vagrant/scripts; time bash worker.sh
      SHELL
    end
  end
end
