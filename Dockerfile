#
# Last Updete: 2018/12/19
#
# Author: Yoshihiko Hara
#
# Overview:
#   Create a container with "micro mruby for arduino uno" installed.
#

# Specify the image (Ubuntu 18.04) to be the base of the container.
From ubuntu:18.04

# Specify working directory (/root).
WORKDIR /root

# Update applications and others.
RUN apt-get -y update
RUN apt-get -y upgrade

# Install network tools (ip, ping, ifconfig).
RUN apt-get -y install iproute2 iputils-ping net-tools

# Install working tools (vim, wget, curl, git, unzip).
RUN apt-get -y install apt-utils
RUN apt-get -y install software-properties-common
RUN apt-get -y install vim wget curl git
RUN apt-get -y install unzip

# Set the root user's password (pw = root).
RUN echo 'root:root' | chpasswd

# Install sshd.
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y install openssh-server
RUN mkdir /var/run/sshd

# Change the setting so that the root user can SSH login.
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

# Install build tools(g++、make、bison)
RUN apt-get -y install g++ make bison

# Install the library necessary for building CRuby.
RUN apt-get -y install zlib1g-dev libssl-dev libreadline-dev
RUN apt-get -y install libyaml-dev libxml2-dev libxslt-dev
RUN apt-get -y install openssl libssl-dev libbz2-dev libreadline-dev

# Install CRuby(Ruby 2.5.3).
# CRuby and bison are necessary when building mruby.
RUN wget https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.3.tar.gz
RUN tar xvzf ruby-2.5.3.tar.gz
WORKDIR /root/ruby-2.5.3
RUN ./configure
RUN make
RUN make install
WORKDIR /root

# Install mruby(mruby 1.3).
RUN wget https://github.com/mruby/mruby/archive/1.3.0.zip
RUN unzip 1.3.0.zip
WORKDIR /root/mruby-1.3.0
RUN ruby ./minirake
WORKDIR /root
ENV PATH $PATH:/root/mruby-1.3.0/bin
RUN echo "export PATH=$PATH:/root/mruby-1.3.0/bin" >> .bash_profile

# Install Python(Python 2.7).
# It is necessary to use "pip" to get the source of "micro mruby for arduino uno".
# And Build Tool(platformio) depends on python 2.7.
RUN apt-get -y install python2.7 python-pip python-setuptools python2.7-dev

# Get "PlatformIO Core"
# Install "PlatformIO Core" to build applications using "micro mruby for arduino uno".
RUN pip install platformio
RUN pip install --egg scons

# Get "micro mruby for arduino uno"
RUN git clone https://github.com/kishima/micro_mruby_for_arduino_uno.git

# Register "micro mruby for arduino uno" as a library of "PlatformIO Core".
WORKDIR /root
RUN mkdir -p ./.platformio/lib
RUN cp -rf ./micro_mruby_for_arduino_uno  ./.platformio/lib

# Build TransCoder
WORKDIR /root/.platformio/lib/micro_mruby_for_arduino_uno/tool
RUN make
WORKDIR /root
ENV PATH $PATH:/root/.platformio/lib/micro_mruby_for_arduino_uno/tool
RUN echo "export PATH=$PATH:/root/.platformio/lib/micro_mruby_for_arduino_uno/tool" >> .bash_profile

# Make example project
RUN mkdir /root/examples
WORKDIR /root/examples
RUN platformio init --board uno
WORKDIR /root/examples/src
RUN echo "#include \"mmruby_arduino.h\"" > main.cpp
RUN echo "void setup()" >> main.cpp
RUN echo "{" >> main.cpp
RUN echo "  mmruby_setup();" >> main.cpp
RUN echo "  mmruby_run();" >> main.cpp
RUN echo "}" >> main.cpp
RUN echo "void loop(){}" >> main.cpp

# Make example ruby script
RUN mkdir /root/examples/ruby
WORKDIR /root/examples/ruby
RUN echo 'puts "hello world"' > test-001.rb
WORKDIR /root

# Specify the locale.
RUN apt-get install -y locales
RUN echo "ja_JP UTF-8" > /etc/locale.gen
RUN locale-gen
