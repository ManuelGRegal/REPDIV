#!/bin/bash
#set -o errexit
#set -o xtrace
set -o nounset

# Variables
RED_LAN="192.168.100"
NETMASK="255.255.255.0"
NETMASK_CIDR_24="24"
NUMERO="3"

clear
echo "----- Escenario Cluster Web -----"
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

   for i in $(seq 1 $NUMERO)
   do
     # personalizar configuración contenedor
     cp config_web_PLANTILLA_incus.yml config_web0$i.yml
     cp network_PLANTILLA.yml network_web0$i.yaml
     sed -i "s/NOMBRE/web0$i/g" config_web0$i.yml
     sed -i "s/XXXX/$RED_LAN.5$i/g" network_web0$i.yaml
     sed -i "s/YYYY/$NETMASK/g" network_web0$i.yaml
     sed -i "s/ZZZZ/$RED_LAN.1/g" network_web0$i.yaml
     incus launch images:ubuntu/22.04/cloud web0$i -c user.user-data="$(cat config_web0$i.yml)" -c user.network-config="$(cat network_web0$i.yaml)" -p LAN
     rm config_web0$i.yml network_web0$i.yaml
   done
   echo " "
   sleep 5
   incus ls -c n,s,4,P,S,l,m
   ;;
2) echo "Parar contenedores escenario"
   for i in $(seq 1 $NUMERO)
   do
     incus stop -f web0$i
   done
   echo " "
   incus ls -c n,s,4,P,S,l,m
   ;;
3) echo "Arrancar containers escenario"
   for i in $(seq 1 $NUMERO)
   do
     incus start web0$i
   done
   sleep 3
   echo " "
   incus ls -c n,s,4,P,S,l,m
   ;;
4) echo "Borrar escenario"
   for i in $(seq 1 $NUMERO)
   do
     incus stop -f web0$i
     incus delete web0$i
   done
   echo " "
   incus ls -c n,s,4,P,S,l,m
   ;;
*) echo "opción incorrecta"
   ;;
esac
