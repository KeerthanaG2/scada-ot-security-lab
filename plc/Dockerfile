FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y git sudo iptables tcpdump iproute2 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 https://github.com/thiagoralves/OpenPLC_v3.git /OpenPLC_v3
WORKDIR /OpenPLC_v3
RUN ./install.sh docker
EXPOSE 8080 502
CMD ["./start_openplc.sh"]
