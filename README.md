# Owncloud docker container

this projects builds a debian based image running [owncloud-9.1.0](https://doc.owncloud.org/) with the ldap plugin enabled and configured.

# Running 

Running the container with all defaults:

```
docker run -ti --rm -p 80:80 -p 443:443 docker.clarin.eu/owncloud:1.0.0
```

## Customization

Simple variables are managed via container environment variables, passed to the container via the '-e` parameter. If a variable is not supplied, the default value is used. The following variables are supported:

| Variable                 | Default Value       | Description                             | 
| ------------------------ | ------------------- | --------------------------------------- |
| DATABASE_USER            | owncloud            | Owncloud database username              |
| DATABASE_NAME            | owncloud            | Owncloud database name                  |
| OWNCLOUD_ADMIN           | admin               | Owncloud administrator username         |
| LDAP_HOST                | 172.17.0.1          | LDAP hostname or ip address             | 
| LDAP_PORT                | 10000               | LDAP port                               |
| LDAP_USER\_DN            | uid=admin,ou=system | LDAP DN for user with search permission |
| LDAP_BASE\_DN            | ou=system           |LDAP base DN                            |

Secrets are not managed via container environment variables as these are leaked via the `docker inspect` command, see [1]. Until a better approach is available secrets are specified in the `/opt/.secrets` file. Provide a host mounted file to override the defaults.

| Variable                 | Default Value       | Description                             |
| ------------------------ | ------------------- | --------------------------------------- |
| DATABASE_PASSWORD        | owncloud            | Owncloud database password              |
| OWNCLOUD_ADMIN\_PASSWORD | password            | Owncloud administrator password         |
| LDAP_USER\_PASSWORD      | admin123            | Password for the ldap user              | 

Note: we strongly recommend that your change the default values for these secrets!

Running a customized owncloud instance:

```
docker run -ti --rm \
	-p 80:80 -p 443:443 \
	-e "DATABASE_USER=value" \
	-e "DATABASE_NAME=value" \
	-e "OWNCLOUD_ADMIN=value" \
	-e "LDAP_HOST=value" \
	-e "LDAP_PORT=value" \
	-e "LDAP_USER_DN=value" \
	-e "LDAP_BASE_DN=value" \
	-v /home/user/.secrets:/opt/.secrets \
	docker.clarin.eu/owncloud:1.0.0
```
 
Where:

* `/home/user/.secrets` is the path to your local secrets file
* all `value` fields are replaced with appropriate values.
    
## Data persistence

Exposed volumes:

```
/var/lib/mysql             # MySql data files
/var/www/html/data         # OwnCloud data files
```

#References

* [1] [Secrets: write-up best practices, do's and don'ts, roadmap #13490
](https://github.com/docker/docker/issues/13490)