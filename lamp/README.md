# LAMP

Infraestructura formada por un servidor web corriendo jun sistema LAMP: Linux-Apache-PHP-MySQL. Tanto con Virtualbox como con incus/lxd, el proceso de instalación y configuración del servidor está automatizado y no requiere intervención manual de ningún tipo. Existen dos versiones:

- genérico donde se hace la instalación del sistema LAMP.
- wordpress donde se hace la instalación del sistema LAMP y se crea una base de datos llamada *wordpress* donde un usuario *wordpress* con contraseña *Abc123..* tiene todos los permisos.

 Se trata de un infraestructura muy sencilla que puede tomarse como base para implementar otras más complejas.

- **lamp**:
  - Ubuntu 22.04 LTS.
  - servidor web con Apache+PHP+MySQL.

## Virtualbox

![lamp-virtualbox](imagenes/lamp-virtualbox.svg)

- la interfaz de server está configurada en modo *host only* (solo anfitrión) usando la red 192.168.56.0/24.

### Archivos

Los archivos con la palabra wordpress gestionan el despliegue del sistema LAMP con la base de datos wordpress indicada anteriormente.

- **Vagrantfile**: es posible personalizar la *box* usada, dirección IP de server, caracterísiticas de la máquina (RAM, cpu, gui visible o no, ...) y carpeta compartida entre la máquina server y el host anfitrión.
- **lamp_generico.sh**: script de aprovisionamiento para instalar y configurar el sistema:
  - permite configurar caché APT para acelerar el proceso de descarga de paquetes.
  - actualiza el sistema.
  - instala y configura paquetes (Apache, php, módulos php, net-tools, msql-client, ...).
  - habilita el sitio por defecto http/https y crea páginas index.php, info.php y descarga [Adminer](https://www.adminer.org/)


### Despliegue

```bash
$ mkdir www
$ vagrant validate
Vagrantfile validated successfully.
$ vagrant up
$ vagrant status
Current machine states:

default                   running (virtualbox)

The VM is running. To stop this VM, you can run `vagrant halt` to
shut it down forcefully, or you can run `vagrant suspend` to simply
suspend the virtual machine. In either case, to restart it again,
simply run `vagrant up`
```
[![asciicast](https://asciinema.org/a/649977.svg)](https://asciinema.org/a/649977)

En el caso de querer montar la infraestructura con la base de datos wordpress:

```bash
$ mkdir www
$ cp Vagrantfile_wordpress Vagrantfile
$ vagrant validate
Vagrantfile validated successfully.
$ vagrant up
```

Para destruir la infraestructura:

```bash
$ vagrant destroy -f
==> default: Forcing shutdown of VM...
==> default: Destroying VM and associated drives.
```

## Incus /LXD

![lamp-incus_lxd](imagenes/lamp-incus_lxd.svg)

### Archivos

Similar para incus y lxd:

- **config_lamp_generico_incus.yml**: fichero de *cloud-init* que permiten configurar el servidor de la organización:
  - nombre de equipo.
  - creación de un usuario adminsitrador *magasix*/*abc123.*
  - aplicar contraseña al usuario por defecto *ubuntu*/*abc123.*
  - permiten configurar caché APT para acelerar el proceso de descarga de paquetes.
  - actualización del equipo.
  - instalación del PPA Ondrej/php para poder instalar las versiones de PHP más recientes.
  - instalación y configuración de paquetes (Apache, php, MySQL client y server...):
    - habilitar sitio http/https y crear páginas index.php, info.php y descargar [Adminer](https://www.adminer.org/).
    - acceso por SSH mediante contraseña (recomendado habilitar clave pública).

### Despliegue

Similar para incus y lxd: el fichero de *cloud-init* permite el rápido despliegue de un servidor LAMP. En caso de no indicar un *profile* se empleará el *profile* por defecto, por lo que el contenedor tendrá una NIC conectada a la red creada durante el proceso de inicialización de incus/lxd y un disco duro. La configuración de red la recibirá por DHCP.

**IMPORTANTE**:

- en caso de usar incus, hay que seleccionar las imágenes de tipo cloud al tener instalado *clout-init*.
- en caso de usar lxd, cualquiera de las imágenes Ubuntu oficiales ya tiene *cloud-init* instalado.

[![asciicast](https://asciinema.org/a/649979.svg)](https://asciinema.org/a/649979)

```bash
$ incus launch images:ubuntu/22.04/cloud lamp -c user.user-data="$(cat config_lamp_generico_incus.yml)"
Launching web
$ incus ls -c n,4,s,l,P,m
$ incus ls -c n,4,s,l,P,m
+------+----------------------+---------+-----------------------+----------+--------------+
| NAME |         IPV4         |  STATE  |     LAST USED AT      | PROFILES | MEMORY USAGE |
+------+----------------------+---------+-----------------------+----------+--------------+
| lamp | 10.84.130.109 (eth0) | RUNNING | 2024/03/31 11:11 CEST | default  | 140.73MiB    |
+------+----------------------+---------+-----------------------+----------+--------------+
```

En caso de usar lxd:

```bash
$ lxc launch ubuntu:j web -c user.user-data="$(cat config_lamp_generico_lxd.yml)"
Creating web
Starting web
$ lxc ls -c n,4,s,l,P,m
+------+----------------------+---------+----------------------+----------+--------------+
| NAME |         IPV4         |  STATE  |     LAST USED AT     | PROFILES | MEMORY USAGE |
+------+----------------------+---------+----------------------+----------+--------------+
| web  | 10.79.128.107 (eth0) | RUNNING | 2024/03/31 09:16 UTC | default  | 168.77MiB    |
+------+----------------------+---------+----------------------+----------+-------------
```

Una vez terminado el despliegue, hay que esperar unos minutos hasta que termine el aprovisionamiento del contenedor (instalación de software y configuración del equipo). Se puede comprobar si ha terminado el proceso por ejemplo verificando que los servicios web y ssh corriendo en web están levantados:

```bash
$ incus exec lamp -- ss -ltn | grep -E "80|443|22"
LISTEN 0      128          0.0.0.0:22        0.0.0.0:*          
LISTEN 0      511                *:443             *:*          
LISTEN 0      128             [::]:22           [::]:*          
LISTEN 0      511                *:80              *:* 
```

O si *cloud-init* ha finalizado:

```bash
$ incus exec lamp -- tail /var/log/cloud-init-output.log
   200K .......... .......... .......... .......... .......... 53% 8.32M 0s
   250K .......... .......... .......... .......... .......... 64% 53.0M 0s
   300K .......... .......... .......... .......... .......... 75% 1.31M 0s
   350K .......... .......... .......... .......... .......... 85% 5.98M 0s
   400K .......... .......... .......... .......... .......... 96% 20.6M 0s
   450K .......... .....                                      100% 20.5M=0.3s

2024-03-31 11:17:58 (1.60 MB/s) - ‘/var/www/html/adminer.php’ saved [476603/476603]
```

En caso de querer eliminar el contenedor se procede con:

```bash
$ incus delete -f lamp 
$ incus ls -c n,4,s,l,P,m
+------+------+-------+--------------+----------+--------------+
| NAME | IPV4 | STATE | LAST USED AT | PROFILES | MEMORY USAGE |
+------+------+-------+--------------+----------+--------------+
```

```bash
$ lxc delete -f lamp 
$ lxc ls -c n,4,s,l,P,m
+------+------+-------+--------------+----------+--------------+
| NAME | IPV4 | STATE | LAST USED AT | PROFILES | MEMORY USAGE |
+------+------+-------+--------------+----------+--------------+
```

