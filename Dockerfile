FROM grantbot/xv6
USER root

# Packages 
RUN apt-get update && \
    apt-get install -y \
    gcc-4.8-multilib \
    language-pack-zh-hans

RUN mkdir -p /home/a/MIT
#RUN echo "export LC_ALL='zh_CN.UTF-8'" >> /etc/bash.bashrc
#RUN source /etc/bash.bashrc
COPY ./MIT/* /home/a/MIT/

WORKDIR /home/a/
