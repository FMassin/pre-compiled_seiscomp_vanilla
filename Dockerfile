FROM debian:buster-slim 

MAINTAINER Fred Massin  <fmassin@sed.ethz.ch>

ENV WORK_DIR /usr/local/src/
ENV INSTALL_DIR /opt/seiscomp

# Fix Debian  env
ENV DEBIAN_FRONTEND noninteractive
ENV INITRD No
ENV FAKE_CHROOT 1

# Setup sysop's user and group id
ENV USER_ID 1000
ENV GROUP_ID 1000

WORKDIR $WORK_DIR

RUN echo 'force-unsafe-io' | tee /etc/dpkg/dpkg.cfg.d/02apt-speedup \
    && echo 'DPkg::Post-Invoke {"/bin/rm -f /var/cache/apt/archives/*.deb || true";};' | tee /etc/apt/apt.conf.d/no-cache \
    && apt-get update \
    && apt-get dist-upgrade -y --no-install-recommends 

RUN apt-get install -y \
    wget 

RUN cd $INSTALL_DIR/../ \
    && wget https://www.seiscomp.de/downloader/seiscomp-4.0.4-debian10-x86_64.tar.gz \
    && wget https://www.seiscomp.de/downloader/seiscomp-maps.tar.gz \
    && wget https://www.seiscomp.de/downloader/seiscomp-4.0.4-doc.tar.gz \
    && find . -type f -iname "seiscomp*.tar.gz" -print0 -execdir tar xvf {} \; -delete 

RUN apt-get install -y \
    mariadb-client \
    postgresql-client \
    libqt4-dev \
    python-numpy \
    libqt4-dev \
    qtbase5-dev \
    libpq-dev \
    ncurses-dev \
    openssh-server \
    openssl \
    libssl-dev \
    net-tools \
    cron \
    libfaketime

# Install seiscomp
RUN cd $INSTALL_DIR/share/deps/debian/10/ \
    && cat install-base.sh install-gui.sh install-fdsnws.sh|sed 's/apt/apt-get/'|sed 's/install/install -y/'|bash

# Cleanup
RUN apt-get autoremove -y --purge \
    && apt-get clean 

# Setup ssh access
RUN mkdir /var/run/sshd
RUN echo 'root:password' | chpasswd
RUN echo X11Forwarding yes >> /etc/ssh/sshd_config
RUN echo X11UseLocalhost no  >> /etc/ssh/sshd_config
RUN echo AllowAgentForwarding yes >> /etc/ssh/sshd_config
RUN echo PermitRootLogin yes >> /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN groupadd --gid $GROUP_ID -r sysop && useradd -m -s /bin/bash --uid $USER_ID -r -g sysop sysop \
    && echo 'sysop:sysop' | chpasswd \
    && chown -R sysop:sysop $INSTALL_DIR

RUN mkdir -p /home/sysop/.seiscomp \
    && chown -R sysop:sysop /home/sysop

USER sysop

### SeisComp3 settings ###
# Configure
RUN $INSTALL_DIR/bin/seiscomp print env >> /home/sysop/.profile
RUN $INSTALL_DIR/bin/seiscomp print crontab|crontab - 
RUN echo 'date' >> /home/sysop/.profile
RUN echo 'echo \$SEISCOMP_ROOT is $SEISCOMP_ROOT' >> /home/sysop/.profile
RUN echo 'seiscomp status |grep "is running"' >> /home/sysop/.profile
RUN echo 'seiscomp status |grep "WARNING"' >> /home/sysop/.profile


# machinery for next
#ENV SEISCOMP_ROOT=/opt/seiscomp3 PATH=/opt/seiscomp3/bin:$PATH \
#     LD_LIBRARY_PATH=/opt/seiscomp3/lib:$LD_LIBRARY_PATH \
#     PYTHONPATH=/opt/seiscomp3/lib/python:$PYTHONPATH \
#     MANPATH=/opt/seiscomp3/share/man:$MANPATH \
#     LC_ALL=C

# Copy default config
#ADD volumes/SYSTEMCONFIGDIR/ $INSTALL_DIR/etc/

# Backup
#RUN mkdir -p  /home/sysop/SYSTEMCONFIGDIR \
#    && cp -r $INSTALL_DIR/etc/defaults /home/sysop/SYSTEMCONFIGDIR/defaults \
#    && cp -r $INSTALL_DIR/etc/descriptions /home/sysop/SYSTEMCONFIGDIR/descriptions \
#    && cp -r $INSTALL_DIR/etc/init /home/sysop/SYSTEMCONFIGDIR/init \
#    && cp -r $INSTALL_DIR/etc/inventory /home/sysop/SYSTEMCONFIGDIR/inventory 

# # Setup aliases
# RUN seiscomp alias create scolvnica scolv \
#     && seiscomp alias create scolvcalt scolv \
#     && seiscomp alias create scolvepos scolv \
#     && seiscomp alias create scolvch scolv \
#     && seiscomp alias create scolvchd scolv \
#     && seiscomp alias create scolvautni scolv 

# # Setup SeisComP3 + seedlink
# RUN seiscomp --stdin setup \<sc3_config.cfg \
#     && mkdir -p /opt/seiscomp3/var/lib/seedlink \
#     && cp seedlink.ini /opt/seiscomp3/var/lib/seedlink/ \
#     && mkdir -p /opt/seiscomp3/var/run/seedlink \
#     && mkfifo  -m=666 /opt/seiscomp3/var/run/seedlink/mseedfifo 

## Setup pipelines
# RUN seiscomp alias create NLoB_amp scamp \
#     && seiscomp alias create NLoB_apick scautopick \
#     && seiscomp alias create NLoB_auloc scautoloc \
#     && seiscomp alias create NLoB_mag scmag \
#     && seiscomp alias create NTeT_amp scamp \
#     && seiscomp alias create NTeT_apick scautopick \
#     && seiscomp alias create NTeT_auloc scautoloc \
#     && seiscomp alias create NTeT_mag scmag \
#     && seiscomp enable scevent scautopick scautoloc scmag scamp seedlink NLoB_amp \
#     NLoB_apick NLoB_auloc NLoB_mag NTeT_amp NTeT_apick NTeT_auloc NTeT_mag
 

#WORKDIR /home/sysop

VOLUME [$INSTALL_DIR"/etc/key"]
VOLUME [$INSTALL_DIR"/etc/inventory"]
VOLUME ["/home/sysop/.seiscomp3"]
#VOLUME ["/home/sysop/userdata"]

USER root
    
EXPOSE 22

# Start sshd
CMD ["/usr/sbin/sshd", "-D"]
