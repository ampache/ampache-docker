# ampache-docker

Docker container for Ampache, a web based audio/video streaming application and file manager allowing you to access your music & videos from anywhere, using almost any internet enabled device.

## build status

![travis status](https://travis-ci.org/ampache/ampache-docker.svg?branch=master)

## Develop build status

![travis status](https://travis-ci.org/ampache/ampache-docker.svg?branch=develop)

## noSQL build status

![travis status](https://travis-ci.org/ampache/ampache-docker.svg?branch=nosql)

## Usage

### docker run

To run official builds from docker hub you can run these commands:

To run the current Ampache master (stable) branch

```bash
docker run --name=ampache -d -v /path/to/your/music:/media:ro -p 80:80 ampache/ampache
```

To run the current Ampache master (stable) branch **without an SQL server!**

```bash
docker run --name=ampache -d -v /path/to/your/music:/media:ro -p 80:80 ampache/ampache:nosql
```

To run the current Ampache develop branch

```bash
docker run --name=ampache -d -v /path/to/your/music:/media:ro -p 80:80 ampache/ampache:develop
```

~~The develop tag is set up to use git updates so you don't have to rebuild your images to stay up to date with development.~~

### docker-compose

This method is recommended as it creates persistent volumes for important data. Included in the [GitHub repository](https://github.com/ampache/ampache-docker/blob/master/docker-compose.yml) is a simple `docker-compose.yml` file to get started. Use the following commands:

```bash
docker-compose up -d
```

The first time you run the container, you will need to create data folders and set the correct permissions on the configuration folder:

```bash
./docker-compose.sh
```

This will automatically create mount points for:

* Media catalog "/media" folder `./data/media`
* Ampache debug logs `./data/log` 
* Ampache config folder `./data/config`.

## Running on ARM

The automated builds for the official repo are now built for linux/amd64, linux/arm/v7 and linux/arm64.

## Installation

1. Open [http://localhost/install.php](http://localhost/install.php) and click **Start Configuration**, then **Continue**
2. On the **Insert Ampache Database** page:
    1. **MySQL Administrative Username**: admin
    2. **MySQL Administrative Password**: (see container output)
        * The logs will show a line that says `mysql -uadmin -pjnzYXLz7cMzq -h<host> -P<port>`. The password is everything after `-p`, in this case `jnzYXLz7cMzq`.
    3. Check **Create Database User**
    4. **Ampache Database User Password**: Enter anything
    5. Click **Insert Database**
3. **Generate Configuration File** page:
    1. Click **Create Config**
4. **Create Admin Account** page:
    1. Enter anything for **Username** and **Password**
    2. Click **Create Account**
5. **Ampache Update** page:
    1. Click **Update Now!**
    2. Click [Return to main page] to login using previously entered credentials

## Thanks to

* @ericfrederich for his original work
* @velocity303 and @goldy for the other ampache-docker inspiration
* @kuzi-moto for bringing the image out of the dark ages

## Current Release

Ampache 4.2.5

