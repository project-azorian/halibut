FROM docker.io/debian:buster-slim

ARG PROJECT=halibut
ARG UID=42424
ARG GID=42424
ARG PIP_ARGS=""

SHELL [ "/bin/bash", "-cex" ]

RUN apt-get update ;\
    apt-get -y dist-upgrade ;\
    apt-get install -y --no-install-recommends \
            git \
            python3 \
            python3-distutils \
            python3-virtualenv \
            sudo ;\
    groupadd -g ${GID} ${PROJECT} ;\
    useradd -u ${UID} -g ${PROJECT} -M -d /var/lib/${PROJECT} -s /usr/sbin/nologin -c "${PROJECT} user" ${PROJECT} ;\
    mkdir -p /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT} ;\
    chown ${PROJECT}:${PROJECT} /etc/${PROJECT} /var/log/${PROJECT} /var/lib/${PROJECT} /var/cache/${PROJECT} ;\
    python3 -m virtualenv --python=python3 --no-setuptools /tmp/venv ;\
    source /tmp/venv/bin/activate ;\
    pip install --no-cache --upgrade ${PIP_ARGS} virtualenv ;\
    hash -r ;\
    virtualenv /var/lib/halibut ;\
    deactivate ;\
    rm /var/lib/halibut/lib/python*/no-global-site-packages.txt ;\
    source /var/lib/halibut/bin/activate ;\
    pip install --no-cache --upgrade ${PIP_ARGS} ansible ;\
    echo "${PROJECT} ALL=(ALL) NOPASSWD: /var/lib/halibut/bin/ansible --inventory /etc/halibut/inventory.ini all -m ping" > /etc/sudoers.d/${PROJECT} ;\
    echo "${PROJECT} ALL=(ALL) NOPASSWD: /var/lib/halibut/bin/ansible-playbook --inventory /etc/halibut/inventory.ini /srv/ansible/playbook.yaml" >> /etc/sudoers.d/${PROJECT} ;\
    chmod 0440 /etc/sudoers.d/${PROJECT} ;\
    apt-get purge -y --auto-remove \
            python3-virtualenv \
            virtualenv ;\
    rm -rfv \
        /var/lib/apt/lists/* \
        /tmp/* \
        /root/.cache \
        /etc/machine-id ;\
    find /usr/ /var/ \( -name "*.pyc" -o -name "__pycache__" \) -delete

COPY ./assets /tmp/assets
RUN set -ex ;\
    cp -rfav /tmp/assets/* / ;\
    rm -rf /tmp/assets ;\
    chown -R ${PROJECT}:${PROJECT} /srv/ansible

USER $PROJECT
ENV PATH=/var/lib/halibut/bin:$PATH
RUN mkdir -p /var/lib/$PROJECT/.ansible

VOLUME ["/mnt/rootfs/", "/root/.ansible", "/var/lib/$PROJECT/", "/tmp", "/var/tmp", "/usr/tmp", "/srv/ansible" ]

CMD sudo /var/lib/halibut/bin/ansible-playbook --inventory /etc/halibut/inventory.ini /srv/ansible/playbook.yaml

# Build: docker build --network=host -t docker.io/port/halibut:latest ./images/base
# Push: docker push docker.io/port/halibut:latest
# Run: docker run --rm --net=host --pid=host --ipc=host -it -v /:/mnt/rootfs:rw --read-only docker.io/port/halibut:latest
