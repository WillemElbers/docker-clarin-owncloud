FROM docker.clarin.eu/base:1.0.1
MAINTAINER sysops@clarin.eu

# Install system dependencies
RUN apt-get update \
 && apt-get install -y bzip2 supervisor \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 mariadb-server libapache2-mod-php5 \
 && apt-get install -y php5-gd php5-json php5-mysql php5-curl \
 && apt-get install -y php5-intl php5-mcrypt php5-imagick \
 && apt-get install -y php5-ldap

# Download and extract owncloud
RUN cd /opt \
 && wget https://download.owncloud.org/community/owncloud-9.1.0.tar.bz2 \
 && echo "26df5f51ae87f83dba93c130a1929278afe69f9426b877e3c5064034bec28ee3  owncloud-9.1.0.tar.bz2" | sha256sum -c - \
 && tar -jxf owncloud-9.1.0.tar.bz2 \
 && rm -r /var/www/html \
 && mv /opt/owncloud /var/www/html \
 && chown -R www-data:www-data /var/www/html \
 && rm /opt/owncloud-9.1.0.tar.bz2

# Enable required apache modules
RUN a2enmod rewrite \
 && a2enmod headers \
 && a2enmod env \
 && a2enmod dir \
 && a2enmod mime

# Add apache vhost configuration
ADD apache/000-default.conf /etc/apache2/sites-available/000-default.conf
ADD apache/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf

# Configure mariadb and owncloud
RUN /etc/init.d/mysql start \
 && mysql -e "CREATE USER 'owncloud'@'%' IDENTIFIED BY 'owncloud';" \
 && mysql -e "CREATE DATABASE owncloud;" \
 && mysql -e "GRANT ALL PRIVILEGES ON owncloud.* TO 'owncloud'@'%';" \
 && cd /var/www/html \
 && sudo -u www-data php occ maintenance:install \
        --database "mysql" --database-name "owncloud"  --database-user "owncloud" --database-pass "owncloud" \
        --admin-user "admin" --admin-pass "password"

# Enable and configure owncloud ldap app
RUN /etc/init.d/mysql start \
 && cd /var/www/html \
 && sudo -u www-data php occ app:enable user_ldap \
 && sudo -u www-data php occ ldap:create-empty-config \
 && sudo -u www-data php occ ldap:set-config "" "ldapHost" "172.17.0.1" \
 && sudo -u www-data php occ ldap:set-config "" "ldapPort" "10000" \
 && sudo -u www-data php occ ldap:set-config "" "ldapAgentName" "uid=admin,ou=system" \
 && sudo -u www-data php occ ldap:set-config "" "ldapAgentPassword" "admin123" \
 && sudo -u www-data php occ ldap:set-config "" "ldapBase" "ou=system"

# Supervisor configuration
ADD supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisord

# Expose volumes
VOLUME ["/var/lib/mysql"]

# Export the unity main port
EXPOSE 80 443

# Run supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]