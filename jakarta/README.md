# Pre-compiled SeisComP3 Vanilla
## What
This directory contains a Dockerfile to generate a simple SeisComP3 installation. 

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
docker build -t seiscomp3:latest -t  seiscomp3:jakarta -t  seiscomp3:jakarta.debian10 .
```

### Run (the docker image into a container)
The resulting image has mount points. You can start the container as follows:

```
docker run -d --name seiscomp3 -p 9999:22 \
    -v     ${HOME}/Applications/seiscomp3/.seiscomp/:/home/sysop/.seiscomp3/ \
    -v       ${HOME}/Applications/seiscomp3/etc/key/:/opt/seiscomp3/etc/key/ \
    -v ${HOME}/Applications/seiscomp3/etc/inventory/:/opt/seiscomp3/etc/inventory/ \
    seiscomp3:latest
```
