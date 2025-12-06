# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
# 1. Cargar la configuración desde el archivo YAML
settings = YAML.load_file('config.yaml')
GLOBAL_NET = settings['global']['network_prefix']

Vagrant.configure("2") do |config|

  # 2. Iterar sobre cada máquina definida en el YAML
  settings['machines'].each do |machine|
    
    config.vm.define machine['name'] do |node|
      
      # --- Configuración Básica ---
      node.vm.box = machine['box']
      node.vm.hostname = machine['hostname']
      
      # --- Red  ---
      node.vm.network "private_network", ip: "#{GLOBAL_NET}.#{machine['ip']}"
      
      # --- Puertos ---
      if machine['ports']
        machine['ports'].each do |port|
          node.vm.network "forwarded_port", guest: port['guest'], host: port['host'], protocol: "tcp"
        end
      end

      # --- Hardware (VirtualBox) ---
      node.vm.provider "virtualbox" do |v|
        v.name = "PFG_#{machine['name']}" # Nombre en la lista de VBox
        v.memory = machine['ram']
        v.cpus = machine['cpus']
        v.gui = machine['gui']
        
        # Optimización para Linked Clones (Ahorra espacio)
        v.linked_clone = true 
      end

      # --- Provisioning (Scripts) ---
      if machine['scripts']
        machine['scripts'].each do |script_path|
          # Detectar si es Windows para usar PowerShell o Linux para Shell
          if machine['os_type'] == "windows"
            node.vm.provision "shell", path: script_path, privileged: false
          else
            node.vm.provision "shell", path: script_path
          end
        end
      end

    end 
  end

end