#!/bin/bash
#set -o errexit
#set -o xtrace
set -o nounset

# Variables
RED_WAN="192.0.2"
RED_LAN="192.168.100"
RED_DMZ="172.20"
NETMASK_24="255.255.255.0"
NETMASK_CIDR_24="24"
NETMASK_16="255.255.0.0"
NETMASK_CIDR_16="16"
FW_WAN="254"
FW_LAN="254"
FW_DMZ="255.254"
SERVER="0.2"
ADMIN2="2"

clear
echo "----- Escenario FW-LAN-DMZ -----"
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
   lxc network create wan ipv4.address=$RED_WAN.1/$NETMASK_CIDR_24 ipv6.address=none ipv4.dhcp=true ipv4.dhcp.ranges="$RED_WAN.20-$RED_WAN.50" ipv4.firewall=true ipv4.nat=true
   #creación red LAN
   lxc network create lan ipv4.address=$RED_LAN.1/$NETMASK_CIDR_24 ipv6.address=none ipv4.dhcp=true ipv4.dhcp.ranges="$RED_LAN.20-$RED_LAN.50" ipv4.firewall=true ipv4.nat=true
   #creación red DMZ
   lxc network create dmz ipv4.address=$RED_DMZ.0.1/$NETMASK_CIDR_16 ipv6.address=none ipv4.dhcp=true ipv4.dhcp.ranges="$RED_DMZ.0.20-$RED_DMZ.0.50" ipv4.firewall=true ipv4.nat=true
   # creación perfil WAN-LAN-DMZ con 3 NICs en modo ponte
   lxc profile create WAN-LAN-DMZ
   cat profile_WAN-LAN-DMZ | lxc profile edit WAN-LAN-DMZ
   # creación perfil LAN con 1 NICs en modo ponte
   lxc profile create LAN
   cat profile_LAN | lxc profile edit LAN
   # creación perfil DMZ con 1 NICs en modo ponte
   lxc profile create DMZ
   cat profile_DMZ | lxc profile edit DMZ

   echo "------------------------------"
   echo "     creando firewall       "
   echo "------------------------------"
   cp network_3NICS_PLANTILLA.yml network_fw.yaml
   sed -i "s/XXXX/$RED_WAN.$FW_WAN/g"  network_fw.yaml
   sed -i "s/YYYY/$NETMASK_24/g"  network_fw.yaml
   sed -i "s/ZZZZ/$RED_WAN.1/g" network_fw.yaml
   sed -i "s/WWWW/$RED_LAN.$FW_LAN/g" network_fw.yaml
   sed -i "s/VVVV/$NETMASK_24/g"  network_fw.yaml   
   sed -i "s/AAAA/$RED_DMZ.$FW_DMZ/g" network_fw.yaml
   sed -i "s/BBBB/$NETMASK_16/g"  network_fw.yaml         
   lxc launch ubuntu:j fw -c user.user-data="$(cat config_fw_lxd.yml)" -c user.network-config="$(cat network_fw.yaml)" -p WAN-LAN-DMZ
   echo "------------------------------"
   echo "        creando server        "
   echo "------------------------------"
   cp network_PLANTILLA.yml network_server.yaml
   sed -i "s/XXXX/$RED_DMZ.$SERVER/g" network_server.yaml
   sed -i "s/YYYY/$NETMASK_16/g" network_server.yaml
   sed -i "s/ZZZZ/$RED_DMZ.$FW_DMZ/g" network_server.yaml
   lxc launch ubuntu:j server -c user.user-data="$(cat config_server_lxd.yml)" -c user.network-config="$(cat network_server.yaml)" -p DMZ
   echo "------------------------------"
   echo "        creando admin 2       "
   echo "------------------------------"
   cp network_PLANTILLA.yml network_admin2.yaml
   sed -i "s/XXXX/$RED_LAN.$ADMIN2/g" network_admin2.yaml
   sed -i "s/YYYY/$NETMASK_24/g" network_admin2.yaml
   sed -i "s/ZZZZ/$RED_LAN.$FW_LAN/g" network_admin2.yaml
   lxc launch ubuntu:j admin2 -c user.user-data="$(cat config_fw_lxd.yml)" -c user.network-config="$(cat network_admin2.yaml)" -p LAN

   rm network_fw.yaml network_server.yaml network_admin2.yaml
   echo " "
   sleep 5
   lxc ls -c n,s,4,P,S,l
   ;;
2) echo "Parar contenedores escenario"
   lxc stop -f fw server admin2
   echo " "
   lxc ls -c n,s,4,P,S,l
   ;;
3) echo "Arrancar containers escenario"
   lxc start fw server admin2
   sleep 3
   echo " "
   lxc ls -c n,s,4,P,S,l,m
   ;;
4) echo "Borrar escenario"
   lxc stop -f fw server admin2
   lxc delete fw server admin2
   echo " "
   lxc ls -c n,s,4,P,S,l,m
   ;;
*) echo "opción incorrecta"
   ;;
esac
