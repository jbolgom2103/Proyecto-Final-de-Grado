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
# 2. Instalacion del servidor web
echo "--- INICIANDO CONFIGURACION DEL SERVIDOR WEB ---"
# 2.1 Configuracion DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
# 2.2 Instalamos Apache
echo "--- Instalando apache2 y creando web ---"
apt-get update
apt-get install -y apache2
# Creamos una pagina de pruebas
echo "<h1>Sitio Web Corporativo - Monitorizado por Wazuh</h1>" | tee /var/www/html/index.html
# 2.3 Instalacion del Agente Wazuh
echo "--- Instalando y configurando el agente wazuh ---"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list
apt-get update
WAZUH_MANAGER="192.168.10.10" apt-get install -y wazuh-agent
# 2.4 Habilitamos y arrancamos el servicio
echo "--- Arrancando servicios ---"
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
systemctl restart apache2
