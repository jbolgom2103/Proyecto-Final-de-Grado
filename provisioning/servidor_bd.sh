#!/bin/bash
set -e -u
# 1. Union al dominio
# 1.1 Variables de configuracion
DOMAIN="pyme.local"
AD_USER="Administrator"
AD_PASSWORD="Password1234!"
DC_IP="192.168.10.5"
# 1.2 Configuracion de DNS
echo "--- INICIANDO CONFIGURACION DE ACTIVE DIRECTORY ---"
systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm -f /etc/resolv.conf
echo "nameserver $DC_IP" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
# 1.3 Sincronizamos la hora con el servidor de dominio
echo "--- Sincronizando reloj ---"
sudo timedatectl set-local-rtc 1
# 1.4 Instalamos los paquetes necesarios
echo "--- Instalando dependencias de AD ---"
apt update
apt-get install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin packagekit
# 1.5 Union al dominio
echo "--- Uniéndose al dominio $DOMAIN ---"
# 1.6 Configuracion post union
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0022" >> /etc/pam.d/common-session
echo $AD_PASSWORD | realm join -U $AD_USER $DOMAIN --verbose
echo "--- [AD] Unión completada. Estado del dominio: ---"
realm list
# 2. Instalacion base de datos
echo "--- INICIANDO CONFIGURACION DE LA BASE DE DATOS ---"
# 2.1 Configuracion inicial
echo "nameserver 8.8.8.8"  | sudo tee /etc/resolv.conf > /dev/null
# 2.2 Instalamos MariaDB
echo "--- Instalando MariaDB"
apt-get update
apt-get install -y mariadb-server
# 2.3 Configuracion MariaDB
sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb
# 2.4 Creacion de base de datos y usuario
echo "--- Creando base de prueba ---"
mysql -e "CREATE DATABASE IF NOT EXISTS pyme_db;"
mysql -e "CREATE USER IF NOT EXISTS 'usuario1'@'192.168.10.%' IDENTIFIED BY 'Contraseñaseguradb';"
mysql -e "GRANT ALL PRIVILEGES ON pyme_db.* TO 'usuario1'@'192.168.10.%';"
mysql -e "FLUSH PRIVILEGES;"
# 2.5 Instalacion del agente Wazuh
echo "--- Instalando Agente Wazuh ---"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
apt-get update
WAZUH_MANAGER="192.168.10.10" apt-get install -y wazuh-agent
# 2.6 Arrancamos el agente
systemctl enable wazuh-agent
systemctl start wazuh-agent