# ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord

A Docker Image that has the latest wordpress, nginx, phpmyadmin, supervisord and more on Ubuntu 20.04.
Based on [this](https://hub.docker.com/r/thomasvan/ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord/).

## Todo

1. If anyone has suggestions please leave a comment on [this GitHub issue](https://github.com/thomasvan/ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord/issues/1).
2. Implement [Docker Compose](https://docs.docker.com/compose/) for a quicker setup.
3. Clean up README.
4. Requests? Just make a comment on [this GitHub issue](https://github.com/thomasvan/ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord/issues/2) if there's anything you'd like added or changed.

## Installation

The easiest way get up and running this docker container is to pull the latest stable version from the [Docker Hub Registry](https://hub.docker.com/r/thomasvan/ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord/):

```bash
$ docker pull thomasvan/ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord:latest
```

If you'd like to build the image yourself:

```bash
$ git clone https://github.com/thomasvan/ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord.git
$ cd ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord
$ sudo docker build -t="thomasvan/ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord" .
```

## Usage

The -p 8080:80 maps the internal docker port 80 to the outside port 80 of the host machine. The other -p sets up sshd on port 2222.
The -p 9011:9011 is using for supervisord, listing out all services status.

```bash
$ sudo docker run -p 8080:80 -p 2222:22 -p 9011:9011 --name docker-name -d thomasvan/ubuntu20-wordpress-nginx-php7.4-phpmyadmin-supervisord:latest
```

Start your newly created container, named _docker-name_.

```bash
$ sudo docker start docker-name
```

After starting the container docker-wordpress-nginx-ssh checks to see if it has started and the port mapping is correct. This will also report the port mapping between the docker container and the host machine.

```bash
$ sudo docker ps

3306/tcp, 0.0.0.0:9011->9011/tcp, 0.0.0.0:2222->22/tcp, 0.0.0.0:8080->80/tcp
```

You can then visit the following URL in a browser on your host machine to get started:

```bash
http://127.0.0.1:8080
```

You can start/stop/restart and view the error logs of nginx and php-fpm services:

```bash
http://127.0.0.1:9011
```

You can also SSH to your container on 127.0.0.1:2222. The default password is _webuser_, and can also be found in /container-info.txt.

```bash
$ ssh -p 2222 webuser@127.0.0.1
# To drop into root
$ sudo -s
```

Now that you've got SSH access, you can setup your FTP client the same way, or the SFTP Sublime Text plugin, for easy access to files.

To get the user as well as database info, check the top of the docker container logs for it:

```bash
$ docker logs _container-name_
```
