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
LVS_WAN="180"
LVS_WAN2="181"
LVS_DMZ="255.180"

clear
echo "----- Escenario HA LVS -----"
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
   echo "     creando LVS       "
   echo "------------------------------"
   cp network_2NICS_PLANTILLA.yml network_lvs.yaml
   sed -i "s/QQQQ/$RED_WAN.$LVS_WAN/g"  network_lvs.yaml
   sed -i "s/XXXX/$RED_WAN.$LVS_WAN2/g"  network_lvs.yaml
   sed -i "s/YYYY/$NETMASK_24/g"  network_lvs.yaml
   sed -i "s/ZZZZ/$RED_WAN.1/g" network_lvs.yaml
   sed -i "s/WWWW/$RED_DMZ.$LVS_DMZ/g" network_lvs.yaml
   sed -i "s/VVVV/$NETMASK_16/g"  network_lvs.yaml         
   incus launch images:ubuntu/22.04/cloud lvs -c user.user-data="$(cat config_lvs_incus.yml)" -c user.network-config="$(cat network_lvs.yaml)"  -c "linux.kernel_modules= ip_vs, ip_vs_fo, ip_vs_ovf, ip_vs_pe_sip, ip_vs_dh, ip_vs_lblcr,ip_vs_nq, ip_vs_sed, ip_vs_wlc, ip_vs_ftp, ip_vs_lblc, ip_vs_lc, ip_vs_rr, ip_vs_sh, ip_vs_wrr" -c "security.privileged=true" -p WAN-DMZ
   rm network_lvs.yaml
   echo "------------------------------"
   echo "        creando servers        "
   echo "------------------------------"
   for j in {1..5}
   do
      # personalizar configuración
      cp network_PLANTILLA.yml network_server_0$j.yaml
      cp config_server_incus_PLANTILLA.yml config_server_incus_0$j.yml
      sed -i "s/XXXX/$RED_DMZ.0.18$j/g" network_server_0$j.yaml
      sed -i "s/YYYY/$NETMASK_16/g" network_server_0$j.yaml
      sed -i "s/ZZZZ/$RED_DMZ.$LVS_DMZ/g" network_server_0$j.yaml
      sed -i "s/NOMBRE/lvs-php-0$j/g" config_server_incus_0$j.yml
      incus launch images:ubuntu/22.04/cloud lvs-php-0$j -c user.user-data="$(cat config_server_incus_0$j.yml)" -c user.network-config="$(cat network_server_0$j.yaml)" -p DMZ
      rm network_server_0$j.yaml config_server_incus_0$j.yml
   done
   echo " "
   sleep 5
   incus ls -c n,s,4,P,S,l
   ;;
2) echo "Parar contenedores escenario"
   incus stop -f lvs
   for j in {1..5}
   do
      incus stop -f lvs-php-0$j
   done
   echo " "
   incus ls -c n,s,4,P,S,l
   ;;
3) echo "Arrancar containers escenario"
   incus start lvs
   for j in {1..5}
   do
      incus start lvs-php-0$j
   done
   sleep 3
   echo " "
   incus ls -c n,s,4,P,S,l,m
   ;;
4) echo "Borrar escenario"
   incus delete -f lvs
   for j in {1..5}
   do
      incus delete -f lvs-php-0$j
   done
   echo " "
   incus ls -c n,s,4,P,S,l,m
   ;;
*) echo "opción incorrecta"
   ;;
esac
