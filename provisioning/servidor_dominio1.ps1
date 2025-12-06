# Cambio de nombre del equipo
# Definimos el nombre deseado
$NewName = "Servidor-Control" 

# Comprobamos si el equipo ya tiene el nombre correcto
if ($env:COMPUTERNAME -eq $NewName) {
    Write-Output "El equipo ya se llama $NewName. No es necesario reiniciar."
} 
else {
    Write-Output "El nombre actual es $($env:COMPUTERNAME). Renombrando a $NewName..."
    
    # Renombrar el equipo
    Rename-Computer -NewName $NewName -Force
    
    # Reiniciar inmediatamente para aplicar cambios
    # Esto cortará la conexión con Vagrant, pero es NECESARIO la primera vez.
    Restart-Computer -Force
}
