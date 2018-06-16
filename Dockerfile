FROM grantbot/xv6
USER root

# Packages 
RUN apt-get update && \
    apt-get install -y \
        gcc-4.8-multilib 

RUN mkdir -p /home/a/MIT

WORKDIR /home/a/
