# SPDK - Container app
This repository contains source code and infrastructure deployment resources for SPDK container app.

Todos:
- Make/Init Git repository
- Start writing document (structure first, then content)
- Take screenshots and add

# Problem statement


# Solution


# Steps:
## Pre-requisites
## Instructions
- Use Terraform to provision resources on AWS such as VPC, EC2s, EBS and setup K3s with two nodes (one master, one worker)
- For testing purposes of a simple Docker deployment, a 3rd admin node can be used:
    - Copy files inside `assignment` folder to the admin node
    - Ensure variables in `run_container.sh` script are setup correctly
    - Execute `run_container.sh` script to build and push container image to ECR repository 
    - It will also launch container and run SPDK app, check and verify logs. It should show similar output:
```sh
Mounting hugetlbfs at /mnt/huge
INFO: Requested 128 hugepages but 213 already allocated 
[2024-08-05 12:27:55.539627] Starting SPDK v24.09-pre git sha1 24813ed47 / DPDK 24.03.0 initialization...
[2024-08-05 12:27:55.540703] [ DPDK EAL parameters: nvmf --no-shconf -c 0x1 -m 128 --huge-unlink --no-telemetry --log-level=lib.eal:6 --log-level=lib.cryptodev:5 --log-level=lib.power:5 --log-level=user1:6 --iova-mode=pa --base-virtaddr=0x200000000000 --match-allocations --file-prefix=spdk_pid102 ]
[2024-08-05 12:27:55.631637] app.c: 909:spdk_app_start: *NOTICE*: Total cores available: 1
[2024-08-05 12:27:55.686384] reactor.c: 941:reactor_run: *NOTICE*: Reactor started on core 0
[2024-08-05 12:28:00.610525] tcp.c: 677:nvmf_tcp_create: *NOTICE*: *** TCP Transport Init ***
```

- For K8s deployment, master and worker nodes will be used
    - Run following on Master node to get token:
    ```sh
    sudo cat /var/lib/rancher/k3s/server/node-token
    ```
    - Run following on Worker node to attach it to cluster, ensure to replace `MASTER_SERVER_IP` and `MASTER_TOKEN`:
    ```sh
    curl -sfL https://get.k3s.io | K3S_URL=https://<MASTER_SERVER_IP>:6443 K3S_TOKEN=<MASTER_TOKEN> sh -
    ```
    - Run following command on Worker node to ensure Transparent Hugepages are enabled and Hugepages are allocated:
    ```sh
    cat /sys/kernel/mm/transparent_hugepage/enabled
    cat /proc/meminfo | grep -i huge

    # To check ECR repository connection
    cat /etc/rancher/k3s/registries.yaml
    cat /var/lib/rancher/k3s/agent/etc/containerd/config.toml
    ```
    - abc

## Dependencies
- Gossm installation on local for accessing K3s nodes
- yq package installation on Master K3s node

## Further improvements:
- Currently this deployment is done keeping in consideration that we only have one K3s node, can be modified to cater for:
    - Multiple nodes
    - Dynamic updates of resources
- Can use LB in front of master nodes


# Good things:
- Automatic Cluster NodePool registration

---

https://www.percona.com/blog/transparent-huge-pages-refresher/
Enable transparent hugepages:
- cat /sys/kernel/mm/transparent_hugepage/enabled

- Check logs for Master and Worker (less + PgUp/Down) for Hugepages installation

- Build Docker container of SPDK (install kmod as well)

Before starting container, on Host
- sudo modprobe vfio-pci
- docker run -it --rm --privileged -v /lib/modules:/lib/modules spdk-app:local-v2
Within container:
- DRIVER_OVERRIDE=vfio-pci ./scripts/setup.sh
or
- NRHUGE=512 DRIVER_OVERRIDE=vfio-pci ./scripts/setup.sh (for limited hugepage allocation)

