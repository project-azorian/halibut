#!/bin/bash
set -ex

add-apt-repository -y ppa:projectatomic/ppa
apt-get update
apt-get install -y cri-o-1.12
systemctl stop crio


tee /etc/crio/crio.conf <<EOF
# The CRI-O configuration file specifies all of the available configuration
# options and command-line flags for the crio(8) OCI Kubernetes Container Runtime
# daemon, but in a TOML format that can be more easily modified and versioned.
#
# Please refer to crio.conf(5) for details of all configuration options.

# CRI-O reads its storage defaults from the containers-storage.conf(5) file
# located at /etc/containers/storage.conf. Modify this storage configuration if
# you want to change the system's defaults. If you want to modify storage just
# for CRI-O, you can change the storage configuration options here.
[crio]

# Path to the "root directory". CRI-O stores all of its data, including
# containers images, in this directory.
#root = "/var/lib/containers/storage"

# Path to the "run directory". CRI-O stores all of its state in this directory.
#runroot = "/var/run/containers/storage"

# Storage driver used to manage the storage of images and containers. Please
# refer to containers-storage.conf(5) to see all available storage drivers.
#storage_driver = ""

# List to pass options to the storage driver. Please refer to
# containers-storage.conf(5) to see all available storage options.
#storage_option = [
#]

# If set to false, in-memory locking will be used instead of file-based locking.
file_locking = false

# Path to the lock file.
file_locking_path = "/run/crio.lock"


# The crio.api table contains settings for the kubelet/gRPC interface.
[crio.api]

# Path to AF_LOCAL socket on which CRI-O will listen.
listen = "/var/run/crio/crio.sock"

# IP address on which the stream server will listen.
stream_address = "127.0.0.1"

# The port on which the stream server will listen.
stream_port = "0"

# Enable encrypted TLS transport of the stream server.
stream_enable_tls = false

# Path to the x509 certificate file used to serve the encrypted stream. This
# file can change, and CRI-O will automatically pick up the changes within 5
# minutes.
stream_tls_cert = ""

# Path to the key file used to serve the encrypted stream. This file can
# change, and CRI-O will automatically pick up the changes within 5 minutes.
stream_tls_key = ""

# Path to the x509 CA(s) file used to verify and authenticate client
# communication with the encrypted stream. This file can change, and CRI-O will
# automatically pick up the changes within 5 minutes.
stream_tls_ca = ""

# The crio.runtime table contains settings pertaining to the OCI runtime used
# and options for how to set up and manage the OCI runtime.
[crio.runtime]
manage_network_ns_lifecycle = true

# A list of ulimits to be set in containers by default, specified as
# "<ulimit name>=<soft limit>:<hard limit>", for example:
# "nofile=1024:2048"
# If nothing is set here, settings will be inherited from the CRI-O daemon
#default_ulimits = [
#]

# Path to the OCI compatible runtime used for trusted container workloads. This
# is a mandatory setting as this runtime will be the default and will also be
# used for untrusted container workloads if runtime_untrusted_workload is not
# set.
#
# DEPRECATED: use Runtimes instead.
#
# runtime = "/usr/lib/cri-o-runc/sbin/runc"

# default_runtime is the _name_ of the OCI runtime to be used as the default.
# The name is matched against the runtimes map below.
default_runtime = "runc"

# Path to OCI compatible runtime used for untrusted container workloads. This
# is an optional setting, except if default_container_trust is set to
# "untrusted".
# DEPRECATED: use "crio.runtime.runtimes" instead. If provided, this
#     runtime is mapped to the runtime handler named 'untrusted'. It is
#     a configuration error to provide both the (now deprecated)
#     runtime_untrusted_workload and a handler in the Runtimes handler
#     map (below) for 'untrusted' workloads at the same time. Please
#     provide one or the other.
#     The support of this option will continue through versions 1.12 and 1.13.
#     By version 1.14, this option will no longer exist.
# runtime_untrusted_workload = "/usr/bin/kata-runtime"

