# Docker CI structure

## Description

Docker-based structure for different web-sites deploy at dev-server.
This is a skeleton for automatically independent deploy different web-sites at dev-server and maintenance them further.



## Contents

- [Description](#description)
- [Install](#install)
- [Directory structure](#directory-structure)
- [Config](#config)
- [Usage](#usage)
- [Commands](#commands)



## Install

At the Debian's OS please, follow steps below or see [guide](https://docs.docker.com/engine/installation/) 

1) Install Docker CE at :
```php
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
```php
sudo apt-get install docker-compose
```

3) Get this structure from git repo e.g. into `/var/docker` folder
```php
git clone https://github.com/demmonico/docker-ci /var/docker
```



## Directory Structure
```
bin/            contains management scripts
config/         contains common configs
    ssh/        contains ssh keys of CI bot account and known hosts file. Will be bound to each virtual host
images/         contains docker images which further will be used at the projects
    ...
main/           contains docker container for main dev-server's host, which can be contains docker web-console etc.
projects/       contains docker containers for all virtual hosts (your web-sites) + test container. Excluded from VCS
    ...
proxy/          contains docker container for proxy
    config.yml/ contains settings for domain name of hosts gateway
    ...
```



## Config

Here you can configure follow things:

### SSH keys of CI bot and known hosts
If you want to download anything from git then you should create `config/ssh` folder and place ssh key files and known hosts file there.
Note that it is excluded from VCS.

### Host domain name
Please, edit `config.yml` file to setup host's domain name(s).

### Autostart
If you want to start you virtual hosts automatically after system's loads then you should add `/var/docker/bin/start.sh` (or your custom CI folder) to your system scheduler.



## Usage

### Project structure
In common way internal folder usages:
```
PROJECT_NAME/app                    contains web-site files
PROJECT_NAME/db                     contains db files
PROJECT_NAME/data                   contains additional data files, e.g. moodledata folder
PROJECT_NAME/docker-compose.yml     contains project build and run settings
```

### Project settings
You can drive your project settings via `PROJECT_NAME/docker-compose.yml` file. Use Docker Compose, exists pre-defined docker images and you custom Dockerfiles to build your containers.
At `docker-compose.yml` file you can define bound volumes, network links, container names etc.
Firstly you should replace all occurrences of your project's names at `docker-compose.yml` file with actual.

***Note*** that container's name should be unique through the all projects and have to reflect to the project's name.

### Environment variables
You can pass environment variables inside your container through the:
- on first container's run there are creates `PROJECT_NAME/hosts.env` file with common environments variables automatically. You can use it using `env_file` section.
- you can pass env variables via `docker-compose.yml` file using `environment` section.
- you can define any env variables in your custom Dockerfile.



## Commands
Here follows up available commands:

### Start all
To start proxy, main container and all exists project's containers you should use command `/var/docker/bin/start.sh`.

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
