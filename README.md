# Docker Manager structure

## Description

Docker-based structure for different web-sites deploy at dev-server and local development.
This is a skeleton for automatically independent deploy different web-sites at dev-server and maintenance them further.



## Contents

- [Description](#description)
- [Directory structure](#directory-structure)
- [Install](#install)
    - [Pre-Install Docker (Docker Compose)](#pre-install-docker)
    - [Install at development environment](#install-at-development-environment)
    - [Install at dev server environment](#install-at-dev-server-environment)
- [Config](#config)
    - [SSH keys of CI bot and known hosts](#ssh-keys-of-ci-bot-and-known-hosts)
    - [Host domain name](#host-domain-name)
    - [Autostart](#autostart)
- [Usage](#usage)
    - [Project settings](#project-settings)
    - [Environment variables](#environment-variables)
    - [Add new project](#add-new-project)
- [Commands](#commands)
    - [Start all](#start-all)
    - [Stop all](#stop-all)
    - [Start one](#start-one)
    - [Stop one](#stop-one)
- [Change log](#change-log)
- [License](#license)

 

## Directory Structure
```
bin/            contains management scripts
config/         contains common configs
    ssh/        contains ssh keys of CI bot account and known hosts file. Will be bound to each virtual host
images/         contains docker images which further will be used at the projects
    ...
main/           contains docker container for main dev-server's host, which can be contains docker web-console etc.
projects/       contains docker containers for all virtual hosts (your web-sites) + test container. Excluded from VCS
    PROJECT_NAME/
        ...
        app/                contains web-site files
        custom/             contains custom run/run_once bin scripts or another files
        data/               contains additional data files, e.g. moodledata folder
        db/                 contains db files
        shared/             contains files shared between this project's containers as "/docker-shared/FILES"
        docker-compose.yml  contains project build and run settings
        host.env            contains environment's variables. NOTE it generates automatically
        ...
    ...
proxy/          contains docker container for proxy
    config.yml/ contains settings for domain name of hosts gateway
    ...
```



## Install

Follow steps. ***Note*** that you couldn't use any copy of this docker-manager structure at the system simultaneously!

### Pre-Install Docker

At the Debian's OS please, follow steps below or see [guide](https://docs.docker.com/engine/installation/)

1) Install Docker CE at :
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

2) Install Docker Compose
```sh
sudo apt-get install docker-compose
```

***Note*** If further you'll catch an error similar to the following
```
Couldn't connect to Docker daemon at http+unix://var/run/docker.sock - is it running?
```
then try to fix it, as described [here](https://stackoverflow.com/questions/29101043/cant-connect-to-docker-from-docker-compose) - add new group `docker` and add yourself there
```sh
# 1. Create the docker group.
sudo groupadd docker
# 2. Add your user to the docker group.
sudo usermod -aG docker $USER
# 3. Log out and log back in so that your group membership is re-evaluated.
```


### Install at development environment (in case of locally installed Apache server listening port 80)

1) Create new website project's folder and setup Apache configs manually or automatically using [script](https://github.com/demmonico/bash/blob/master/newsite.sh)
```sh
# prepare
sudo wget -q https://raw.githubusercontent.com/demmonico/bash/master/newsite.sh -O /var/www/newsite.sh
cd /var/www/
sudo chmod +x newsite.sh

# create new site
sudo ./newsite.sh -n SITENAME
```
***Note*** to automatically remove website and clear up hosts and Apache settings you can use [script](https://github.com/demmonico/bash/blob/master/rmsite.sh)
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
Now you could remove `.git`  folder to avoid nested git IDE errors

3) Correct host's Apache config and setup docker-manager host's settings.
```sh
sudo ./bin/install-dev.sh SITENAME
```
Run this script will provide you correct work both with inner docker projects and with your exists Apache projects. ***Note*** please, check whether Apache proxy mod is enabled.

4) Copy your ssh keys and known hosts file into `config/ssh` folder to provide access to `github.com`

5) Build and start proxy, main and other containers. Note you should set environment to `dev` value
```sh
./bin/start.sh dev
```

### Install at server environment (for development purposes, not for production!)

1) Just pull this structure from git repo into a folder e.g. `/var/docker` 
```sh
git clone https://github.com/demmonico/docker-manager /var/docker
```
Now you could remove `.git`  folder to avoid nested git IDE errors

2) Copy file `proxy/config-example.yml` to `proxy/config.yml` and edit host name(s)

3) Copy your ssh keys and known hosts file into `config/ssh` folder to provide access to `github.com`

4) Build and start proxy, main and other containers
```sh
cd /var/docker
./bin/start.sh
```



## Config

Here you can configure follow things:

### SSH keys of CI bot and known hosts
If you want to download anything from git then you should create `config/ssh` folder and place ssh key files and known hosts file there.
Note that it is excluded from VCS.

### Host domain name
Please, edit `proxy/config.yml` file to setup host's domain name(s).

### Autostart
If you want to start you virtual hosts automatically after system's loads then you should add `/var/docker/bin/start.sh` (or your custom docker's folder) to your system scheduler.



## Usage

### Project settings
You can drive your project settings via `PROJECT_NAME/docker-compose.yml` file. Use Docker Compose, exists pre-defined docker images and you custom Dockerfiles to build your containers.
At `docker-compose.yml` file you can define bound volumes, network links, container names etc.
Firstly you should replace all occurrences of your project's names at `docker-compose.yml` file with actual.

***Note*** that container's name should be unique through the all projects and have to reflect to the project's name.

### Environment variables
You can pass environment variables inside your container through the:
- on first container's run there are creates `PROJECT_NAME/host.env` file with common environments variables automatically. You can use it using `env_file` section.
- you can pass env variables via `docker-compose.yml` file using `environment` section.
- you can define any env variables in your custom Dockerfile.

### Add new project
1) Create unique folder `projects/PROJECT_NAME` and `docker-compose.yml` file inside or you can copy it from `test` project.
2) Correct your `projects/PROJECT_NAME/docker-compose.yml` file remembering:
    - each container's name should be unique through all running containers
    - you can use inherits of exists docker images at `images/` or pull from `dockerhub.com` or use own
3) Add app code, data, database sql dump or custom running scripts if you need they.
4) Add new container to exists and run it
```sh
/var/docker/bin/add.sh PROJECT_NAME
```

***Important*** When you create new project at the local development environment you should add string to your local `/etc/hosts` file
```
127.0.0.1        PROJECT_NAME.DOCKER_HOSTNAME
```
***Important*** When you create new project or pull exists project you should add file `app/src/.gitkeep` (inside the app container it placed at `/var/www/html/.gitkeep`) to root `.gitignore` file of your project. Note that you shouldn't remove/replace it to avoid VCS conflicts at your `dockerconfig` branch. 



## Commands

***Important***
Please, note that you should run all commands from your current user (not from `root`) otherwise there can be permission fails both inside the docker container and at the host
Of course that the owner of all files in this structure should be your current user too.

Here follows up available commands:

### Start all
To start proxy, main container and all exists project's containers you should use command:
```sh
# dev server
/var/docker/bin/start.sh
# local dev
/var/docker/bin/start.sh dev
```

### Stop all
To stop all containers (included proxy and main) you should use command `/var/docker/bin/stop.sh [PARAMS]`.
Available params (you'd use one of following):
- -c - remove containers after they stops
- -a - remove containers and their images after they stops

### Start one
To start only one project's container you should use command `/var/docker/bin/add.sh PROJECT_NAME`.

### Stop one
To stop one container you should use command `/var/docker/bin/stop.sh [PARAMS] -n PROJECT_NAME`.
Available params are the same as in [Stop all](#stop-all) section.



## Change log

See the [CHANGELOG](CHANGELOG.md) file for change logs.



## License

See the [LICENSE](LICENSE) file for license rights and limitations (Apache License v2.0).
