FROM ubuntu:disco

# needed to install tzdata in disco
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
  build-essential pkg-config qt5-default qttools5-dev-tools qttranslations5-l10n \
  libqt5svg5-dev libboost-dev libssl-dev libprotobuf-dev protobuf-compiler \
  libcap-dev libxi-dev \
  libasound2-dev libpulse-dev \
  libogg-dev libsndfile1-dev libspeechd-dev \
  libavahi-compat-libdnssd-dev libzeroc-ice-dev libg15daemon-client-dev

RUN mkdir /root/mumble
ADD https://github.com/mumble-voip/mumble/archive/master.tar.gz /root/mumble/
RUN ls /root/mumble
RUN tar xvfz /root/mumble/master.tar.gz -C /root/mumble/
WORKDIR /root/mumble/mumble-master
RUN ls

RUN qmake -recursive main.pro CONFIG+="no-client grpc"
RUN make release

FROM bitnami/minideb:latest

RUN groupadd -g 1001 -r murmur && useradd -u 1001 -r -g murmur murmur
RUN install_packages \
  libcap2 \
  libzeroc-ice3.7 \
  libprotobuf17 \
  libgrpc6 \
  libgrpc++1 \
  libavahi-compat-libdnssd1 \
  libqt5core5a \
  libqt5network5 \
  libqt5sql5 \
  libqt5xml5 \
  libqt5dbus5 \
  libqt5sql5-psql

COPY --from=0 /root/mumble/mumble-master/release/murmurd /usr/bin/murmurd
COPY --from=0 /root/mumble/mumble-master/scripts/murmur.ini /etc/murmur/murmur.ini

# Forward apporpriate ports
EXPOSE 64738/tcp 64738/udp

USER murmur

# Run murmur
ENTRYPOINT ["/opt/murmur/murmur.x86", "-fg", "-v"]
CMD ["-ini", "/etc/murmur.ini"]
