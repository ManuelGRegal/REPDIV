#!/bin/bash
#set -o errexit
#set -o xtrace
set -o nounset

# Variables
RED_WAN="192.0.2"
RED_DMZ="172.20"
NETMASK_24="255.255.255.0"
NETMASK_CIDR_24="24"
NETMASK_16="255.255.0.0"
NETMASK_CIDR_16="16"
HAPROXY_WAN="190"
HAPROXY_DMZ="255.190"

clear
echo "----- Escenario HA HAproxy -----"
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
   incus network create wan ipv4.address=$RED_WAN.1/$NETMASK_CIDR_24 ipv6.address=none ipv4.dhcp=true ipv4.dhcp.ranges="$RED_WAN.20-$RED_WAN.50" ipv4.firewall=true ipv4.nat=true
   #creación red DMZ
   incus network create dmz ipv4.address=$RED_DMZ.0.1/$NETMASK_CIDR_16 ipv6.address=none ipv4.dhcp=true ipv4.dhcp.ranges="$RED_DMZ.0.20-$RED_DMZ.0.50" ipv4.firewall=true ipv4.nat=true
   # creación perfil WAN-DMZ con 2 NICs en modo ponte
   incus profile create WAN-DMZ
   cat profile_WAN-DMZ | incus profile edit WAN-DMZ
   # creación perfil DMZ con 1 NICs en modo ponte
   incus profile create DMZ
   cat profile_DMZ | incus profile edit DMZ

   echo "------------------------------"
   echo "     creando HAproxy       "
   echo "------------------------------"
   cp network_2NICS_PLANTILLA.yml network_haproxy.yaml
   sed -i "s/XXXX/$RED_WAN.$HAPROXY_WAN/g"  network_haproxy.yaml
   sed -i "s/YYYY/$NETMASK_24/g"  network_haproxy.yaml
   sed -i "s/ZZZZ/$RED_WAN.1/g" network_haproxy.yaml
   sed -i "s/WWWW/$RED_DMZ.$HAPROXY_DMZ/g" network_haproxy.yaml
   sed -i "s/VVVV/$NETMASK_16/g"  network_haproxy.yaml         
   incus launch images:ubuntu/22.04/cloud haproxy -c user.user-data="$(cat config_haproxy_incus.yml)" -c user.network-config="$(cat network_haproxy.yaml)"  -p WAN-DMZ
   rm network_haproxy.yaml
   echo "------------------------------"
   echo "        creando servers        "
   echo "------------------------------"
   for j in {1..5}
   do
      # personalizar configuración
      cp network_PLANTILLA.yml network_server_0$j.yaml
      sed -i "s/XXXX/$RED_DMZ.0.19$j/g" network_server_0$j.yaml
      sed -i "s/YYYY/$NETMASK_16/g" network_server_0$j.yaml
      sed -i "s/ZZZZ/$RED_DMZ.$HAPROXY_DMZ/g" network_server_0$j.yaml
      sed -i "s/NOMBRE/haproxy-php-0$j/g" config_server_incus_0$j.yml
      incus launch images:ubuntu/22.04/cloud haproxy-php-0$j -c user.user-data="$(cat config_server_incus_0$j.yml)" -c user.network-config="$(cat network_server_0$j.yaml)" -p DMZ
      rm network_server_0$j.yaml 
   done
   echo " "
   sleep 5
   incus ls -c n,s,4,P,S,l
   ;;
2) echo "Parar contenedores escenario"
   incus stop -f haproxy
   for j in {1..5}
   do
      incus stop -f haproxy-php-0$j
   done
   echo " "
   incus ls -c n,s,4,P,S,l
   ;;
3) echo "Arrancar containers escenario"
   incus start haproxy
   for j in {1..5}
   do
      incus start haproxy-php-0$j
   done
   sleep 3
   echo " "
   incus ls -c n,s,4,P,S,l,m
   ;;
4) echo "Borrar escenario"
   incus delete -f haproxy
   for j in {1..5}
   do
      incus delete -f haproxy-php-0$j
   done
   echo " "
   incus ls -c n,s,4,P,S,l,m
   ;;
*) echo "opción incorrecta"
   ;;
esac
