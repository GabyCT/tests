#!/bin/bash
#
# Copyright (c) 2017 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export KUBECONFIG=/etc/kubernetes/admin.conf
sudo -E kubeadm reset --cri-socket=/var/run/crio/crio.sock
sudo systemctl stop kubelet
sudo systemctl stop docker
for ctr in $(sudo crictl ps --quiet); do
	sudo crictl stop "$ctr"
	sudo crictl rm "$ctr"
done
for pod in $(sudo crictl sandboxes --quiet); do
	sudo crictl stops "$pod"
	sudo crictl rms "$pod"
done

sudo systemctl stop crio
sudo rm -rf /var/lib/cni/*
sudo rm -rf /var/run/crio/*
sudo rm -rf /var/log/crio/*
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /run/flannel/*
sudo rm -rf /etc/cni/net.d/*

sudo umount /tmp/hyper/shared/pods/*/*/rootfs \
			/tmp/tmp*/crio/overlay2/*/merged \
			/tmp/hyper/shared/pods/*/*/rootfs \
			/run/netns/cni-* \
			/tmp/tmp*/crio-run/overlay2-containers/*/userdata/shm \
			/tmp/tmp*/crio/overlay2 \
			/tmp/hyper/shared/pods/*/*-resolv.conf \
			/var/lib/containers/storage/overlay2

sudo rm -rf /var/lib/virtcontainers/pods/*
sudo rm -rf /var/run/virtcontainers/pods/*
sudo rm -rf /var/lib/containers/storage/*
sudo rm -rf /var/run/containers/storage/*

sudo ip link set dev cni0 down
sudo ip link set dev cbr0 down
sudo ip link set dev flannel.1 down
sudo ip link set dev docker0 down
sudo ip link del cni0
sudo ip link del cbr0
sudo ip link del flannel.1
sudo ip link del docker0

sudo systemctl start docker
sudo systemctl start crio
sudo systemctl restart cc-proxy