# Default level of trust CRI-O puts in container workloads. It can either be
# "trusted" or "untrusted", and the default is "trusted". Containers can be run
# through different container runtimes, depending on the trust hints we receive
# from kubelet:
#
#   - If kubelet tags a container workload as untrusted, CRI-O will try first
#     to run it through the untrusted container workload runtime. If it is not
#     set, CRI-O will use the trusted runtime.
#
#   - If kubelet does not provide any information about the container workload
#     trust level, the selected runtime will depend on the default_container_trust
#     setting. If it is set to untrusted, then all containers except for the host
#     privileged ones, will be run by the runtime_untrusted_workload runtime. Host
#     privileged containers are by definition trusted and will always use the
#     trusted container runtime. If default_container_trust is set to "trusted",
#     CRI-O will use the trusted container runtime for all containers.
#
# DEPRECATED: The runtime handler should provide a key to the map of runtimes,
#     avoiding the need to rely on the level of trust of the workload to choose
#     an appropriate runtime.
#     The support of this option will continue through versions 1.12 and 1.13.
#     By version 1.14, this option will no longer exist.
#default_workload_trust = ""

# If true, the runtime will not use pivot_root, but instead use MS_MOVE.
no_pivot = false

# Path to the conmon binary, used for monitoring the OCI runtime.
conmon = "/usr/lib/crio/bin/conmon"

# Environment variable list for the conmon process, used for passing necessary
# environment variables to conmon or the runtime.
conmon_env = [ "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
]

# If true, SELinux will be used for pod separation on the host.
selinux = false

# Path to the seccomp.json profile which is used as the default seccomp profile
# for the runtime.
seccomp_profile = "/etc/crio/seccomp.json"

# Used to change the name of the default AppArmor profile of CRI-O. The default
# profile name is "crio-default-" followed by the version string of CRI-O.
apparmor_profile = "crio-default"

# Cgroup management implementation used for the runtime.
cgroup_manager = "cgroupfs"

# List of default capabilities for containers. If it is empty or commented out,
# only the capabilities defined in the containers json file by the user/kube
# will be added.
default_capabilities = [
  "CHOWN",
  "DAC_OVERRIDE",
  "FSETID",
  "FOWNER",
  "NET_RAW",
  "SETGID",
  "SETUID",
  "SETPCAP",
  "NET_BIND_SERVICE",
  "SYS_CHROOT",
  "KILL",
]

# List of default sysctls. If it is empty or commented out, only the sysctls
# defined in the container json file by the user/kube will be added.
default_sysctls = [
]

# Path to the OCI hooks directory for automatically executed hooks.
hooks_dir_path = "/usr/share/containers/oci/hooks.d"

# List of default mounts for each container. **Deprecated:** this option will
# be removed in future versions in favor of default_mounts_file.
default_mounts = [
]

# Path to the file specifying the defaults mounts for each container. The
# format of the config is /SRC:/DST, one mount per line. Notice that CRI-O reads
# its default mounts from the following two files:
#
#   1) /etc/containers/mounts.conf (i.e., default_mounts_file): This is the
#      override file, where users can either add in their own default mounts, or
#      override the default mounts shipped with the package.
#
#   2) /usr/share/containers/mounts.conf: This is the default file read for
#      mounts. If you want CRI-O to read from a different, specific mounts file,
#      you can change the default_mounts_file. Note, if this is done, CRI-O will
#      only add mounts it finds in this file.
#
#default_mounts_file = ""

# Maximum number of processes allowed in a container.
pids_limit = 1024

# Maximum sized allowed for the container log file. Negative numbers indicate
# that no size limit is imposed. If it is positive, it must be >= 8192 to
# match/exceed conmon's read buffer. The file is truncated and re-opened so the
# limit is never exceeded.
log_size_max = -1

