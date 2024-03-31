#!/bin/bash
#set -o errexit
#set -o xtrace
set -o nounset

# Variables
RED_WAN="192.0.2"
RED_LAN="192.168.100"
NETMASK="255.255.255.0"
NETMASK_CIDR="24"
FW_WAN="254"
FW_LAN="254"
SERVER="253"
OPERARIO="10"

clear
echo "----- Escenario FW-LAN -----"
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
   #creación red WAN
   lxc network create wan ipv4.address=$RED_WAN.1/$NETMASK_CIDR ipv6.address=none ipv4.dhcp=true ipv4.dhcp.ranges="$RED_WAN.2-$RED_WAN.50" ipv4.firewall=true ipv4.nat=true
   #creación red LAN
   lxc network create lan ipv4.address=$RED_LAN.1/$NETMASK_CIDR ipv6.address=none ipv4.dhcp=true ipv4.dhcp.ranges="$RED_LAN.2-$RED_LAN.50" ipv4.firewall=true ipv4.nat=true
   # creación perfil WAN-LAN con 2 NICs en modo ponte
   lxc profile create WAN-LAN
   cat profile_WAN-LAN | lxc profile edit WAN-LAN
   # creación perfil LAN con 1 NICs en modo ponte
   lxc profile create LAN
   cat profile_LAN | lxc profile edit LAN

   echo "------------------------------"
   echo "     creando firewall       "
   echo "------------------------------"
   cp network_2NICS_PLANTILLA.yml network_fw.yaml
   sed -i "s/XXXX/$RED_WAN.$FW_WAN/g"  network_fw.yaml
   sed -i "s/YYYY/$NETMASK/g"  network_fw.yaml
   sed -i "s/ZZZZ/$RED_WAN.1/g" network_fw.yaml
   sed -i "s/WWWW/$RED_LAN.$FW_LAN/g" network_fw.yaml
   lxc launch ubuntu:j fw -c user.user-data="$(cat config_fw_lxd.yml)" -c user.network-config="$(cat network_fw.yaml)" -p WAN-LAN
   echo "------------------------------"
   echo "     creando server     "
   echo "------------------------------"
   cp network_PLANTILLA.yml network_server.yaml
   sed -i "s/XXXX/$RED_LAN.$SERVER/g" network_server.yaml
   sed -i "s/YYYY/$NETMASK/g" network_server.yaml
   sed -i "s/ZZZZ/$RED_LAN.$FW_LAN/g" network_server.yaml
   lxc launch ubuntu:j server -c user.user-data="$(cat config_server_lxd.yml)" -c user.network-config="$(cat network_server.yaml)" -p LAN
   rm network_fw.yaml network_server.yaml
   echo " "
   sleep 5
   lxc ls -c n,s,4,P,S,l
   ;;
2) echo "Parar contenedores escenario"
   lxc stop -f fw server
   echo " "
   lxc ls -c n,s,4,P,S,l
   ;;
3) echo "Arrancar containers escenario"
   lxc start fw server
   sleep 3
   echo " "
   lxc ls -c n,s,4,P,S,l,m
   ;;
4) echo "Borrar escenario"
   lxc stop -f fw server
   lxc delete fw server
   echo " "
   lxc ls -c n,s,4,P,S,l,m
   ;;
*) echo "opción incorrecta"
   ;;
esac
