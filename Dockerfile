# License-Identifier: (MIT)
FROM ubuntu:22.04

# LABEL about the custom image
LABEL maintainer="SystemsBR"
LABEL version="1.0"
LABEL description="Getting Started with NuttX and ESP32"

ARG DEBIAN_FRONTEND=noninteractive

# Install packages
RUN \
    apt-get update && apt-get -y install --no-install-recommends \
    sudo tzdata locales wget unzip rsync bc ca-certificates openssl \
    automake binutils-dev bison build-essential flex g++-multilib gcc-multilib \
    genromfs gettext git gperf kconfig-frontends libelf-dev libexpat-dev \
    libgmp-dev libisl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev xxd \
    libtool picocom pkg-config python3-pip texinfo u-boot-tools util-linux \
    curl cmake \
    && apt-get clean

RUN \
    pip3 install kconfiglib esptool==4.8.dev4

# Configure Timezone
ENV TZ=Etc/UTC
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN \
    ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    echo "Etc/UTC" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    locale-gen en_US.UTF-8

# User setup
ENV USER=espressif
ENV HOME=/home/${USER}
ENV WORK=/project

ARG HOST_UID=1000
ARG HOST_GID=1000

RUN \
    groupadd -g ${HOST_GID} ${USER} && \
    useradd -g ${HOST_GID} -m -s /bin/bash -u ${HOST_UID} ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

RUN usermod -aG sudo ${USER} 
RUN usermod -aG dialout ${USER}
RUN usermod -aG plugdev ${USER}

# Setup passwords
RUN echo "root:rootpass" > /root/passwdfile
RUN echo "${USER}:espressif" >> /root/passwdfile
RUN chpasswd -c SHA512 < /root/passwdfile && \
    rm /root/passwdfile

# Toolchain download for RISC-V SoCs (ESP32-C3, ESP32-C6, ESP32-H2)
# All RISC-V SoCs use the same toolchain. Currently (Jun 2024), NuttX uses the xPack’s prebuilt toolchain based on GCC 13.2.0-2 for RISC-V devices.
ADD https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz .

# Toolchain download/setup for Xtensa SoCs (ESP32, ESP32-S2, ESP32-S3)
# Each Xtensa-based device has its own toolchain, which needs to be downloaded and configured separately
ADD https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/xtensa-esp32-elf-12.2.0_20230208-x86_64-linux-gnu.tar.xz .
ADD https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/xtensa-esp32s2-elf-12.2.0_20230208-x86_64-linux-gnu.tar.xz .
ADD https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/xtensa-esp32s3-elf-12.2.0_20230208-x86_64-linux-gnu.tar.xz .

RUN tar -xf xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz -C /opt
RUN tar -xf xtensa-esp32-elf-12.2.0_20230208-x86_64-linux-gnu.tar.xz -C /opt
RUN tar -xf xtensa-esp32s2-elf-12.2.0_20230208-x86_64-linux-gnu.tar.xz -C /opt
RUN tar -xf xtensa-esp32s3-elf-12.2.0_20230208-x86_64-linux-gnu.tar.xz -C /opt

RUN rm xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz
RUN rm xtensa-esp32-elf-12.2.0_20230208-x86_64-linux-gnu.tar.xz
RUN rm xtensa-esp32s2-elf-12.2.0_20230208-x86_64-linux-gnu.tar.xz
RUN rm xtensa-esp32s3-elf-12.2.0_20230208-x86_64-linux-gnu.tar.xz

USER ${USER}

# Configure basic .gitconfig
RUN \
    git config --global color.ui false && \
    git config --global http.sslverify false

# Setup PATH
RUN echo "export PATH=$PATH:/opt/xpack-riscv-none-elf-gcc-13.2.0-2/bin:/opt/xtensa-esp32-elf/bin:/opt/xtensa-esp32s2-elf/bin:/opt/xtensa-esp32s3-elf/bin" >> ${HOME}/.bashrc

WORKDIR ${WORK}

# Copy script to download nuttx sources
COPY get-nuttx.sh .
RUN sudo chmod 0755 get-nuttx.sh

ENTRYPOINT ["/bin/bash"]
