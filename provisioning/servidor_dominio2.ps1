# Configuracion del servidor principal
# Comprobamos si el servidor de dominio ya esta instalado para que no explote
$CheckDC = Get-WindowsFeature -Name AD-Domain-Services
# Cambiamos la contraseña a la cual queramos, por defecto es vagrant
$AdminLocal = [ADSI]"WinNT://localhost/Administrator,user"
$AdminLocal.SetPassword("Password1234!")
if ($CheckDC.Installed -eq $false) {
    Write-Output "---INICIANDO INSTALACION DE ACTIVE DIRECTORY---"
    # 1. Instalar active directory
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Write-Output "- Herramientas instaladas"
    # 2. Configurar parametros para el servidor
    $NombreDominio = "pyme.local"
    $NombreNetBios = "Pyme"
    $ModoSeguroPwd = ConvertTo-SecureString "Password1234!" -AsPlainText -Force
    # 4. Promovemos el servidor a controlador de dominio
    Write-Output "- Creando el dominio pyme.local... El servidor se reiniciara solo"
    Install-ADDSForest -DomainName $NombreDominio -DomainNetBiosName $NombreNetBios -SafeModeAdministratorPassword $ModoSeguroPwd -InstallDns -Force -Confirm:$false
} else {
    Write-Output "--- EL SERVIDOR YA ES UN CONTROLADOR DE DOMINIO. ---"
}