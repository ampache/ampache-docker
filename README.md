# ampache-docker

Docker image for Ampache, a web based audio/video streaming application and file manager allowing you to access your music & videos from anywhere, using almost any internet enabled device.

## NEWS

Debian has released a new stable version and containers are updated to match.

* Trixie uses PHP 8.4 and MariaDB has been updated to the latest LTS version.
* The UID and GID of mysql has changed and this [commit](https://github.com/ampache/ampache-docker/commit/1020db4855d641b938560b90c513aa667c6f5df2) checks that your ID's match the container ID's.
* The included `php.ini` file has been updated so you may need to update yours depending on your changes.

For the Debian upgrade to Bookworm MariaDB upgrades caused one issue.

Have a look at [comment](https://github.com/ampache/ampache-docker/issues/102#issuecomment-1640956439) for information about how it was solved when there was an error during the upgrade.

## How to use this image

This section covers two methods for running Ampache, first with the `docker run` command, and then using `docker-compose`.

### docker run

To run the current Ampache master (stable) branch:

```bash
docker run --name=ampache -d -v /path/to/your/music:/media:ro -p 80:80 ampache/ampache
```

### docker-compose

This method is recommended as it creates persistent volumes for important data and makes restarting the container much easier.

If you're already using Docker Desktop for Windows or Mac then Docker Compose is included. If you are using a different version or on Linux, follow these instructions in the docker docs: [Install Docker Compose](https://docs.docker.com/compose/install/)

In the [GitHub repository](https://github.com/ampache/ampache-docker/blob/master/docker-compose.yml) is a simple `docker-compose.yml` file to get started. Download the file and run this command to start an Ampache container:

```bash
docker-compose up -d
```

This automatically creates the following bind mounts:

* `./data/media` mounted at `/media` for music
* `./data/mysql` mounted at `/var/lib/mysql` for persistent MySQL storage
* `./data/config` mounted at `/var/www/config` for persistent Ampache configuration
* `./data/log` mounted at `/var/log/ampache` for debug logs

### Environment variables

You can configure parts of the container using environment variables. When running with `docker run`, you can set an environment variable using the `-e` parameter; for example, `-e FOO=BAR` sets the environemnt variable `FOO` to bar. When using `docker-compose`, you can set environment variables using a `.env` file in this directory.

Available environment variables are:

* `DISABLE_INOTIFYWAIT_CLEAN`: If set to 1, disables the clean step on the directory monitor. This prevents Ampache from automatically cleaning files. If you are using a bind mount on an external storage, this may be desirable as it prevents Ampache from removing files if the external storage goes down.
* `LOG_FILE`: Full file path to ampache log file inside the container. (Default: /var/log/ampache/ampache.log) When available it will print log file data to the docker logs command. (e.g. `docker logs ampache`)

### Enable debug logging

The Ampache containers do no log anything by default.

You can Enable logging using the docker exec commands to sed your config file. These commands will update your config file to enable logging.

```
docker exec -it ampache sed -i "s/log_filename = \"%name.%Y%m%d.log\"/log_filename = \"ampache.log\"/g" /var/www/config/ampache.cfg.php
docker exec -it ampache sed -i "s/;debug = \"true\"/debug = \"true\"/g" /var/www/config/ampache.cfg.php
```

When enabled make sure there are no visual or permission issues showing up in the container. If you get a permission error you can set the log folder permissions with these commands.

```
docker exec -it ampache chown www:data:www-data /var/log/ampache
docker exec -it ampache chmod 754 /var/log/ampache
```

Restart the container and logs will start flowing in!

```
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

```bash
chown 33:33 ./data/config -R
chown 33:33 ./data/log
```

Optionally, the media directory should be writable as if you wish to allow uploads.

```bash
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

~~The develop tag is set up to use git updates so you don't have to rebuild your images to stay up to date with development.~~

### `ampache:nosql`

For advanced users, this provides an image without a MySQL server built-in. You must provide your own MySQL server.

### `ampache:nosql<version>`

The `nosql` image pinned to a specific version.

e.g. `ampache:nosql7`, `ampache:nosql7.7.2`

## Running on ARM

The automated builds for the official repo are now built for linux/amd64, linux/arm/v7 and linux/arm64.

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

## Set the local_web_path

This applies if Ampache is running behind a reverse proxy. The following are typical error messages:

(Ampache\Module\Api\Subsonic_Api) -> Stream error: 
(Ampache\Module\Api\Subsonic_Api) -> Stream error: The requested URL returned error: 404 Not Found

In ampache.cfg.php set local_web_path to localhost. There are various discussions and issues with more detail on this, see for example: https://github.com/ampache/ampache/issues/1639

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

