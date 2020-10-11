# Pre-compiled SeisComP Vanilla
## What
This directory contains a Dockerfile to generate a simple SeisComP installation. 

## How
### Dependency
The only dependency is Docker. 

On a Mac you can type in a terminal:
```
brew cask install docker
```

Or follow instructions for your computer :
https://docs.docker.com/compose/install/#install-compose

### Setup (the docker image)

To generate the docker image using the Dockerfile, run:

```
docker build -t seiscomp:latest -t  seiscomp:4.0.4 -t  seiscomp:4.0.4.debian10 .
```

### Run (the docker image into a container)
The resulting image has mount points. You can start the container as follows:

```
docker run -d --name seiscomp -p 9999:22 \
    -v ${HOME}/Applications/seiscomp/.seiscomp/:/home/sysop/.seiscomp/ \
    -v ${HOME}/Applications/seiscomp/etc/key/:/opt/seiscomp/etc/key/ \
    -v ${HOME}/Applications/seiscomp/etc/inventory/:/opt/seiscomp/etc/inventory/ \
    seiscomp:latest
```

This will also start an ssh server that you can connect to with (password the
same as the user name):

```
ssh-copy-id sysop@localhost -p 9999
ssh -p 9999 sysop@localhost
```

### Upgrade (the docker image)
First login as root
```
docker exec -u 0 -it seiscomp bash
```

and make make changes. Go to /usr/local/src/seiscomp3 and follow seiscomp doc for upgrading seiscomp.


Use the container ID (`docker ps`) and commit the change to a new image:
```
docker ps 
docker commit <CONTAINER ID>  seiscomp:<VERSION TAG>
docker images
```

Now there are 2 images available, the old and new one. 
You can delete the old image and run the new one into a new container (see above)

# Misc
By default the user `sysop` inside the container has `USER_ID=1000` and
`GROUP_ID=1000`. If this doesn't match with the permissions of the playback
files on your host machine add the following options to your `docker run`
command:
```
-e USER_ID=`id -u` -e GROUP_ID=`id -g`
```
