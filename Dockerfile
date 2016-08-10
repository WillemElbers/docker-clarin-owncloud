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
 && mkdir -p /var/www/html/data \
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

# Supervisor configuration
ADD supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN useradd -s /bin/bash supervisor \
 && mkdir -p /var/log/supervisord \
 && mkdir -p /var/run/supervisord \
 && chown -R supervisor /var/log/supervisord \
 && chown -R supervisor /etc/supervisor \
 && chown -R supervisor /var/run/supervisord

RUN mkdir -p /opt/initialisation

# Add entrypoint script
ADD entrypoint.sh /opt/entrypoint.sh
ADD secrets /opt/.secrets
RUN chown supervisor /opt/* \
 && chmod u+x /opt/entrypoint.sh \
 && chmod 0600 /opt/.secrets

# Expose volumes
VOLUME ["/var/lib/mysql", "/var/www/html", "/opt/initialisation"]

# Export the unity main port
EXPOSE 80 443

# Run supervisor
CMD ["/opt/entrypoint.sh"]