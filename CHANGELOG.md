# 0.5.0-alpha (2018-03-12)

- add CLI command wrapper `dm` for `bin/*` scripts
- move `bin/*` scripts detailed info to the separate file to provide CLI help
 

# 0.4.0 (2018-03-09)

- test project was moved to the separate `demo/` folder
- main project was moved to the common `projects/` folder (auto-creates while auto-installation)
 
 
# 0.3.0 (2018-01-04)

- refactor `start.sh` script, remove `add.sh` script, optimize all scripts
- multiple Docker Manager apps:
    - add dynamical host's port binding
    - realize overlay for run several Docker Manager apps simultaneously
- add key `-f` to forced remove images and containers
- create common settings file - `config/local.yml`
- move host configs to common settings file, clear proxy's folder
- add `install.sh` script for common (**server**/**local**) purposes
- edit NGINX config template for DM proxy based on `jwilder/nginx-proxy` 


# 0.2.0 (2017-12-01)

- add `CHANGELOG.md` :)
- add `LICENSE`
- docker images:
    - refactor structure of image source folder, add version of image format, add new format version
    - split run and run_once scripts on base and custom one
    - remove apache dummy from image, add dummy customization possibility
    - add rsync, zip etc. utils to all apps' containers
    - fix Moodle image: replace related sitename into fixed - for cron jobs
    - fix cron service start at app containers
    - add new app apache-php-based container with refactored structure
    - add new app apache-Moodle-based container with refactored structure
    - add new app apache-Yii2-based container with refactored structure
    - move docker images to separate repository and Docker Hub
- create common security's config folder at `/config` and replace `ssh` folder there
- add `TODO.md`


# 0.1.0 (2017-11-17)

- First release
