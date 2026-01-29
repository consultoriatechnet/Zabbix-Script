📌 Etapas do script
1. Configuração de variáveis
Define IP do servidor (IP_SERVIDOR).

Define credenciais do banco de dados (usuário root, usuário do Zabbix, senha e nome do banco).

2. Configuração de idioma/locale
Ativa o locale pt_BR.UTF-8 para que o sistema use português brasileiro.

3. Instalação de dependências básicas
Instala pacotes necessários: sudo, curl, gnupg2, apt-transport-https, software-properties-common, wget, lsb-release, unzip.

4. Instalação e configuração do MariaDB
Instala o servidor MariaDB.

Executa mysql_secure_installation para proteger o banco (senha root, remover usuários anônimos, desabilitar login remoto, etc.).

Cria o banco de dados zabbix, usuário zabbix com senha zabbix123 e concede permissões.

5. Instalação do Zabbix
Baixa e instala o pacote oficial zabbix-release para Debian 12.

Atualiza os repositórios.

Instala pacotes do Zabbix:

zabbix-server-mysql (servidor Zabbix com suporte MySQL/MariaDB),

zabbix-frontend-php (frontend web em PHP),

zabbix-apache-conf (configuração do Apache para o frontend),

zabbix-sql-scripts (scripts SQL para inicializar o banco),

zabbix-agent (agente para monitorar o próprio servidor).

Importa o schema inicial (server.sql.gz) para o banco de dados.

Configura a senha do banco no arquivo /etc/zabbix/zabbix_server.conf.

Reinicia e habilita os serviços zabbix-server, zabbix-agent e apache2.

6. Instalação do Grafana
Adiciona o repositório oficial do Grafana.

Instala o pacote grafana.

Configura o Grafana para:

aceitar conexões em todas as interfaces (http_addr = 0.0.0.0),

usar o IP do servidor na URL raiz (root_url).

Instala o plugin oficial de integração Zabbix App no Grafana.

Atualiza todos os plugins.

Ajusta permissões da pasta de plugins.

Habilita e inicia o serviço grafana-server.

7. Mensagem final
Exibe os endereços de acesso:

Zabbix: http://IP_SERVIDOR/zabbix  
(login padrão: Admin / zabbix)

Grafana: http://IP_SERVIDOR:3000
