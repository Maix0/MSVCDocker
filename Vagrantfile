# Vagrant File (Vagrantfile)
# http://docs.vagrantup.com/v2/vagrantfile/index.html

Vagrant.require_version ">= 2.1.4"

# plugin checks
required_plugins = %w(vagrant-reload)
required_plugins.each do |plugin|
    raise "\"#{plugin}\" plugin is not installed!" unless Vagrant.has_plugin? plugin
end

# bring in provisioner that lets us do Posix SSH on windows
require_relative 'vagranttools/ssh_provisioner.rb'

Vagrant.configure("2") do |config|
    config.vm.define "win-msvc14" do |vmconfig|
        vmconfig.vm.box = "gusztavvargadr/windows-10"
        vmconfig.vm.guest = :windows

        vmconfig.ssh.username = vmconfig.winrm.username
        vmconfig.ssh.password = vmconfig.winrm.password
        vmconfig.ssh.insert_key = false
        vmconfig.vm.synced_folder "build", "/vagrant"

        vmconfig.vm.synced_folder ".", "/dev"

        vmconfig.vm.provider :virtualbox do |v, override|
            v.name = "win-msvc14"
            v.linked_clone = true
            v.memory = 4096

            # set the vm's cpus to the number of host cpus
            if RUBY_PLATFORM.downcase.include? "darwin"
                v.cpus = `sysctl -n hw.physicalcpu`
            elsif RUBY_PLATFORM.downcase.include? "linux"
                v.cpus = `nproc`
            else 
                v.cpus = 4;
            end
        end

        vmconfig.vm.communicator = "winrm"
        vmconfig.vm.provision "shell", path: "vagranttools/setup_basic.ps1"

        outputdir = "\\\\vboxsvr\\vagrant\\msvc14\\snapshots"
        snapshot1dir= "#{outputdir}\\SNAPSHOT-01"
        snapshot2dir= "#{outputdir}\\SNAPSHOT-02"
        cmpdir= "#{outputdir}\\CMP"

        vmconfig.vm.provision "shell", path: "vagranttools/snapshot.bat", args: [ snapshot1dir ]
        vmconfig.vm.provision "shell", path: "vagranttools/setup_msvc.ps1", 
                                            args: [ "-msvc_ver", 14, "-output_dir", snapshot2dir ]
        vmconfig.vm.provision :reload
        
        vmconfig.vm.provision "shell", path: "vagranttools/snapshot.bat", args: [ snapshot2dir ]
        
        vmconfig.vm.provision "shell", path: "vagranttools/compare-snapshots.bat", 
                                        args: [ snapshot1dir, snapshot2dir, cmpdir ]
    end
end
