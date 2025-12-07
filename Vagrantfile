# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
# 1. Cargar la configuración desde el archivo YAML
settings = YAML.load_file('config.yaml')
GLOBAL_NET = settings['global']['network_prefix']

Vagrant.configure("2") do |config|
  # --- CONFIGURACIÓN PARA DISCOS LENTOS / EXTERNOS ---
  
  # Enviar una señal de "estoy vivo" cada 30 segundos
  config.ssh.keep_alive = true
  
  # Forzar al cliente SSH a no desconectar aunque la VM no responda en un rato
  # ServerAliveInterval=30: Manda un paquete cada 30s
  # ServerAliveCountMax=60: Espera hasta 60 fallos antes de rendirse (30s * 60 = 30 minutos de paciencia)
  config.ssh.extra_args = ["-o", "ServerAliveInterval=30", "-o", "ServerAliveCountMax=60", "-o", "TCPKeepAlive=yes"]

  # Aumentar el tiempo de espera de arranque (boot) a 20 minutos
  # Vital para discos externos
  config.vm.boot_timeout = 1200
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