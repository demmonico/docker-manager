### Docker Manager bin scripts help

This document is a helper for using DM CLI scripts.

### CLI commands usage

Following commands are available. 
Better use them through `./dm` script wrapper, which provide you completions and shorter calling.

Also you could use command aliases which allowed you shorter syntax. Aliases configured at the `config/local.yml` file.


##### Version

To show version you should use command:
```sh
FORMAT:
    ./dm version
```


##### Install

To automatically installation use command:

```sh
FORMAT:
    # using wrapper
    sudo ./dm install [OPTIONS] -h DM_HOST_NAME [-n DM_NAME] [-p DM_HOST_PORT]
    # or directly
    sudo ./bin/install.sh [OPTIONS] -h DM_HOST_NAME [-n DM_NAME] [-p DM_HOST_PORT]
 
OPTIONS:
    -c - configurate only (no prepare environment actions)
```

Note:
 - **root permissions are required**
 - `DM_HOST_NAME` parameter is required, value must be unique and match [A-Za-z0-9] pattern (by default use current folder's name)
 - installation mode (`server`/`local`) will be detected automatically through analyzing `netstat` results for port `80` and either Apache installed
 - default `DM_HOST_PORT` value is `80` so for `local` mode it's getting required for re-assign default value :)
 - port pointed at `DM_HOST_PORT` value must be available 
 - via using `-c` option you could use `install.sh` script for configuration purposes only and passing Docker environment installation
 
 
##### Start
 
To build and start proxy, main container and all containers of all (or selected one only) projects you should use command:

```sh
FORMAT:
    # using wrapper
    ./dm start [DM_PROJECT]
    # or directly
    ./bin/start.sh [DM_PROJECT]
```

This script do: 
- init proxy gateway with common network (if it wasn't initiated yet) 
- init main host with main project domain's name (if it isn't inited yet) 
- if no options then init all sub-projects at the `projects` folder
- if option `DM_PROJECT` was defined then init sub-project named `DM_PROJECT` placed at the `projects` folder

Process "init" includes: 
- get Docker Manager settings
- define project's name and all default variables and export them to `host.env` file and `environment` section of the `docker-compose.yml` file
- if `DM_HOST_PORT` isn't equal to `80` (so it's local environment) then add line `127.0.0.1        sub_project_name.your_docker_manager.dev-server.com` to the `/etc/hosts` file. ***Note*** require to root permissions
- build chain of the docker-compose files
- build Docker container (if need it) - via Docker Compose engine
- start internal network for this project - via Docker Compose engine
- start Docker container - via Docker Compose engine 
 
 
##### Stop

To stop proxy, main container and all containers of all (or selected one only) projects you should use command:
```sh
FORMAT:
    # using wrapper
    ./dm stop [OPTIONS] [DM_PROJECT]
    # or directly
    ./bin/stop.sh [OPTIONS] [DM_PROJECT]
    
OPTIONS:
    -c - remove containers after they stops
    -a - remove all containers and their images after they stops
    -f - forced mode (see Docker documentation)
```

Single mode (if `DM_PROJECT` is defined):
- get Docker Manager settings and define project's name
- build chain of the docker-compose files
- stop Docker container - *via Docker Compose engine*
- remove Docker container (if need it) - *via Docker Compose engine*
- remove Docker image (if need it) - *via Docker Compose engine*
- remove all unused networks - *via Docker engine*

Multiple mode (if `DM_PROJECT` isn't defined):
- get Docker Manager settings and define project's name
- find all containers related to this project  
- stop containers - *via Docker engine*
- remove containers (if need it) - *via Docker engine*
- remove images (if need it) - *via Docker engine*
- remove all unused networks - *via Docker engine*


##### Exec

To exec command inside some container of your project you should use command:
```sh
FORMAT:
    ./dm exec DM_PROJECT [PARAMS][-c COMMAND [PARAMS] (default bash)]
    
PARAMS:
    -s - DM_PROJECT_SERVICE_NAME (default app)
    -i - DM_PROJECT_SERVICE_INSTANCE_NAME (default 1)
    -u - DMC_USER (default "dm" user)
```


##### Inspect

To inspect containers of your project you should use command:
```sh
FORMAT:
    ./dm inspect DM_PROJECT [PARAMS] PROPERTY_NAME
    
PARAMS:
    -s - DM_PROJECT_SERVICE_NAME (default app)
    -i - DM_PROJECT_SERVICE_INSTANCE_NAME (default 1)
    
PROPERTY_NAME:
    name    - return container's name
    id      - return container's id
    ip      - return container's IP at the DM common network 
    ips     - return all container's IPs
```


##### Help

To show CLI help you should use command:
```sh
FORMAT:
    # show help
    ./dm help
    
    # show commands list
    ./dm help/commands
    
    # show commands list without service commands
    ./dm help/commands -s
```
