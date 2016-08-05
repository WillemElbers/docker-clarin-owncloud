#!/bin/bash
set -e

DEFAULT_DATABASE_USER="owncloud"
DEFAULT_DATABASE_PASSWORD="owncloud"
DEFAULT_DATABASE_NAME="owncloud"
DEFAULT_OWNCLOUD_ADMIN="admin"
DEFAULT_OWNCLOUD_ADMIN_PASSWORD="password"
DEFAULT_LDAP_HOST="172.17.0.1"
DEFAULT_LDAP_PORT="10000"
DEFAULT_LDAP_USER_DN="uid=admin,ou=system"
DEFAULT_LDAP_USER_PASSWORD="admin123"
DEFAULT_LDAP_BASE_DN="ou=system"

DATABASE_USER=${DATABASE_USER:-$DEFAULT_DATABASE_USER}
DATABASE_NAME=${DATABASE_NAME:-$DEFAULT_DATABASE_NAME}
OWNCLOUD_ADMIN=${OWNCLOUD_ADMIN:-$DEFAULT_OWNCLOUD_ADMIN}
LDAP_HOST=${LDAP_HOST:-$DEFAULT_LDAP_HOST}
LDAP_PORT=${LDAP_PORT:-$DEFAULT_LDAP_PORT}
LDAP_USER_DN=${LDAP_USER_DN:-$DEFAULT_LDAP_USER_DN}
LDAP_BASE_DN=${LDAP_BASE_DN:-$DEFAULT_LDAP_BASE_DN}

if [ -f /opt/.secrets ];
then
    chmod 0600 /opt/.secrets
    source /opt/.secrets
fi

DATABASE_PASSWORD=${DATABASE_PASSWORD:-$DEFAULT_DATABASE_PASSWORD}
OWNCLOUD_ADMIN_PASSWORD=${OWNCLOUD_ADMIN_PASSWORD:-$DEFAULT_OWNCLOUD_ADMIN_PASSWORD}
LDAP_USER_PASSWORD=${LDAP_USER_PASSWORD:-$DEFAULT_LDAP_USER_PASSWORD}

initialize() {
    echo ""
    echo "********************"
    echo "*** Initializing ***"
    echo "********************"
    echo ""
    echo "    DATABASE_USER=${DATABASE_USER}"
    echo "    DATABASE_PASSWORD=******"
    echo "    DATABASE_NAME=${DATABASE_NAME}"
    echo "    OWNCLOUD_ADMIN=${OWNCLOUD_ADMIN}"
    echo "    OWNCLOUD_ADMIN_PASSWORD=******"
    echo "    LDAP_HOST=${LDAP_HOST}"
    echo "    LDAP_PORT=${LDAP_PORT}"
    echo "    LDAP_USER_DN=${LDAP_USER_DN}"
    echo "    LDAP_USER_PASSWORD=******"
    echo "    LDAP_BASE_DN=${LDAP_BASE_DN}"
    echo ""

    # Start database
    /etc/init.d/mysql start

    # Initialize mysql database
    echo "Initializing mysql database"
    mysql -e "CREATE USER '${DATABASE_USER}'@'%' IDENTIFIED BY '${DATABASE_PASSWORD}';"
    mysql -e "CREATE DATABASE ${DATABASE_NAME};"
    mysql -e "GRANT ALL PRIVILEGES ON ${DATABASE_NAME}.* TO '${DATABASE_USER}'@'%';"

    # Finalize owncloud installation
    echo "Initializing owncloud installation"
    cd /var/www/html
    sudo -u www-data php occ maintenance:install \
            --database "mysql" --database-name ${DATABASE_NAME}  --database-user ${DATABASE_USER} --database-pass ${DATABASE_PASSWORD} \
            --admin-user ${OWNCLOUD_ADMIN} --admin-pass ${OWNCLOUD_ADMIN_PASSWORD}

    #Enable and configure ldap plugin
    echo "Enabling and configuring owncloud ldap plugin"
    sudo -u www-data php occ app:enable user_ldap
    sudo -u www-data php occ ldap:create-empty-config
    sudo -u www-data php occ ldap:set-config "" "ldapHost" "${LDAP_HOST}"
    sudo -u www-data php occ ldap:set-config "" "ldapPort" "${LDAP_PORT}"
    sudo -u www-data php occ ldap:set-config "" "ldapAgentName" "${LDAP_USER_DN}"
    sudo -u www-data php occ ldap:set-config "" "ldapAgentPassword" "${LDAP_USER_PASSWORD}"
    sudo -u www-data php occ ldap:set-config "" "ldapBase" "${LDAP_BASE_DN}"

    touch /opt/initialized

    # Stop database
    /etc/init.d/mysql stop
}

start() {
    echo ""
    echo "****************************"
    echo " *** Starting supervisor ***"
    echo "****************************"
    echo ""

    unset DATABASE_PASSWORD
    unset OWNCLOUD_ADMIN_PASSWORD
    unset LDAP_USER_PASSWORD
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
}

if [ -f /opt/initialized ]; then
    start
else
    initialize
    start
fi

