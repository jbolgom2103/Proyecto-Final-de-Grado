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
# 2 Instalacion del SIEM
echo "--- INICIANDO INSTALACION DE WAZUH/OPENSEARCH"
# 2.1 Actualizamos e instalamos los paquetess basicos
echo "Actualizando e instalando paquetes basicos"
sudo apt update -y
sudo apt install curl tar unzip -y
# 2.2 Descargamos el instalador oficial
echo "Descargando el scrip de la instalacion automatica"
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
# 2.3 Ejecutamos el asistente de instalacion
echo "Ejecutando el asistente de instalacion"
sudo bash ./wazuh-install.sh -a -i
# 2.4 Recuperamos las contraseñas creadas
echo "-- INSTALACION FINALIZADA"
echo "Las contraseñas generadas se han guardado en el archivo wazuh-passwords.txt"
if [ -f wazuh-passwords.txt ]; then
    echo "========================================================"
    echo "   CREDENCIALES DE ACCESO A WAZUH (GUARDA ESTO)         "
    echo "========================================================"
    cat wazuh-passwords.txt
    echo "========================================================"
fi
# ====================================================
#  INTEGRACIÓN CON TELEGRAM (Alertas Nivel 7+) y SOAR (Alertas Nivel 10+)
# ====================================================

# 1. Variables de Telegram (¡CÁMBIALAS POR LAS TUYAS!)
TELEGRAM_TOKEN="TU_TOKEN_DEL_BOT"
TELEGRAM_CHAT_ID="TU_ID_DE_TELEGRAM"

echo "--- [SIEM] Configurando integración con Telegram ---"

# 2. Crear el script de integración personalizado (Python)
cat <<EOF > /var/ossec/integrations/custom-telegram.py
#!/usr/bin/env python3
import sys
import json
import urllib.request

# Argumentos que pasa Wazuh
alert_file = sys.argv[1]
msg_header = " *WAZUH ALERT* "

# Leer la alerta
with open(alert_file) as f:
    alert_json = json.load(f)

# Extraer datos clave
level = alert_json['rule']['level']
description = alert_json['rule']['description']
agent = alert_json['agent']['name']
rule_id = alert_json['rule']['id']

# Filtrado de seguridad
if level < 7:
    sys.exit()

# Construir el mensaje
message = f"{msg_header}\n\n"
message += f" *Nivel:* {level}\n"
message += f" *Agente:* {agent}\n"
message += f" *Regla:* {rule_id}\n"
message += f" *Detalle:* {description}\n"

# Datos para la API de Telegram
token = "$TELEGRAM_TOKEN"
chat_id = "$TELEGRAM_CHAT_ID"
url = f"https://api.telegram.org/bot{token}/sendMessage"

data = {
    "chat_id": chat_id,
    "text": message,
    "parse_mode": "Markdown"
}

# Enviar petición
req = urllib.request.Request(url, json.dumps(data).encode('utf-8'), {'Content-Type': 'application/json'})
try:
    urllib.request.urlopen(req)
except Exception as e:
    # Escribir error en un log local si falla
    with open('/var/ossec/logs/integrations.log', 'a') as log:
        log.write(f"Telegram Error: {str(e)}\n")

EOF

# 3. Permisos y Propietario
chmod 750 /var/ossec/integrations/custom-telegram.py
chown root:wazuh /var/ossec/integrations/custom-telegram.py

# 4. Modificar la configuración de Wazuh (ossec.conf)
# Añadimos el bloque de respuesta ante los ataques antes del bloque de integracion
# Añadimos el bloque de integración al final del archivo, antes de </ossec_config>
echo "--- [SIEM] Inyectando configuración en ossec.conf ---"

# Hacemos una copia de seguridad por si acaso
cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.bak
# Borramos la ultima linea que es <\ossec.conf> para que no de problemas al añadir nuestro bloque
head -n -1 /var/ossec/etc/ossec.conf > /tmp/ossec.conf.tmp

mv /tmp/ossec.conf.tmp /var/ossec/etc/ossec.conf

cat <<EOF >> /var/ossec/etc/ossec.conf

  <active-response>
    <command>firewall-drop</command>
    <location>local</location>
    <level>10</level>
    <timeout>600</timeout>
  </active-response>

  <integration>
    <name>custom-telegram.py</name>
    <level>7</level>
    <hook_url>https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage</hook_url>
    <alert_format>json</alert_format>
  </integration>

</ossec_config>
EOF
# Ajustamos permisos para asegurarnos que sean correctos
chown root:wazuh /var/ossec/etc/ossec.conf
chmod 640 /var/ossec/etc/ossec.conf
# 5. Reiniciar el Manager para aplicar cambios
echo "--- [SIEM] Reiniciando Wazuh Manager... ---"
systemctl restart wazuh-manager

