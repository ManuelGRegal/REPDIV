#!/usr/bin/env bash
echo "-----------------"

## Configurar caché de paquetes para acelerar isntalación
#echo "-----------------"
#echo "Añadiendo apt-cacher"
#echo "Acquire::http { Proxy \"http://dir_IP_cache:puerto_cache\";};" > /etc/apt/apt.conf.d/01apt-cacher-ng

echo "Actualizando repositorios y equipo"
apt update
#apt full-upgrade -y

echo "-----------------"
echo "Instalando mysql"

echo "mysql-server mysql-server/root_password password Abc123.." | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password Abc123.." | debconf-set-selections

apt install net-tools mysql-client mysql-server -y

echo "[mysqld]" >> /etc/mysql/my.cnf
echo "bind-address = 0.0.0.0" >> /etc/mysql/my.cnf
systemctl restart mysql.service

echo "------------------"
echo "Creando base datos"
mysql -uroot -pAbc123.. -h localhost -e "CREATE DATABASE wordpress;"
mysql -uroot -pAbc123.. -h localhost -e "CREATE USER 'wordpress'@'192.168.56.121' IDENTIFIED BY 'Abc123..';"
mysql -uroot -pAbc123.. -h localhost -e "GRANT ALL ON wordpress.* TO 'wordpress'@'192.168.56.121';"

echo "------ FIN ------"
