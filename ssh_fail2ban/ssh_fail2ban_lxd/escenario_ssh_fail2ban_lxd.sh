#!/bin/bash
#set -o errexit
#set -o xtrace
set -o nounset

# Variables
RED_LAN="192.168.100"
NETMASK_24="255.255.255.0"
NETMASK_CIDR_24="24"
SERVERSSH="101"
PIRATA="100"

clear
echo "----- Escenario SSH - fail2ban -----"
echo "Seleccionar operación:"
echo "1. Crear escenario"
echo "2. Parar contenedores escenario"
echo "3. Arrancar contenedores escenario"
echo "4. Borrar escenario"
echo "------"
read opcion
case $opcion in
1) echo "Crear escenario"
   # personalizar configuración contenedor
   # Creación redes y perfiles

   #creación red LAN
   lxc network create lan ipv4.address=$RED_LAN.1/$NETMASK_CIDR_24 ipv6.address=none ipv4.dhcp=true ipv4.dhcp.ranges="$RED_LAN.20-$RED_LAN.50" ipv4.firewall=true ipv4.nat=true
   # creación perfil LAN con 1 NICs en modo ponte
   lxc profile create LAN
   cat profile_LAN | lxc profile edit LAN

   echo "------------------------------"
   echo "    creando servidor SSH      "
   echo "------------------------------"
   cp network_PLANTILLA.yml network_serverssh.yaml
   sed -i "s/XXXX/$RED_LAN.$SERVERSSH/g"  network_serverssh.yaml
   sed -i "s/YYYY/$NETMASK_24/g"  network_serverssh.yaml
   sed -i "s/ZZZZ/$RED_LAN.1/g" network_serverssh.yaml     
   lxc launch ubuntu:j serverssh -c user.user-data="$(cat config_serverssh_lxd.yml)" -c user.network-config="$(cat network_serverssh.yaml)" -p LAN
   echo "------------------------------"
   echo "       creando pirata        "
   echo "------------------------------"
   cp network_PLANTILLA.yml network_pirata.yaml
   sed -i "s/XXXX/$RED_LAN.$PIRATA/g" network_pirata.yaml
   sed -i "s/YYYY/$NETMASK_24/g" network_pirata.yaml
   sed -i "s/ZZZZ/$RED_LAN.1/g" network_pirata.yaml
   lxc launch ubuntu:j pirata -c user.user-data="$(cat config_pirata_lxd.yml)" -c user.network-config="$(cat network_pirata.yaml)" -p LAN

   rm network_serverssh.yaml network_pirata.yaml
   echo " "
   sleep 5
   lxc ls -c n,s,4,P,S,l
   ;;
2) echo "Parar contenedores escenario"
   lxc stop -f serverssh pirata
   echo " "
   lxc ls -c n,s,4,P,S,l
   ;;
3) echo "Arrancar containers escenario"
   lxc start serverssh pirata
   sleep 3
   echo " "
   lxc ls -c n,s,4,P,S,l,m
   ;;
4) echo "Borrar escenario"
   lxc stop -f serverssh pirata
   lxc delete serverssh pirata
   echo " "
   lxc ls -c n,s,4,P,S,l,m
   ;;
*) echo "opción incorrecta"
   ;;
esac
