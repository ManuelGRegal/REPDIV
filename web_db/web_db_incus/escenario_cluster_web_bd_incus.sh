#!/bin/bash
#set -o errexit
#set -o xtrace
set -o nounset

# Variables
RED_LAN="192.168.100"
NETMASK="255.255.255.0"
NETMASK_CIDR_24="24"
WEB="121"
BD="122"

clear
echo "----- Escenario Cluster Web-BD -----"
echo "Seleccionar operación:"
echo "1. Crear escenario"
echo "2. Parar contenedores escenario"
echo "3. Arrancar contenedores escenario"
echo "4. Borrar escenario"
echo "------"
read opcion
case $opcion in
1) echo "Crear escenario"
   # Creación redes y perfiles
   #creación red LAN
   incus network create lan ipv4.address=$RED_LAN.1/$NETMASK_CIDR_24 ipv6.address=none ipv4.dhcp=true ipv4.dhcp.ranges="$RED_LAN.20-$RED_LAN.50" ipv4.firewall=true ipv4.nat=true
   # creación perfil LAN con 1 NICs en modo ponte
   incus profile create LAN
   cat profile_LAN | incus profile edit LAN
   # personalizar configuración contenedor
   echo "------------------------------"
   echo "     creando web server       "
   echo "------------------------------"
   cp network_PLANTILLA.yml network_web.yaml
   sed -i "s/XXXX/$RED_LAN.$WEB/g"  network_web.yaml
   sed -i "s/YYYY/$NETMASK/g"  network_web.yaml
   sed -i "s/ZZZZ/$RED_LAN.1/g"  network_web.yaml
   incus launch images:ubuntu/22.04/cloud web -c user.user-data="$(cat config_web_incus.yml)" -c user.network-config="$(cat network_web.yaml)" -p LAN
   echo "------------------------------"
   echo "     creando myslq server     "
   echo "------------------------------"
   cp network_PLANTILLA.yml network_db.yaml
   cp config_mysql_incus_PLANTILLA.yml config_mysql_incus.yml
   sed -i "s/XXXX/$RED_LAN.$WEB/g" config_mysql_incus.yml
   sed -i "s/XXXX/$RED_LAN.$BD/g" network_db.yaml
   sed -i "s/YYYY/$NETMASK/g" network_db.yaml
   sed -i "s/ZZZZ/$RED_LAN.1/g" network_db.yaml
   incus launch images:ubuntu/22.04/cloud mysql -c user.user-data="$(cat config_mysql_incus.yml)" -c user.network-config="$(cat network_db.yaml)" -p LAN
   rm network_web.yaml network_db.yaml config_mysql_incus.yml
   echo " "
   sleep 5
   incus ls -c n,s,4,P,S,l
   ;;
2) echo "Parar contenedores escenario"
   incus stop -f web mysql
   echo " "
   incus ls -c n,s,4,P,S,l
   ;;
3) echo "Arrancar containers escenario"
   incus start web mysql
   sleep 3
   echo " "
   incus ls -c n,s,4,P,S,l,m
   ;;
4) echo "Borrar escenario"
   incus stop -f web mysql
   incus delete web mysql
   echo " "
   incus ls -c n,s,4,P,S,l,m
   ;;
*) echo "opción incorrecta"
   ;;
esac
