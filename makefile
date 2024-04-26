#!/usr/bin/env make

# © Dmitry Detkov 2024
# Изделие №4 - k3s
# File: makefile

.POSIX:

export GIT_REPO=https://github.com/ddetkov/k3s.git

.PHONY: *

include .env

all: k3s

# k3s
k3s: k3s.reset k3s.up
## up
k3s.up: k3s.distr k3s.setup k3s.init k3s.info
### setup TODO разбить сетап на инсталл и кинфиг, в конфиге скачивать все образы для зависимостей(свой реджестри при инстале)
k3s.distr:
	@ssh ${USER}@${ENTRYPOINT} "sudo mkdir -p /var/opt/rancher"
	@ssh ${USER}@${ENTRYPOINT} "sudo curl --connect-timeout 10 --retry 5 --retry-delay 3 -L -o /var/opt/rancher/k3s-airgap-images-arm64.tar.zst 'https://github.com/k3s-io/k3s/releases/download/v1.29.3%2Bk3s1/k3s-airgap-images-arm64.tar.zst'"
	@ssh ${USER}@${ENTRYPOINT} "sudo docker image load -i /var/opt/rancher/k3s-airgap-images-arm64.tar.zst"
	@ssh ${USER}@${ENTRYPOINT} "sudo curl --connect-timeout 10 --retry 5 --retry-delay 3 -L -o /var/opt/rancher/k3s 'https://github.com/k3s-io/k3s/releases/download/v1.29.3%2Bk3s1/k3s-arm64'"
	@ssh ${USER}@${ENTRYPOINT} "sudo curl --connect-timeout 10 --retry 5 --retry-delay 3 -L -o /var/opt/rancher/install.sh 'https://get.k3s.io'"

k3s.setup:
	@ssh ${USER}@${ENTRYPOINT} "sudo mkdir -p /var/lib/rancher/k3s/agent/images"
	@ssh ${USER}@${ENTRYPOINT} "sudo curl --connect-timeout 10 --retry 5 --retry-delay 3 -L -o /var/lib/rancher/k3s/agent/images/k3s-airgap-images-arm64.tar.zst 'https://github.com/k3s-io/k3s/releases/download/v1.29.3%2Bk3s1/k3s-airgap-images-arm64.tar.zst'"
	@ssh ${USER}@${ENTRYPOINT} "sudo docker image load -i /var/lib/rancher/k3s/agent/images/k3s-airgap-images-arm64.tar.zst"
	@ssh ${USER}@${ENTRYPOINT} "sudo curl --connect-timeout 10 --retry 5 --retry-delay 3 -L -o /var/lib/rancher/k3s/k3s 'https://github.com/k3s-io/k3s/releases/download/v1.29.3%2Bk3s1/k3s-arm64'"
	@ssh ${USER}@${ENTRYPOINT} "sudo curl --connect-timeout 10 --retry 5 --retry-delay 3 -L -o /var/lib/rancher/k3s/install.sh 'https://get.k3s.io'"
	@ssh ${USER}@${ENTRYPOINT} "sudo curl --connect-timeout 10 --retry 5 --retry-delay 3 -L -o /var/lib/rancher/get_helm.sh 'https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3'"
	@ssh ${USER}@${ENTRYPOINT} "sudo curl --connect-timeout 10 --retry 5 --retry-delay 3 -L -o /var/lib/rancher/kompose-linux-arm64 'https://github.com/kubernetes/kompose/releases/download/v1.26.0/kompose-linux-arm64'"
	@ssh ${USER}@${ENTRYPOINT} "sudo chmod +x /var/lib/rancher/k3s/k3s /var/lib/rancher/k3s/install.sh /var/lib/rancher/get_helm.sh /var/lib/rancher/kompose-linux-arm64"
	@ssh ${USER}@${ENTRYPOINT} "sudo ln -s /var/lib/rancher/k3s/k3s /usr/local/bin/k3s"
### init
k3s.init:
	@ssh ${USER}@${ENTRYPOINT} "sudo INSTALL_K3S_CHANNEL=stable INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_EXEC='server --cluster-cidr=172.30.0.0/16 --service-cidr=172.40.0.0/16 --data-dir=/data/k3s --disable=traefik --kubelet-arg container-log-max-files=3 --kubelet-arg container-log-max-size=10Mi' /var/lib/rancher/k3s/install.sh"
	@ssh ${USER}@${ENTRYPOINT} "sudo chmod 644 /etc/rancher/k3s/k3s.yaml"
	@ssh ${USER}@${ENTRYPOINT} "sudo mkdir -p /root/.kube && sudo cp /etc/rancher/k3s/k3s.yaml /root/.kube/config"
	@ssh ${USER}@${ENTRYPOINT} "sudo mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config"
	@ssh ${USER}@${ENTRYPOINT} "sudo /var/lib/rancher/get_helm.sh"
### info
k3s.info:
	@ssh ${USER}@${ENTRYPOINT} "sudo kubectl get node"
## reset
k3s.reset: k3s.uninstall k3s.reboot k3s.ping k3s.cleanup
### uninstall
k3s.uninstall:
	@ssh ${USER}@${ENTRYPOINT} "sudo /usr/local/bin/k3s-uninstall.sh" || true
	@ssh ${USER}@${ENTRYPOINT} "sudo rm -rf /etc/rancher /var/lib/rancher /usr/local/bin/k3s /data/k3s /root/.kube ~/.kube" || true
### reboot
k3s.reboot:
	@ssh ${USER}@${ENTRYPOINT} "sudo bash -c 'sleep 1; reboot'&"
### ping
k3s.ping:
	@ping -c 90 ${ENTRYPOINT}
### cleanup
k3s.cleanup:
	@ssh ${USER}@${ENTRYPOINT} "sudo docker system prune --all --volumes --force"
