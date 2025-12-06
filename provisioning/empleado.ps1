# Configuracion del empleado
# 1. Configuracion DNS
Write-Output "--- CONFIGURANDO DNS ---"
Set-DnsClientServerAddress -InterfaceAlias "Ethernet*" -ServerAddresses "192.168.10.5"
# 2. Instalacion del agente wazuh
Write-Output "--- DESCARGANDO E INSTALANDO AGENTE WAZUH"
# Definimos la url oficial del instalador
$WazuhUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.1-1.msi"
$Output = "C:\wazuh-agent.msi"
# Descargamos el archivo
Invoke-WebRequest -Uri $WazuhUrl -OutFile $Output
# Instalamos
Write-Output "Instalando MSI"
Start-Process msiexec.exe -ArgumentList "/i $Output /q WAZUH_MANAGER=192.168.10.10 WAZUH_REGISTRATION_SERVER=192.168.10.10" -Wait
# Iniciamos el servicio
Start-Service -Name WazuhSvc
# 3. Union al dominio
Write-Output "--- UNIENDOSE AL DOMINIO pyme.local ---"
# Definimos el nombre del dominio y el usuario administrador
$Dominio = "pyme.local"
$Usuario = "Administrator@pyme.local"
$Password = "Password1234!"
$SecPass = ConvertTo-SecureString $Password -AsPlainText -Force
$Credenciales = New-Object System.Management.Automation.PSCredential($Usuario, $SecPass)
# Ejecutamos la union al dominio
Add-Computer -DomainName $Dominio -Credential $Credenciales -Restart -Force