# Path to directory in which container exit files are written to by conmon.
container_exits_dir = "/var/run/crio/exits"

# Path to directory for container attach sockets.
container_attach_socket_dir = "/var/run/crio"

# If set to true, all containers will run in read-only mode.
read_only = false

# Changes the verbosity of the logs based on the level it is set to. Options
# are fatal, panic, error, warn, info, and debug.
log_level = "error"

# The UID mappings for the user namespace of each container. A range is
# specified in the form containerUID:HostUID:Size. Multiple ranges must be
# separated by comma.
uid_mappings = ""

# The GID mappings for the user namespace of each container. A range is
# specified in the form containerGID:HostGID:Size. Multiple ranges must be
# separated by comma.
gid_mappings = ""

# The minimal amount of time in seconds to wait before issuing a timeout
# regarding the proper termination of the container.
ctr_stop_timeout = 0

# The "crio.runtime.runtimes" table defines a list of OCI compatible runtimes.
# The runtime to use is picked based on the runtime_handler provided by the CRI.
# If no runtime_handler is provided, the runtime will be picked based on the level
# of trust of the workload.

[crio.runtime.runtimes.runc]
runtime_path = "/usr/lib/cri-o-runc/sbin/runc"

[crio.runtime.runtimes.gvisor]
runtime_path = "/usr/local/bin/runsc"

[crio.runtime.runtimes.kata]
runtime_path = "/usr/bin/kata-runtime"

# The crio.image table contains settings pertaining to the management of OCI images.
#
# CRI-O reads its configured registries defaults from the system wide
# containers-registries.conf(5) located in /etc/containers/registries.conf. If
# you want to modify just CRI-O, you can change the registies configuration in
# this file. Otherwise, leave insecure_registries and registries commented out to
# use the system's defaults from /etc/containers/registries.conf.
[crio.image]

# Default transport for pulling images from a remote container storage.
default_transport = "docker://"

# The image used to instantiate infra containers.
pause_image = "k8s.gcr.io/pause:3.1"

# The command to run to have a container stay in the paused state.
pause_command = "/pause"

# Path to the file which decides what sort of policy we use when deciding
# whether or not to trust an image that we've pulled. It is not recommended that
# this option be used, as the default behavior of using the system-wide default
# policy (i.e., /etc/containers/policy.json) is most often preferred. Please
# refer to containers-policy.json(5) for more details.
signature_policy = ""

# Controls how image volumes are handled. The valid values are mkdir, bind and
# ignore; the latter will ignore volumes entirely.
image_volumes = "mkdir"

# List of registries to be used when pulling an unqualified image (e.g.,
# "alpine:latest"). By default, registries is set to "docker.io" for
# compatibility reasons. Depending on your workload and usecase you may add more
# registries (e.g., "quay.io", "registry.fedoraproject.org",
# "registry.opensuse.org", etc.).
registries = [
  "docker.io",
 ]


# The crio.network table containers settings pertaining to the management of
# CNI plugins.
[crio.network]

# Path to the directory where CNI configuration files are located.
network_dir = "/etc/cni/net.d/"

# Path to directory where CNI plugin binaries are located.
plugin_dir = "/opt/cni/bin"
EOF

tee /etc/systemd/system/crio.service <<EOF
[Unit]
Description=Open Container Initiative Daemon
Documentation=https://github.com/kubernetes-sigs/cri-o
After=network-online.target

[Service]
Type=notify
EnvironmentFile=-/etc/sysconfig/crio-storage
EnvironmentFile=-/etc/sysconfig/crio-network
Environment=GOTRACEBACK=crash
ExecStart=/usr/bin/crio \
  \$CRIO_STORAGE_OPTIONS \
  \$CRIO_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
TasksMax=infinity
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
OOMScoreAdjust=-999
TimeoutStartSec=0
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable crio
systemctl restart crio
crictl info
crictl images
crictl ps
crictl pods
