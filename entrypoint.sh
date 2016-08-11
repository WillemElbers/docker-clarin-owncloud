#!/bin/bash
set -e

INITIALISATION_FILE="/opt/initialisation/initialised"

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

    #USER_EXISTS=$(mysql -e  "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '${DATABASE_USER}')" mysql)
    #if [ ${USER_EXISTS} == 1 ]; then
    #    echo "Exists"
    #else
    #    echo "Does not exist"
    #fi

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
    sudo -u www-data php occ ldap:set-config "" "ldapBaseGroups" "ou=groups,ou=system"
    sudo -u www-data php occ ldap:set-config "" "ldapBaseUsers" "ou=users,ou=system"
    sudo -u www-data php occ ldap:set-config "" "ldapLoginFilter" "(&(|(objectclass=inetOrgPerson))(|(mailPrimaryAddress=%uid)(mail=%uid)))"
    sudo -u www-data php occ ldap:set-config "" "hasMemberOfFilterSupport" "0"
    sudo -u www-data php occ ldap:set-config "" "lastJpegPhotoLookup" "0"
    sudo -u www-data php occ ldap:set-config "" "ldapCacheTTL" "600"
    sudo -u www-data php occ ldap:set-config "" "ldapConfigurationActive" "1"
    sudo -u www-data php occ ldap:set-config "" "ldapExperiencedAdmin" "1"
    sudo -u www-data php occ ldap:set-config "" "ldapGroupDisplayName" "cn"
    sudo -u www-data php occ ldap:set-config "" "ldapGroupFilterMode" "0"
    sudo -u www-data php occ ldap:set-config "" "ldapGroupMemberAssocAttr" "uniqueMember"
    sudo -u www-data php occ ldap:set-config "" "ldapLoginFilterEmail" "0"
    sudo -u www-data php occ ldap:set-config "" "ldapLoginFilterMode" "0"
    sudo -u www-data php occ ldap:set-config "" "ldapLoginFilterUsername" "0"
    sudo -u www-data php occ ldap:set-config "" "ldapNestedGroups" "0"
    sudo -u www-data php occ ldap:set-config "" "ldapPagingSize" "500"
    sudo -u www-data php occ ldap:set-config "" "ldapPort" "10000"
    sudo -u www-data php occ ldap:set-config "" "ldapTLS" "0"
    sudo -u www-data php occ ldap:set-config "" "ldapUserDisplayName" "mail"
    sudo -u www-data php occ ldap:set-config "" "ldapUserFilter" "(|(objectclass=inetorgperson))"
    sudo -u www-data php occ ldap:set-config "" "ldapUserFilterMode" "0"
    sudo -u www-data php occ ldap:set-config "" "ldapUserFilterObjectclass" "inetorgperson"
    sudo -u www-data php occ ldap:set-config "" "ldapUuidGroupAttribute" "auto"
    sudo -u www-data php occ ldap:set-config "" "ldapUuidUserAttribute" "auto"
    sudo -u www-data php occ ldap:set-config "" "turnOffCertCheck" "0"
    sudo -u www-data php occ ldap:set-config "" "useMemberOfToDetectMembership" "1"
    sudo -u www-data php occ ldap:set-config "" "ldapExpertUsernameAttr" "mail"


    # Configure logging
    #sudo -u www-data php occ log:manage --backend errorlog --level INFO --timezone UTC

    echo "initialized" >> ${INITIALISATION_FILE}

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

    #Make sure mysql can write the socket file
    if [ ! -d /var/run/mysqld ]; then
        mkdir -p /var/run/mysqld
        chown -R mysql /var/run/mysqld
    fi

    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
}

if [ -f ${INITIALISATION_FILE} ]; then
    start
else
    initialize
    start
fi

