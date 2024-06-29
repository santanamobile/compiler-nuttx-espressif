# Nuttx Firmware Builder for Espressif Modules

This work is based on [this](https://developer.espressif.com/blog/nuttx-getting-started/) blog post.

The main goal is deploy development tools to use nuttx to build firmware for espressif's SOCs.

## Container Specs

- Linux Distro (on Dockerfile): Ubuntu 22.04
- Toolchains: RISC-V and Xtensa

## Target Hardware

The Espressif’s SoCs supported on NuttX are divided in these two architectures:

- RISC-V: ESP32-C3, ESP32-C6, ESP32-H2
- Xtensa: ESP32, ESP32-S2, ESP32-S3

## Requirements

Before start, you must have the Docker runtime installed on your machine. You can obtain the instructions [here](https://docs.docker.com/get-docker/).

## Toolchains

This container have the toolchains to RISC-V SoCs and Xtensa.

## Credentials

The default username of the container is 'espressif', the UID and GID are the same of the container creator.

The root password is: rootpass
The espressif password is: espressif
BTW, the espressif user is in the sudoers file

## Build Container

This is the command to build the Docker image from scratch:

```bash
docker build --no-cache --build-arg "HOST_UID=$(id -u)" --build-arg "HOST_GID=$(id -g)" --rm -f "Dockerfile" -t compiler-nuttx-espressif:v1.0 .
```

The whole process takes approximately 6 minutes to complete.

Check the result image size:

```bash
$ docker image ls

REPOSITORY                 TAG       IMAGE ID       CREATED          SIZE
compiler-nuttx-espressif   v1.0      2080a0f050c0   xx seconds ago   4.79GB
```

## Run container

To build (and flash) the firmware image on the board, you must connect the board on the machine before start the container.

```bash
docker run --rm -it --privileged --device=/dev/ttyUSB0 -v "${PWD}/project:/project" compiler-nuttx-espressif:v1.0
```

## Getting NuttX Sources

```bash
cd /project
git clone https://github.com/apache/nuttx.git nuttx
git clone https://github.com/apache/nuttx-apps apps
```

## Build Example

NuttX provides ready-to-use board default configurations that enable the required config (from Kconfig) for a use scenario, in this case i'll use the example of nsh for the board franzininho-wifi.

First of all, we have to ensure that no previous config exists.

```bash
make distclean
```

```bash
./tools/configure.sh franzininho-wifi:nsh
```

Before building and flashing the firmware, it is necessary build the bootloader.

```bash
make bootloader
```

Flash firmware image with this command:

```bash
make flash ESPTOOL_PORT=/dev/ttyUSB0 ESPTOOL_BINDIR=./
```

When flashing is complete you can monitor the device serial port. In this case we will use picocom to open a serial console by running:

```bash
picocom -b115200 /dev/ttyUSB0
```

To quit picocom, first press CRTL + A followed by a regular x.

## TODO

Improve documentation

## Author

[santanamobile](https://www.github.com/santanamobile)

## License

[MIT](https://choosealicense.com/licenses/mit/)
