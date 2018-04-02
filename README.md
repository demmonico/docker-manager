# Docker Manager tool

## Description

Tool for automated management of Docker-based projects, networks and environments either at local development host and remote server.
Common usage as a Docker-based structure for deploy several web-sites or MSA-based web-application at single server or local host for development purposes.
This skeleton makes simpler process of deploy and management different web-sites at server and maintenance them further.


##### Modes

There are two modes which are supported by this manager:
 - **local** used at the developer's local machine (when port `80` is busy and/or `Apache` is installed at the host machine)
 - **server** other cases, e.g. dev-server

Local mode mostly used at developer's machine when:
 - `Apache` web server is installed
 - Docker Manager used as a Docker-based wrapper which is serving multiple sub-domains or multi-service application
 
Current mode will be detected automatically through analyzing `netstat` results for port `80` and either `Apache` web server installation.



## Contents

- [Description](#description)
    - [Modes](#modes)
- [Structure](#structure)
- [Quick Guide](#quick-guide)
- [Installation steps](#installation-steps)
    - [1. Prepare environment](#1-prepare-environment)
        - [Prepare local host environment](#prepare-local-host-environment)
        - [Prepare remote server environment](#prepare-remote-server-environment)
    - [2. Run installation](#2-run-installation)
        - [Automated installation](#automated-installation)
        - [Manual installation](#manual-installation)
    - [3. Re-login](#3-re-login)
    - [Uninstall](#uninstall)
- [Configuration](#configuration)
    - [Configure Docker Manager](#configure-docker-manager)
        - [Setup common config](#setup-common-config)
        - [Setup sensitive information](#setup-sensitive-information)
    - [Copy or pull projects](#copy-or-pull-projects)
    - [Configure project](#configure-project)
        - [Configs priority](#configs-priority)
            - [Compose files](#compose-files)
            - [Environment file](#environment-file)
            - [Dockerfile](#dockerfile)
        - [Environment variables](#environment-variables)
            - [Customize DB settings](#customize-db-settings)
            - [Tune PHP settings](#tune-php-settings)
            - [Add domains to hosts file](#add-domains-to-hosts-file)
            - [Add custom command to the entrypoint script](#add-custom-command-to-the-entrypoint-script)
        - [SSL certificates](#ssl-certificates)
        - [HTTP Basic Authentication](#http-basic-authentication)
- [Usage](#usage)
    - [Start project(s)](#start-projects)
    - [Stop project(s)](#stop-projects)
    - [Exec command inside container](#exec-command-inside-container)
    - [Inspect containers](#inspect-containers)
    - [CLI command readme](#cli-command-readme)
- [Change log](#change-log)
- [License](#license)

 

## Structure

<details><summary>Click here to expand</summary>
<p>

```
bin/                contains bin scripts for management purposes
|-- exec.sh         script for exec command inside container
|-- install.sh      installation script
|-- start.sh        script for build/start one/all projects
|-- stop.sh         script for stop one/all projects
|-- ...
 
config/                 contains common configs
|-- docker-compose.d/   contains common used docker-compose settings compiled while compose up. These files will be bound automatically AFTER main docker-compose.yml file
|   |-- app.yml         contains common used docker-compose settings for app services
|   |-- db.yml          contains common used docker-compose settings for db services
|   |-- networks.yml    contains settings for common network of this DM
|-- security/           [GIT IGNORED] contains security settings, tokens and SSH keys for using while build/start Docker containers
|   |-- ssh-keys/       [GIT IGNORED] contains SSH keys
|   |   |-- id_rsa
|   |   |-- id_rsa.pub
|   |   |-- known_hosts
|   |-- common.yml      [GIT IGNORED] contains security settings and tokens
|-- local.yml           [GIT IGNORED] contains settings of current instance of the DM
|-- local-example.yml   contains example of settings of the DM
 
demo/                           contains test projects and docker/docker-compose configs and data files
|-- advanced-project/           contains test example of advanced project usage
|   |-- ...                     see "projects/main" folder structure for details
|-- simple-project/             contains test example of simple project usage
|   |-- ...                     see "projects/main" folder structure for details
 
images/             contains docker images which further will be used at the projects
|-- some_image/     [GIT IGNORED]
|-- ...
 
projects/                           contains docker containers for all virtual hosts (your web-sites). Should be excluded from VCS
|-- main/                           contains docker/docker-compose configs and data files for main project, accessible at main domain of this DM
|   | 
|   |   Following template of the structure consider an idea: one docker service - one folder,
|   |   e.g. if project has 3 servises (app, db and reverse proxy) then there are 3 sub-folders here (app, db, proxy) + folder for shared files.
|   |   So all sub-folders are OPTIONAL.
|   | 
|   |-- app/                        contains app's code, data files and docker params
|   |   |-- data/                   contains app's data files, e.g. moodledata folder or upload folder
|   |   |-- dockerfiles/            contains custom Dockerfile and additional files for build/run app's Docker container
|   |   |   |-- install/            contains additional files, e.g. custom run/run_once scripts etc
|   |   |   |   |-- apache-dummy/   contains Apache dummy files. Could be pulled from dummy's repo or created manually
|   |   |   |   |   |-- .htaccess   dummy's htaccess
|   |   |   |   |   |-- uc.jpg      dummy's image
|   |   |   |   |   |-- uc.php      dummy's php code
|   |   |   |   |-- custom.sh       additional custom run script
|   |   |   |   |-- custom_once.sh  additional custom run_once script
|   |   |   |   |-- run.sh          BUILD_IN script runs each time when Docker container starts (already exists inside image)
|   |   |   |   |-- run_once.sh     BUILD_IN script runs once when Docker container starts at first time (already exists inside image)
|   |   |   |   |-- ...
|   |   |   |-- Dockerfile          contains Docker's build/run params
|   |   |   |-- supervisord.conf    supervisord's config file for container
|   |   |-- src                     contains app's code. Should be created manually during installation new project
|   |   |-- ...
|   |-- db/                         contains db's files
|   |   |-- data/                   contains db's data files, e.g. MYSQL's tables' data
|   |   |-- dockerfiles/            contains custom Dockerfile and additional files for build/run db's Docker container
|   |   |   |-- ...                 see above for app service
|   |-- proxy/                      contains reverse proxy's files
|   |   |-- nginx-conf/             contains NGINX config files
|   |   |   |-- proxy.conf          NGINX config file
|   |-- shared/                     contains files shared between project's containers as e.g. "/dm-shared" alias folder
|   |-- docker-compose.yml          contains project's build and run settings, e.g. services' (container's) list etc
|   |-- host.env                    contains environment's variables
|   |-- ...
|   |
|   |   NOTE: host.env file generates automatically when start.sh script is used!!!
|   |
|
|-- DM_PROJECT/                 contains docker/docker-compose configs and data files for sub-project. Shoud be UNIQUE through the current DM's instance
|   |-- ...                     see "main" folder structure for details
|
|-- ...
 
proxy/                          contains docker container for common DM proxy (see jwilder/nginx-proxy docker image for details)
|-- custom.conf                 rewrite some default nginx settings, e.g. client_max_body_size option etc
|-- default_location            hack for NGINX's virtual hosts shared robots.txt file
|-- docker-compose.yml          contains reverse proxy's build and run settings
|-- Dockerfile                  Dockerfile for proxy container
|-- host.env                    contains environment's variables
|-- nginx.tmpl                  contains custom template for NGINX's configs
|-- run.sh                      proxy's entrypoint
|-- run_once.sh                 proxy's once entrypoint
 
|-- dm                          bin scripts wrapper
```

</p>
</details>



## Quick Guide

TODO

While installation process you should do follow steps:
- configure Docker Manager
- re-configure `Apache` settings, setting up `Apache mod_proxy`, `/etc/hosts` file etc
- install Docker CE and Docker Compose
- add current user to `docker` group (to fix group membership [error](https://stackoverflow.com/questions/29101043/cant-connect-to-docker-from-docker-compose))

You could do it automatically using CLI command `dm install` or manually. Please, follow to the related steps.



## Installation steps

Installation steps, CLI command `./dm install` and `bin/install.sh` script are actual for Ubuntu 16.04 OS only! 
Script's work didn't test with other OS!
 
Depending on installation placement (`local host` or `remote server`) you have to choose follow installation steps.



### 1. Prepare environment

#### Prepare local host environment

This step required if there are `Apache` web server listened standard port `80` at the host machine. 
Otherwise you could go to the [Prepare remote server environment](#prepare-remote-server-environment) section.
If you have another web server listened port `80` then you have to continue installation manually. 

*Replace `VIRTUAL_HOST_NAME` with real folder name of virtual host for Docker Manager installation.*

1.1) Creating new virtual host's folder and setting up `Apache` config
 
Do this automatically using [small script](https://github.com/demmonico/bash/blob/master/newsite.sh).
 
```sh
# get newsite.sh script
sudo wget -q https://raw.githubusercontent.com/demmonico/bash/master/newsite.sh -O /var/www/newsite.sh && sudo chmod +x /var/www/newsite.sh
 
# create new virtual host
sudo /var/www/newsite.sh -n VIRTUAL_HOST_NAME
```

Also you could do it manually.

1.2) Download Docker Manager

```sh
cd /var/www/VIRTUAL_HOST_NAME
 
# pull
git init && git remote add origin https://github.com/demmonico/docker-manager && git pull origin master
```

1.3) Remove git dependencies

Remove `.git` folder and `.gitignore` file to avoid nested git IDE errors. *You could pass this step if you planning to get updates or make some pull requests in the future ;)*

```sh
rm -rf .git && rm -f .gitignore
```



#### Prepare remote server environment

This step required if there are no installed `Apache`/`Nginx` web servers and standard port `80` is free at the host machine. 
Otherwise you could go to the [Prepare local host environment](#prepare-local-host-environment) section.

1.1) Creating folder and download Docker Manager

*You could replace `docker-manager` with custom name or change Docker Manager installation path `/var`.*

```sh
# pull
sudo git clone https://github.com/demmonico/docker-manager /var/docker-manager && sudo chown -R $USER:$USER /var/docker-manager
 
cd /var/docker-manager
```

1.2) Remove git dependencies (optional step for remote installations)

Remove `.git` folder and `.gitignore` file to avoid nested git IDE errors. *You could pass this step if you planning to get updates in the future*

```sh
rm -rf .git && rm -f .gitignore
```



### 2. Run installation

While installation process you should do follow steps:
- configure Docker Manager
- re-configure `Apache` settings, setting up `Apache mod_proxy`, `/etc/hosts` file etc
- install Docker CE and Docker Compose
- add current user to `docker` group (to fix group membership [error](https://stackoverflow.com/questions/29101043/cant-connect-to-docker-from-docker-compose))

You could do it automatically using CLI command `dm install` or manually. Please, follow to the related steps.



#### Automated installation

##### 2.1) Run install script

```sh
sudo ./dm install [OPTIONS] -h DM_HOST_NAME [-n DM_NAME] [-p DM_HOST_PORT]
```

See the [CLI command readme](BIN_HELP.md#install) file for details.

***Example 1***

This instance of the Docker Manager will be named as `test`. It placed at `/var/docker-manager` folder.
 
Main domain's name of the project, which is hosted by Docker Manager, is `docker.localhost`. 
Docker Manager main project will be accessible as this address. 
All sub-projects will be accessible as sub-domains (e.g. `subdomain.docker.localhost`). 

```sh
sudo /var/docker-manager/dm install -h docker.localhost -n test
```

***Example 2***

If name of the Docker Manager's instance isn't set then folder's name will be used as name - `docker-manager` here.
Port is changed to `8080`.

```sh
sudo /var/docker-manager/dm install -h docker.localhost -p 8080
```

***Example 3***

If we want just re-configure Docker Manager, e.g. to another port, we could use `-c` option.
Port is changed to `8081`, configuration is refreshed and no installation was done.

```sh
sudo /var/docker-manager/dm install -c -h docker.localhost -p 8081
```

##### 2.2) Configure Docker Manager

See setup sensitive information section at [Configure Docker Manager](#configure-docker-manager).



#### Manual installation

<details><summary>Click here to expand</summary>
<p>


##### 2.1) Prepare host environment

At the Debian's OS please, follow steps below or see [guide](https://docs.docker.com/engine/installation/)

##### Install Docker CE

```sh
# setup repository
sudo apt-get update && \
sudo apt-get install \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common && \
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add - && \
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable" && \
   
# install docker
sudo apt-get update && \
sudo apt-get install docker-ce
```

##### Install Docker Compose
```sh
sudo apt-get install docker-compose
```

***Note*** If further you'll catch an error similar to the following
```diff
- Couldn't connect to Docker daemon at http+unix://var/run/docker.sock - is it running?
```
then try to fix it, as described [here](https://stackoverflow.com/questions/29101043/cant-connect-to-docker-from-docker-compose) - add new group `docker` and add yourself there
```sh
# 1. Create the docker group.
sudo groupadd docker
# 2. Add your user to the docker group.
sudo usermod -aG docker $USER
# 3. Log out and log back in so that your group membership is re-evaluated.
```
***Note*** that step 3 you could do later (see [3. Re-login](#3-re-login))


##### 2.2) Installation

##### Install at the local environment (case when locally Apache server installed and/or busy port 80)

1) Create new website project's folder and setup `Apache` configs manually or automatically using [script](https://github.com/demmonico/bash/blob/master/newsite.sh)
```sh
# prepare
sudo wget -q https://raw.githubusercontent.com/demmonico/bash/master/newsite.sh -O /var/www/newsite.sh
cd /var/www/
sudo chmod +x newsite.sh

# create new site
sudo ./newsite.sh -n SITENAME
```
***Note*** to automatically remove website and clear up hosts and `Apache` settings you can use [script](https://github.com/demmonico/bash/blob/master/rmsite.sh)
```sh
# pulling script the same as newsite.sh
# and afterward run it
sudo ./rmsite.sh -n SITENAME
```

2) Pull this structure from git repo
```sh
cd SITENAME/
git remote add origin https://github.com/demmonico/docker-manager
git pull origin master
```
Now you could remove `.git` folder to avoid nested git IDE errors

3) Correct host's `Apache` config and setup docker-manager host's settings.

Follow will provide you correct work both with inner docker projects and with your exists `Apache` projects. 

- re-configure `Apache` for using proxy mod's for Docker Manager's virtual host. ***Note*** please, check whether `Apache` proxy mod is enabled
- update `hosts` file to make available new virtual hosts


##### Install at the server environment (for development purposes, not for production!)

Just pull this structure from git repo into a folder e.g. `/var/docker-manager` 
```sh
git clone https://github.com/demmonico/docker-manager /var/docker-manager
```
Now you could remove `.git` folder to avoid nested git IDE errors


##### 2.3) Configure Docker Manager

See [Configure Docker Manager](#configure-docker-manager).

</p>
</details>



### 3. Re-login

Re-evaluated your group membership to fixing docker group permissions and avoid following errors in the future:
 
```diff
- Couldn't connect to Docker daemon at http+unix://var/run/docker.sock - is it running?
```

- in case of **remote usage** re-login your SSH session 
- in case of **local usage** restart/re-login machine 

[Source](https://stackoverflow.com/questions/29101043/cant-connect-to-docker-from-docker-compose)



### Uninstall

1) Stop all containers of this Docker Manager instance using CLI command `dm stop`

2) Remove Docker Manager folder
```sh
sudo rm -rf /var/docker-manager
```

3) Docker CE uninstall
```sh
sudo apt-get purge docker-ce
 
sudo rm -rf /var/lib/docker
```

4) Docker Compose uninstall
```sh
sudo rm /usr/local/bin/docker-compose
```

5) Clear groups
```sh
sudo groupdel docker
```



## Configuration

### Configure Docker Manager

##### Setup common config

If you've install Docker Manager via [Automated installation](#automated-installation) you could skip this step.

There are 2 ways to configure Docker Manager: 
- automatically using CLI command `dm install -c` (see [Automated installation](#automated-installation) section) 
- manually copying file `config/local-example.yml` to `config/local.yml` and tune configs and command aliases



##### Setup sensitive information

1) Create `config/security` folder if it doesn't exists
2) Create `config/security/common.yml` config file with token to provide free access to `github.com`
```
tokens:
  github: YOUR_GITHUB_TOKEN
```
3) Optionally copy your SSH keys and known hosts files into the `config/security/ssh-keys` folder: 
```
id_rsa
id_rsa.pub
known_hosts
```

For using common defined SSH keys through the all projects then this folder should be mounted as a volume to any container at the `docker-compose.yml` file as `~/.ssh` folder.



### Copy or pull projects

1) For main project start this step could be passed. 
If you want to create sub-project then you should create unique folder (named e.g. `sub_project`) at `projects` folder. 
Further this sub-project will be available as `sub_project.your_docker_manager.dev-server.com` sub-domain. 
 
2) Create new app, db, proxy, shared and etc. folders regarding to the services at your applications. 
***Recommended*** create separate folder per each service (`app`, `db`...)

3) Copy or pull (via git for example) your project's code and data regarding the [DM's structure](#structure).

Main project's files should be placed at `projects/main` folder 
(accessible as main domain's name of the project e.g. `your_docker_manager.dev-server.com` - see [Automated installation](#automated-installation)).

- put app's code to `projects/main/app/src` folder
- put app's data to `projects/main/app/data` folder
- put db's data to `projects/main/db/data` folder

Sub-project's files should be placed at `projects/your_sub_domain` folder 
(accessible as sub-domain e.g. `sub-domain.your_docker_manager.dev-server.com`). 
***Note:*** folder's name should be unique through all projects of the Docker Manager instance.

- put app's code to `projects/DM_PROJECT/app/src` folder
- put app's data to `projects/DM_PROJECT/app/data` folder
- put db's data to `projects/DM_PROJECT/db/data` folder

***Important*** Check project's folder permissions. It should be owned by you current user (***NOT ROOT!***), which will run `/dm` scripts wrapper further.



### Configure project

#### Configs priority

You can manage your project settings using several ways (**from high to low priority** - [see](https://docs.docker.com/compose/environment-variables/#the-env-file)): 
- Compose files `*.yml`. In the frame of DM usage you could use their overriding in the follow order:
    - `projects/DM_PROJECT/docker-compose.local.yml` - **optional** **out of VCS** project's local config. Could be used for override configs from all below files
    - `projects/DM_PROJECT/docker-compose.override.yml` - **optional** project's override config. Could be used for override configs from the `config/docker-compose.d/*.yml` files and below
    - `config/docker-compose.d/*.yml` - define common used configs of the defined service (`app`, `db`). Called only if service present at the project's main `yml` config. For example exists `app.yml` file will be bound only if project's `docker-compose.yml` file contains service named `app`
    - `config/docker-compose.d/networks.yml` - define common DM's network. Called **ALWAYS**
    - `projects/DM_PROJECT/docker-compose.yml` - project's main config. Called **ALWAYS**
- Environment file
    - `host.env` which exists by default if using DM
    - any included to Docker Compose file manually
- Dockerfile


##### Compose files

Main compose `docker-compose.yml` file with project's settings placed at your project's folder (`projects/DM_PROJECT`). 
You could pull it within `env`/`docker` branch your project or create it manually. 
As Docker Compose file structure example you could use projects at the `demo/` folder.

*Tip: you could save project configuration to the separate repository or separate branch of the project's repository to provide IaC*

At `docker-compose.yml` file you could:
- setting a lot of services configurations
***Note*** if you rename container's name then it should be unique through the all running Docker containers.
- mounting volumes
- defining network links, build arguments and environment variables
 
As a base images of Docker container you could use:
- pre-defined docker's images pulled from `dockerhub.com`
- pre-defined common docker's images at `images/` folder
- custom build image based on your custom Dockerfiles - just create `dockerfiles` folder (e.g. `projects/DM_PROJECT/app/dockerfiles` - see [DM's structure](#structure)) and put `Dockerfile` and all additional custom scripts or files there

If you want to add a `Apache` dummy (like "Waiting" message) which will be shown while containers are starting then you should: 
- create at your project's folder e.g. `app/dockerfiles/install/apache-dummy` folder (see [DM's structure](#structure)) with dummy files or pull from [repository](https://github.com/demmonico/apache-dummy)
- set build argument `DUMMY=apache-dummy` at the `docker-compose.yml` file.


##### Environment file

Files contains list of environment variables which will be accessible into container's runtime.

File `host.env` already exists by default for DM usage case (`dm start` script creates it automatically). **Note** file `host.env`:
- is out of VCS 
- is already included to container for services `app` and `db` (defined at the `config/docker-compose.d/*.yml` files)
- isn't recreated while restarting project/containers

You could add custom variables to the `host.env` file (through it isn't recreated while restarting) or just create another by your own and include it to the project's Docker Compose file at the `env_file` section. 


##### Dockerfile

You could create your own `Dockerfile` and build your custom image. 
This way is more effort but it allows the widest way for customization. 
[See](https://docs.docker.com/engine/reference/builder/) for details.


#### Environment variables

Using environment variables you could drive many processes at all container's life stages. 
You can pass environment variables inside your container using any way described above.
 
All DM's environment variables are prefixed due to the follow rules:
- `DM_`  - common used DM env var
- `DMB_` - DM env var used at the `build` stage
- `DMC_` - DM env var used inside the container


##### Customize DB settings

For customize DB settings at the `app` container use environment variables
```sh
# alias name of internal DB host
- DMC_DB_SERVICE=db
 
# [optional] assigned DB name if it differ with DM_PROJECT
- DMC_DB_NAME=test-db
 
# [optional] change MySQL files location (/var/lib/mysql by default)
- DMC_DB_FILES_DIR=/tmp/mysql
```


##### Tune PHP settings

To drive your settings of the internal application's PHP service:
- `DMC_APP_APACHE_UPLOADMAXFILESIZE` - PHP `upload_max_filesize` param (auto-adjust next param too)
```sh
- DMC_APP_APACHE_UPLOADMAXFILESIZE=20M
```
- `DMC_APP_APACHE_POSTMAXSIZE` - PHP `post_max_size` param (auto-adjust next param too)
- `DMC_APP_APACHE_MEMORYLIMIT` - PHP `memory_limit` param (auto-validate free memory)
- `DMC_APP_APACHE_MAXEXECTIME` - PHP `max_execution_time` param
- `DMC_APP_APACHE_MAXINPUTTIME` - PHP `max_input_time` param


##### Add domains to hosts file

You could add one/several domains to the internal container's `/etc/hosts` file using `DMC_CUSTOM_ADD_HOSTS` variable. 
Useful at the `development` environment when you need link several DM projects or another local hosts. 
**Note** exists rows contains these domains will be commented.

```sh
# one domain by IP
- DMC_CUSTOM_ADD_HOSTS=192.168.100.1:example.com
 
# one domain by DM container name
- DMC_CUSTOM_ADD_HOSTS=dc000example_app_1:example.com
 
# several domains separated by ";"
- DMC_CUSTOM_ADD_HOSTS=dc000example_app_1:example1.com;192.168.100.1:example2.com;dc000test_app_1:test.com
```


##### Add custom command to the entrypoint script

To run custom commands while container build/start you could use special custom env variables within custom scripts:
- `DMC_CUSTOM_RUN_COMMAND` (called when container starts)
```sh
# create file under user dm every time when container starts
- DMC_CUSTOM_RUN_COMMAND=sudo -u dm bash -c "touch /tmp/run"
 
# add another local domain to inner /etc/hosts file
- DMC_CUSTOM_RUN_COMMAND=bash -c "echo 172.18.0.3 local.example.loc >> /etc/hosts"
 
# add another local domain (which running at the container named dm000main_app_1) to inner /etc/hosts file
- DMC_CUSTOM_RUN_COMMAND=bash -c `echo "$$( getent hosts dm000main_app_1 | awk '{ print $$1 }' ) dc" >> /etc/hosts`
```

- `DMC_CUSTOM_RUNONCE_COMMAND` (called once when container creates)
```sh
# create file once when container creates (under user root by defaults)
- DMC_CUSTOM_RUNONCE_COMMAND=bash -c "touch /tmp/runonce"
 
# install NodeJS and php7.1-sqlite extension
- DMC_CUSTOM_RUNONCE_COMMAND=bash -c "curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && sudo apt-get install -y nodejs && apt-get install -y php7.1-sqlite"
```



#### SSL certificates

You could enable SSL protection at your web-site (or/and sub-domains). 

<details><summary>Follow steps</summary>
<p>

1. Generate SSL certificates (or buy). As a result of this step you have to get `.crt` and `.key` files. If you going to generate:
    - create a file called `openssl.cnf` with the following details
    ```cnf
        [req]
        distinguished_name = req_distinguished_name
        req_extensions = v3_req
     
        [req_distinguished_name]
        countryName = SL
        countryName_default = SL
        stateOrProvinceName = Western
        stateOrProvinceName_default = Western
        localityName = Colombo
        localityName_default = Colombo
        organizationalUnitName = ABC
        organizationalUnitName_default = ABC
        commonName = *.dev.abc.com
        commonName_max = 64
     
        [ v3_req ]
        # Extensions to add to a certificate request
        basicConstraints = CA:FALSE
        keyUsage = nonRepudiation, digitalSignature, keyEncipherment
        subjectAltName = @alt_names
     
        [alt_names]
        DNS.1 = *.api.dev.abc.com
        DNS.2 = *.app.dev.abc.com
    ```
    
    - create the Private key
    ```sh
    sudo openssl genrsa -out server.key 2048
    ```
    
    - create Certificate Signing Request (CSR)
    ```sh
    sudo openssl req -new -out server.csr -key server.key -config openssl.cnf
    ```
    **Note:** for the common name type as `*.dev.abc.com`. 
    It will take the default values mentioned above for other values.
    
    - sign the SSL Certificate (you'll get files `server.csr`, `server.key` and `server.crt`)
    ```sh
    # file server.csr certificate will contains *.dev.abc.com as the common name and other domain names as the DNS alternative names
    sudo openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt -extensions v3_req -extfile openssl.cnf
    ```
    
2. For using wildcard certificates you have to smooth naming files, e.g. `VIRTUAL_HOST=foo.bar.com` would use cert name `bar.com.crt` and `bar.com.key`. 
[See](https://github.com/jwilder/nginx-proxy#wildcard-certificates) for details

3. Bind port `443` and mount volume with certs to the `proxy` container. 
Use as an example `proxy/docker-compose.local-ssl-example.yml` file. 
**Note**: for `local` environment it would work if you disable (or configure specially) your host's web-server (`Apache` etc) and set up `DM_HOST_PORT` to port `80` directly

4. Make sure that ports are bound correctly and restart DM.
**Note**: by default router `NGINX` will redirect all requests from `http` to `https`. 
To avoid that you could manually add env variable `HTTPS_METHOD=noredirect` to the project when you want to disable that behavior. 
[See](https://github.com/jwilder/nginx-proxy#how-ssl-support-works) for details

</p>
</details>



#### HTTP Basic Authentication

You could enable HTTP Basic Authentication at your web-site (or/and sub-domains). 

<details><summary>Follow steps</summary>
<p>

1. Generate `htpasswd` file(s). 
If you want to use separate user profiles for you sub-domains then you have to repeat this step as many times as you need.  
```sh
# create file for credentials
htpasswd -c .htpasswd
 
# add user name and password credentials
htpasswd -cb .htpasswd username userpassword
```
 
2. Mount file as a volume with certs to the `proxy` container. Filename should be equal with host name which you want to protect. 
Use as an example `proxy/docker-compose.local-ssl-example.yml` file. 
**Note**: if you need to include several `htpasswd` files then you have to mount all of them. 
[See](https://github.com/jwilder/nginx-proxy#basic-authentication-support) for details

3. Make sure that all settings are correct and restart DM.

</p>
</details>



## Usage

### Start project(s)

To build and start proxy, main container and all containers of all (or selected one only) projects you should use command:
```sh
./dm start [DM_PROJECT]
```

See the [CLI command readme](BIN_HELP.md#start) file for details.

*Tip: If you want to run you Docker Manager automatically when OS loads (e.g. for dev-server environment) then you could add `/var/docker-manager/bin/start.sh` script to your system scheduler.*



### Stop project(s)

To stop proxy, main container and all containers of all (or selected one only) projects you should use command:
```sh
./dm stop [OPTIONS] [DM_PROJECT]
```

See the [CLI command readme](BIN_HELP.md#stop) file for details.

***Example 1***

Stop main project, DM proxy, all sub-projects.

```sh
/var/docker-manager/dm stop
```

***Example 2***

Stop and remove all containers related to main project, DM proxy, all sub-projects. 
For example, you want to re-build some container from the main project or DM proxy. 

```sh
/var/docker-manager/dm stop -c
```

***Example 3***

Stop single sub-project named `sub_project_name`.

```sh
/var/docker-manager/dm stop sub_project_name
```

***Example 4***

Stop and remove all containers with all base images related to the single sub-project named `sub_project_name`. 
For example, you want to change container base image of the some container and re-build it. 

```sh
/var/docker-manager/dm stop -f -a sub_project_name
```


### Exec command inside container

To exec command inside some container of your project you should use command:
```sh
./dm exec DM_PROJECT [PARAMS][-c COMMAND [PARAMS] (default bash)]
```

See the [CLI command readme](BIN_HELP.md#exec) file for details.

**Note** you could exec command using command aliases which could be defined at the `config/local.yml` file. 
For examples see `config/local-example.yml` file which contains several pre-defined aliases.

**Note** you could exec pre-defined command scripts loaded into `DMC_INSTALL_DIR` inside the container. 
File naming rules is `exec_cmd_name.sh` where `name` is your cmd name.   
For examples see pre-defined scripts at the [app image](https://github.com/demmonico/docker-ubuntu-apache-php).

***Example 1***

Simple call container's terminal.

```sh
/var/docker-manager/dm exec DM_PROJECT
```

By default:
- service name is `app`
- service instance name is `1`
- user is `dm` user

***Example 2***

Call command `uname -a` under `root`

```sh
/var/docker-manager/dm exec DM_PROJECT -u root -c uname -a
```

***Example 3***

Call command `uname -a` with specified user `root`, service name `db`, service instance name `2`

```sh
/var/docker-manager/dm exec DM_PROJECT -s db -i 2 -u root -c uname -a
```

***Example 4***

Call command alias defined at the `config/local.yml` file

```sh
# at the `config/local.yml` file
container:
  cmd_aliases:
    - laravel/phpunit=/var/www/html/vendor/bin/phpunit -c /var/www/html/phpunit.xml
    
# run in terminal
/var/docker-manager/dm exec DM_PROJECT -c laravel/phpunit
```

***Example 5***

Call pre-defined command scripts loaded inside the container. 
See pre-defined at the [app](https://github.com/demmonico/docker-ubuntu-apache-php) and [db](https://github.com/demmonico/docker-ubuntu-mariadb) containers:
 
- add manually domain to the `app` container `/etc/hosts` file:

```sh
# at the `app` container exists
/dm-install/exec_cmd_hosts_add.sh
    
# run in terminal
/var/docker-manager/dm exec DM_PROJECT -c lib/hosts/add 192.168.100.1 example.com
# or
/var/docker-manager/dm exec DM_PROJECT -c lib/hosts/add dc000example_app_1 example.com
```

- remove manually domain from the `app` container `/etc/hosts` file:

```sh
# at the `app` container exists
/dm-install/exec_cmd_hosts_remove.sh
    
# run in terminal
/var/docker-manager/dm exec DM_PROJECT -c lib/hosts/remove example.com
```

- export DB dump at the `db` container (dump file will be placed at the `/var/lib/mysql` folder):

```sh
# at the `app` container exists
/dm-install/exec_cmd_mysql_export.sh
    
# run in terminal
/var/docker-manager/dm exec DM_PROJECT -c lib/mysql/export
# or for getting gzip
/var/docker-manager/dm exec DM_PROJECT -c lib/mysql/export gzip
```

- import DB dump at the `db` container (dump file should be placed at the `/var/lib/mysql` folder):

```sh
# at the `app` container exists
/dm-install/exec_cmd_mysql_import.sh
    
# run in terminal
/var/docker-manager/dm exec DM_PROJECT -c lib/mysql/import testdump.sql
# or for gzip
/var/docker-manager/dm exec DM_PROJECT -c lib/mysql/export testdump.sql.gz
```


### Inspect containers

To inspect containers of your project you should use command:
```sh
./dm inspect DM_PROJECT [PARAMS] PROPERTY_NAME
```

See the [CLI command readme](BIN_HELP.md#inspect) file for details.

***Example***

Get container's id with specified service name `db`, service instance name `2`

```sh
/var/docker-manager/dm exec DM_PROJECT -s db -i 2 id
```



### CLI command readme

See the [CLI command readme](BIN_HELP.md) file for more information about DM CLI commands.



## Change log

See the [CHANGELOG](CHANGELOG.md) file for change logs.



## License

See the [LICENSE](LICENSE) file for license rights and limitations (Apache License v2.0).
