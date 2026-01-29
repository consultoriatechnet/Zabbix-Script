#!/bin/bash

### VARIÁVEIS PERSONALIZÁVEIS ###
IP_SERVIDOR=$(hostname -I | awk '{print $1}')
DB_ROOT_PASS="root"
DB_ZABBIX_USER="zabbix"
DB_ZABBIX_PASS="zabbix123"
DB_NAME="zabbix"

### CONFIGURAR LOCALE ###
echo "Configurando sistema para pt_BR.UTF-8..."
sed -i 's/^# *pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=pt_BR.UTF-8
dpkg-reconfigure locales

### DEPENDÊNCIAS ###
apt update && apt install -y sudo curl gnupg2 apt-transport-https software-properties-common wget lsb-release unzip

### INSTALAR MARIADB ###
echo "Instalando MariaDB..."
apt install -y mariadb-server
mysql_secure_installation <<EOF

y
$DB_ROOT_PASS
$DB_ROOT_PASS
y
y
y
y
EOF

### CRIAR BANCO DE DADOS ZABBIX ###
mysql -uroot -p$DB_ROOT_PASS <<EOF
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER '$DB_ZABBIX_USER'@'localhost' IDENTIFIED BY '$DB_ZABBIX_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_ZABBIX_USER'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF

### INSTALAR ZABBIX (conforme site oficial) ###
wget https://repo.zabbix.com/zabbix/7.4/release/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.4+debian12_all.deb
dpkg -i zabbix-release_latest_7.4+debian12_all.deb
apt update
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

### IMPORTAR SCHEMA INICIAL ###
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -u$DB_ZABBIX_USER -p$DB_ZABBIX_PASS $DB_NAME
mysql -uroot -p$DB_ROOT_PASS -e "SET GLOBAL log_bin_trust_function_creators = 0;"

### CONFIGURAR SENHA DO BANCO NO ZABBIX ###
sed -i "s/^# DBPassword=.*/DBPassword=$DB_ZABBIX_PASS/" /etc/zabbix/zabbix_server.conf

### INICIAR SERVIÇOS ###
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

### INSTALAR GRAFANA ###
mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
apt update && apt install -y grafana

# Configurar Grafana para aceitar acesso via IP na porta 3000
sed -i "s|^;root_url =.*|root_url = http://$IP_SERVIDOR:3000/|" /etc/grafana/grafana.ini
sed -i "s/^;http_addr =.*/http_addr = 0.0.0.0/" /etc/grafana/grafana.ini

grafana-cli plugins install alexanderzobnin-zabbix-app
grafana-cli plugins update-all
chown -R grafana: /var/lib/grafana/plugins

systemctl daemon-reexec
systemctl enable grafana-server
systemctl start grafana-server

echo "============================================================"
echo "Zabbix disponível em: http://$IP_SERVIDOR/zabbix"
echo "Grafana disponível em: http://$IP_SERVIDOR:3000"
echo "Login padrão do Grafana: admin / admin"
echo "Login padrão do Zabbix: Admin / zabbix"
echo "============================================================"
