# PFG-ASIR-SIEM: Automatización de Infraestructura de Seguridad para PYMES

[![Vagrant](https://img.shields.io/badge/Vagrant-2.4-blue.svg)](https://www.vagrantup.com/)
[![VirtualBox](https://img.shields.io/badge/VirtualBox-7.0-blue.svg)](https://www.virtualbox.org/)
[![Wazuh](https://img.shields.io/badge/Wazuh-4.x-orange.svg)](https://wazuh.com/)

Este proyecto despliega de forma **completamente automatizada** una infraestructura de red corporativa segura, diseñada para Pequeñas y Medianas Empresas (PYMES).

Integra **Active Directory** para la gestión de identidades y **Wazuh SIEM** para la monitorización de seguridad y respuesta ante incidentes (SOAR), todo desplegado mediante **Infraestructura como Código (IaC)**.

---

## Arquitectura del Sistema

La infraestructura simula una red corporativa real (`192.168.10.0/24`) con 5 nodos virtualizados:


| Máquina | SO | Rol | IP |
| :--- | :--- | :--- | :--- |
| **DC-SERVER** | Windows Server 2019 | Controlador de Dominio (AD DS), DNS. | `192.168.10.5` |
| **SIEM-SERVER** | Ubuntu 22.04 LTS | Wazuh Manager, OpenSearch, Dashboard. | `192.168.10.10` |
| **WEB-APACHE** | Ubuntu 22.04 LTS | Servidor Web corporativo (Apache2). | `192.168.10.30` |
| **DB-SERVER** | Ubuntu 22.04 LTS | Base de datos (MariaDB). | `192.168.10.40` |
| **PC-Empleado** | Windows 10 | Estación de trabajo unida al dominio. | `192.168.10.50` |

---

## Instalación y Despliegue

### Requisitos Previos
* **CPU:** Virtualización activada (VT-x/AMD-V).
* **RAM:** Mínimo 16 GB recomendados.
* **Software:** [VirtualBox](https://www.virtualbox.org/) y [Vagrant](https://www.vagrantup.com/) instalados.
* **Almacenamiento:** Minimo 50 GB recomendados.

### Pasos
1.  **Clonar el repositorio:**
    ```bash
    git clone (https://github.com/jbolgom2103/Proyecto-Final-de-Grado.git)
    cd PFG-ASIR-SIEM
    ```

2.  **Configurar el entorno:**  
Edita `config.yaml` si necesitas ajustar la RAM o las IPs.

3.  **Desplegar la infraestructura:**
    Ejecuta el comando mágico:
    ```bash
    vagrant up
    ```
    *Tiempo estimado: 20-45 minutos (dependiendo de tu conexión a internet y disco SSD).*

4.  **Acceder al Dashboard:**
    * URL: `https://localhost:8443`
    * Usuario: `admin`
    * Contraseña: La generada al final del despliegue del SIEM (consulta los logs).

---

## Estructura del Proyecto y Scripts

El proyecto utiliza una estructura modular donde la lógica de aprovisionamiento está separada de la definición de la infraestructura.

```text
PFG-ASIR-SIEM/
├── Vagrantfile             # Orquestador principal (Lee config.yaml)
├── config.yaml             # Variables (IPs, RAM, Nombres)
└── provisioning/           # Scripts de automatización
    ├── servidor_dominio1.ps1
    ├── servidor_dominio2.ps1
    ├── servidor_siem.sh
    ├── servidor_web.sh
    ├── servidor_bd.sh
    └── empleado.ps1
```

### Explicación de los Scripts

#### 1. `servidor_dominio1.ps1` y `servidor_dominio2.ps1` (Windows)
* **Función:** Configuran el corazón de la red.
* **Lógica:**
    * **Fase 1:** Renombra el servidor a `Servidor-Control` y gestiona el reinicio obligatorio de Windows de forma idempotente (no falla si ya está renombrado).
    * **Fase 2:** Instala el rol de **Active Directory Domain Services**, promueve el servidor a Controlador de Dominio (`pyme.local`), configura el DNS y establece la contraseña del Administrador.

#### 2. `servidor_siem.sh` (Linux)
* **Función:** Despliega la inteligencia de seguridad.
* **Lógica:**
    * Instala dependencias y descarga el instalador oficial de Wazuh.
    * Ejecuta la instalación desatendida (`-a -i`) para levantar Manager, Indexer y Dashboard.
    * **Integración SOAR:** Inyecta automáticamente la configuración XML en `ossec.conf` para bloquear ataques (Active Response).
    * **Integración Telegram:** Crea un script en Python (`custom-telegram.py`) y lo conecta al gestor de alertas para notificar incidentes de Nivel > 7. Este es el unico script que tienes que tocar a mano debido a que tienes que colocar el token de tu bot creado con @botfather y tu id de telegram que te lo da @userinfobot, estos datos son totalmente personales debido a que con ellos pueden tener acceso a tu bot.

#### 3. `servidor_web.sh` y `servidor_bd.sh` (Linux)
* **Función:** Simulan la infraestructura de producción.
* **Lógica:**
    * **Unión al Dominio:** Usan `realmd` y `sssd` para unir máquinas Linux al Directorio Activo de Windows, permitiendo login centralizado.
    * **Servicios:** Instalan Apache2 y MariaDB respectivamente y crea una base y un usario de prueba ademas de una pequeña web, se puede editar a disposicion.
    * **Agente Wazuh:** Instalan y conectan el agente de seguridad al SIEM.

#### 4. `empleado.ps1` (Windows)
* **Función:** Simula un puesto de trabajo corporativo.
* **Lógica:**
    * Configura el DNS para apuntar al DC.
    * Instala el agente Wazuh (MSI) de forma silenciosa.
    * Une el equipo al dominio `pyme.local` usando credenciales seguras.

---

## Capacidades de Seguridad (Pruebas de Concepto)

El laboratorio viene pre-configurado para detectar y responder a:

1.  **Ataques de Fuerza Bruta:**
    * Si intentas loguearte fallidamente 10 veces en el `PC-Empleado`, recibirás una alerta en Telegram.
2.  **Ataques Web (SQL Injection / Shellshock):**
    * Lanzar `curl ... OR 1=1` contra el servidor web genera una alerta crítica.
    ![visualizacion ataque](/imagenes/visualizacion_ataque.png)
3.  **Respuesta Activa (SOAR):**
    * Si se detecta un ataque de fuerza bruta SSH contra los servidores Linux, el firewall bloqueará la IP del atacante automáticamente durante 10 minutos.
![respuesta ataque](/imagenes/respuesta_ataque.png)

##  Autor

**Juan Felipe Duque Bolivar**
*Proyecto Final de Grado Superior ASIR (Administración de Sistemas Informáticos en Red).*