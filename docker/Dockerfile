FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install git kmod -y && \
    git clone https://github.com/spdk/spdk.git /spdk

WORKDIR /spdk

# Install dependencies and Build SPDK
RUN git submodule update --init && \
    ./scripts/pkgdep.sh && \
    ./configure && make

# Copy the entrypoint script to the container and make it executable
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

# Set the entrypoint to run the SPDK app
ENTRYPOINT ["./entrypoint.sh"]
CMD ["64", "vfio-pci", "64MB"]