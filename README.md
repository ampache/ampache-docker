# ampache-docker

Docker image for Ampache, a web based audio/video streaming application and file manager allowing you to access your music & videos from anywhere, using almost any internet enabled device.

## NEWS

### Ampache8 images

The images on this page build Ampache7, which is the current stable release. Official Ampache8 images will start being built closer to the Ampache8 release.

If you want to run Ampache8 code before then, the [`preview`](#ampachepreview) and [`nosql-preview`](#ampachenosql-develop-and-ampachenosql-preview) tags are built from the Ampache `develop8` branch. These are development builds, so expect them to break.

The `docker-compose.yml` in the [Ampache repository](https://github.com/ampache/ampache) itself is a full Ampache8 development stack: it builds `docker/Dockerfilephp85` (PHP 8.5) alongside a MariaDB service, and can install the database and create the admin user on first run. See [Ampache8 for Admins](/docs/help/troubleshooting/ampache8-for-admins#docker) for the environment variables it takes.

That is a different file to the `docker-compose.yml` in the ampache-docker repository described below.

### Debian Trixie

Debian has released a new stable version and containers are updated to match.

* MariaDB has been updated to the latest LTS version. Trixie itself ships PHP 8.4, but these images install PHP 8.5 from the [Sury](https://deb.sury.org) repository, so they already have the PHP version Ampache8 needs.
* The UID and GID of mysql has changed and this [commit](https://github.com/ampache/ampache-docker/commit/1020db4855d641b938560b90c513aa667c6f5df2) checks that your ID's match the container ID's.
* The included `php.ini` file has been updated so you may need to update yours depending on your changes.

For the Debian upgrade to Bookworm MariaDB upgrades caused one issue.

Have a look at [comment](https://github.com/ampache/ampache-docker/issues/102#issuecomment-1640956439) for information about how it was solved when there was an error during the upgrade.

## GitHub Project

[github.com](https://github.com/ampache/ampache-docker)

## How to use this image

This section covers two methods for running Ampache, first with the `docker run` command, and then using `docker-compose`.

### docker run

To run the current Ampache master (stable) branch:

```shell
docker run --name=ampache -d -v /path/to/your/music:/media:ro -p 80:80 ampache/ampache
```

### docker-compose

This method is recommended as it creates persistent volumes for important data and makes restarting the container much easier.

If you're already using Docker Desktop for Windows or Mac then Docker Compose is included. If you are using a different version or on Linux, follow these instructions in the docker docs: [Install Docker Compose](https://docs.docker.com/compose/install/)

In the [GitHub repository](https://github.com/ampache/ampache-docker/blob/master/docker-compose.yml) is a simple `docker-compose.yml` file to get started. Download the file and run this command to start an Ampache container:

```shell
docker-compose up -d
```

This automatically creates the following bind mounts:

* `./data/media` mounted at `/media` for music
* `./data/mysql` mounted at `/var/lib/mysql` for persistent MySQL storage
* `./data/config` mounted at `/var/www/config` for persistent Ampache configuration
* `./data/log` mounted at `/var/log/ampache` for debug logs

The [client](#ampacheclient) images add one more:

* `./data/client` mounted at `/var/tmp/client` for the client install scripts and their download and build cache

### Environment variables

You can configure parts of the container using environment variables. When running with `docker run`, you can set an environment variable using the `-e` parameter; for example, `-e FOO=BAR` sets the environemnt variable `FOO` to bar. When using `docker-compose`, you can set environment variables using a `.env` file in this directory.

Available environment variables are:

* `VERSION`: Ampache version to build using GitHub release [tags](https://github.com/ampache/ampache/tags)
* `MYSQL_USER`: Set your own MySql admin username (Default: admin)
* `MYSQL_PASS`: Set your own MySql admin password (Or one will be randomly generated for you)
* `DISABLE_INOTIFYWAIT_CLEAN`: If set to 1, disables the clean step on the directory monitor. This prevents Ampache from automatically cleaning files. If you are using a bind mount on an external storage, this may be desirable as it prevents Ampache from removing files if the external storage goes down.
* `LOG_FILE`: Full file path to ampache log file inside the container. (Default: /var/log/ampache/ampache.log) When available it will print log file data to the docker logs command. (e.g. `docker logs ampache`)
* `UID`: Change the uid of the `www-data` user in the container to match a user on your host
* `GID`: Change the gid of the `www-data` group in the container to match a group on your host

#### Automated install

When you install Ampache you can use the CLI to do it without using the web interface.

The following variables can be used to automatically install the server.

An install will only run when there is no existing config file (`/var/www/config/ampache.cfg.php`)

* `DB_NAME` Desired Database Name **REQUIRED**
* `DB_HOST` Hostname of your database **REQUIRED**
* `DB_USER` MySQL Administrative Username (Fallback to `MYSQL_USER`)
* `DB_PASSWORD` MySQL Administrative Password (Fallback to `MYSQL_PASS`)
* `DB_PORT` MySQL Port
* `FORCE_INSTALL` If 1 then forcibly replace any existing database
* `AMPACHE_DB_USER` Ampache Database Username (Fallback to `DB_USER`)
* `AMPACHE_DB_PASSWORD` Ampache Database Password (Fallback to `DB_PASSWORD`)
* `AMPACHE_ADMIN_USER` Admin username **REQUIRED**
* `AMPACHE_ADMIN_EMAIL` Admin email address **REQUIRED**
* `AMPACHE_ADMIN_PASSWORD` Admin password (A random password will be generated without)

* Random passwords can be assigned by using `**Random**` for the following variables
  * MYSQL_PASS
  * DB_PASSWORD
  * AMPACHE_DB_PASSWORD
  * AMPACHE_ADMIN_PASSWORD

#### Web clients

The [Ampache client](#ampacheclient) image types install a web client into the base of the web interface. (See [Web clients](#web-clients-1) for the clients that are included)

The install scripts must exist in the container. (Either copied from `/data/client` to `/var/tmp/client` during image build or by using a volume mounted to `/var/tmp/client`)

* `CLIENT_INSTALL` Client install script (Default: `ample.sh`)
* `CLIENT_VERSION` Client release tag to install, or `latest` (Default: `latest`)
* `CLIENT_ZIP` Install from a local zip instead of downloading a release (Ample only)
* `CLIENT_FORCE` If 1 then reinstall the client even when it is already installed

Downloads and builds are cached in `/var/tmp/client/.cache` so that recreating the container does not download or build the client again.

EXAMPLE: This will create an Ampache develop container on port 80 with a random password for the admin user.

```shell
docker run -d --name=ampache-develop \
    -e DB_NAME=ampache-develop \
    -e MYSQL_USER=admin \
    -e MYSQL_PASS=changeme \
    -e DB_HOST=localhost \
    -e AMPACHE_ADMIN_USER=admin \
    -e AMPACHE_ADMIN_EMAIL=admin@example.com \
    -p 80:80 \
    ampache/ampache:develop
```

This creates a new container with a local MariaDB and configures an admin account.

### Enable debug logging

The Ampache containers do not log anything by default.

You can Enable logging using the docker exec commands to sed your config file. These commands will update your config file to enable logging.

```shell
docker exec -it ampache sed -i "s/log_filename = \"%name.%Y%m%d.log\"/log_filename = \"ampache.log\"/g" /var/www/config/ampache.cfg.php
docker exec -it ampache sed -i "s/;debug = \"true\"/debug = \"true\"/g" /var/www/config/ampache.cfg.php
```

When enabled make sure there are no visual or permission issues showing up in your browser. If you get a permission error you can set the log folder permissions with these commands.

```shell
docker exec -it ampache chown www:data:www-data /var/log/ampache
docker exec -it ampache chmod 754 /var/log/ampache
```

Restart the container and logs will start flowing in!

```text
2025-08-25 23:55:53,909 INFO success: apache2 entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2025-08-25 23:55:53,909 INFO success: cron entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2025-08-25 23:55:53,909 INFO success: inotifywait entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2025-08-25T23:56:08+00:00 [ampache] (Ampache\Module\System\Dba) -> Database connection...
2025-08-25T23:56:08+00:00 [ampache] (Ampache\Module\System\Dba) -> Database connection...
2025-08-25T23:56:08+00:00 [user] (Ampache\Module\System\Session) -> f2b64ef63352084c9630aacfe7953677 has been extended to Tue, 26 Aug 2025 00:56:08 +0000 extension length 3600
2025-08-25T23:56:08+00:00 [user] (Ampache\Module\Application\ApplicationRunner) -> Found handler "Ampache\Module\Application\Index\ShowAction" for action "show"
2025-08-25T23:56:08+00:00 [user] (Ampache\Module\System\Session) -> Session created: 6ff7a5ebd8d9c629f3769ce7220c60ac
```

### Permissions

In the container the webserver runs as the http user (UID and GID 33). If you created the directories manually, it is important to ensure that the Ampache Configuration, and log directories are readable and writeable by that user.

```shell
chown 33:33 ./data/config -R
chown 33:33 ./data/log
```

Optionally, the media directory should be writable as if you wish to allow uploads.

```shell
chgrp 33 ./data/media && chmod g+w ./data/media
```

## Image Variants

For more advanced users a few different image variants are available.

### `ampache:<version>`

**Recommended**: Specifies a particular version from the Ampache master (stable) branch. Pinning Ampache to a specific version can prevent issues where you unexpectedly update a major version of Ampache with breaking changes you're not aware of.

e.g. `ampache:7`, `ampache:7.7.2`

Use something like [Diun](https://crazymax.dev/diun/) to monitor for updates to the image.

### `ampache:latest`

Pulls the most recent image from the Master (stable) branch

### `ampache:develop`

Pulls the most recent image from the Develop branch. This is generally safe to run but can break occasionally. Contains the latest features and updates.

### `ampache:preview`

Pulls the most recent image built from the Ampache `develop8` branch. This is unreleased Ampache8 code, so expect it to break. Use it to preview what is coming, not to run your library.

### `ampache:nosql`

For advanced users, this provides an image without a MySQL server built-in. You must provide your own MySQL server.

### `ampache:nosql<version>`

The `nosql` image pinned to a specific version.

e.g. `ampache:nosql7`, `ampache:nosql7.10.1`

### `ampache:nosql-develop` and `ampache:nosql-preview`

The `develop` and `preview` images without a MySQL server built-in.

### `ampache:client`

For advanced users, this provides an image using [Client Structure](/docs/information/ampache7-client-structure-install-type). This allows you to run your own API client inside the base of the web interface.

This image uses [Ample](https://github.com/mitchray/ample) by default and can be changed to [tinysub](https://tangled.org/devins.page/tinysub) or your own client. (See [Web clients](#web-clients-1))

### `ampache:client<version>`

The `client` image pinned to a specific version.

e.g. `ampache:client7`, `ampache:client7.10.1`

### `ampache:client-nosql`

For advanced users, this provides a [Client Structure](/docs/information/ampache7-client-structure-install-type) image without a MySQL server built-in. You must provide your own MySQL server.

### `ampache:client-nosql<version>`

The `client-nosql` image pinned to a specific version.

e.g. `ampache:client-nosql7`, `ampache:client-nosql7.10.1`

## Web clients

The client images ship an install script for each supported client in `/var/tmp/client`. Pick one with `CLIENT_INSTALL` and it is installed into the base of the web interface when the container starts. Ampache keeps working underneath at the usual paths (`/server`, `/rest`, `/play`, `/image.php` and so on), so the client is what you see when you open the container in a browser.

Nothing stops you adding your own script to `/var/tmp/client` and pointing `CLIENT_INSTALL` at it.

Switching between clients is best done on a fresh container. The web root is not a volume, so recreating the container gives you a clean Ampache install for the new client to write into.

### Ample

[Ample](https://github.com/mitchray/ample) is the default client and uses the Ampache API.

The latest release is downloaded from GitHub unless you pin one with `CLIENT_VERSION` or install a local zip with `CLIENT_ZIP`.

* `AMPACHE_URL` Written into `config/ample.json` as the `ampacheURL`

```shell
docker run -d --name=ampache-client \
    -e AMPACHE_URL=https://music.example.com \
    -p 80:80 \
    ampache/ampache:client
```

### tinysub

[tinysub](https://tangled.org/devins.page/tinysub) is an [OpenSubsonic](https://opensubsonic.netlify.app) client, so it talks to the Subsonic API at `/rest`. Make sure `subsonic_backend` is enabled in your Ampache config.

tinysub does not publish build artifacts, so the container clones the latest tagged source and builds it with npm on first start. The build needs network access and takes a few minutes. It is cached in `/var/tmp/client/.cache`, so keep that volume if you do not want to build again when the container is recreated. The npm cache in there uses a bit over 100MB and can be deleted at any time.

tinysub bakes its settings into the build, so changing any of these variables rebuilds the client.

* `TINYSUB_SERVER` Prefilled server url (Fallback to `AMPACHE_URL`)
* `TINYSUB_SERVER_LOCK` If true, hide the server url input (Default: false)
* `TINYSUB_USERNAME` Prefilled username
* `TINYSUB_PASSWORD` Prefilled password
* `TINYSUB_NAME` Deployment name shown in the settings page
* `TINYSUB_BASE_URL` Base path of the build (Default: `/`)
* `TINYSUB_BUILD_TARGET` Browser build target
* `TINYSUB_DIST` Install a prebuilt `dist` folder or zip instead of building

**The prefilled username and password are embedded in the build and readable by anyone who can load the page.** They exist for demo servers. Never set them to real user credentials.

```shell
docker run -d --name=ampache-tinysub \
    -e CLIENT_INSTALL=tinysub.sh \
    -e TINYSUB_SERVER=https://music.example.com \
    -e TINYSUB_NAME="My Server" \
    -p 80:80 \
    ampache/ampache:client
```

If you would rather not build in the container, build tinysub yourself (`npm install && npm run build`) and mount the result:

```shell
docker run -d --name=ampache-tinysub \
    -e CLIENT_INSTALL=tinysub.sh \
    -e TINYSUB_DIST=/var/tmp/client/dist \
    -v ./dist:/var/tmp/client/dist:ro \
    -p 80:80 \
    ampache/ampache:client
```

## Running on ARM

The automated builds for the official repo are now built for linux/amd64, linux/arm/v7 and linux/arm64.

Building [tinysub](#tinysub) inside the container is slow on ARM boards. Use `TINYSUB_DIST` to install a copy you built elsewhere if the first start takes too long.

## Installation

1. Open [http://localhost/install.php](http://localhost/install.php) and click **Start Configuration**, then **Continue**
2. On the **Insert Ampache Database** page:
    1. **MySQL Administrative Username**: admin
    2. **MySQL Administrative Password**: (see container output)
        * The logs will show a line like: `mysql -uadmin -pjnzYXLz7cMzq -h<host> -P<port>`. The password is everything after `-p`, in this case `jnzYXLz7cMzq`.
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

After installation you will need to setup a catalog. Make sure to use `/media` as the path where your media is located.

Name that catalog `music` if you want the containers to pick up file changes as they happen. The directory monitor watches `/media` and updates the catalog named `music`, so a catalog with any other name is only updated by the hourly cron job.

## Set the local_web_path

This applies if Ampache is running behind a reverse proxy. The following are typical error messages:

```text
(Ampache\Module\Api\Subsonic_Api) -> Stream error:
(Ampache\Module\Api\Subsonic_Api) -> Stream error: The requested URL returned error: 404 Not Found
```

In ampache.cfg.php set local_web_path to localhost.

There are various discussions and issues with more detail on this, see for example: [issue 1639](https://github.com/ampache/ampache/issues/1639)

If you set `local_web_path` and `force_ssl` options in your config that should work. Forcing SSL makes sure that all links are valid for your proxy

```conf
local_web_path = "http://192.168.1.1:28787" 
force_ssl = "true"
```

## Themes

By default Ampache only ships with one theme built-in located at `/var/www/public/themes/reborn`. We want to avoid mounting the whole `/themes` directory otherwise the reborn theme will not be updated when the Amapche image updates. It's best to make a copy of the existing theme and then we can mount it in the `/themes` directory as a new theme.

Make sure that the container is already running then copy the current theme to a folder on the host:

```shell
docker run -d --name=ampache ampache/ampache
docker cp ampache:/var/www/public/themes/reborn ./data/new-theme
docker container stop ampache
```

Now make modifications to the theme and then start the container again this time mounting the new theme to the container:

```shell
docker run -d --name=ampache -v ./data/new-theme:/var/www/public/themes/new-theme
```

## Thanks to

* @ericfrederich for his original work
* @velocity303 and @goldy for the other ampache-docker inspiration
* @kuzi-moto for bringing the image out of the dark ages
