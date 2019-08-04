#!/usr/bin/env bash
VIRTUALENV_PATH=/home/vagrant/.virtualenv
action="$1"
shift

case "$action" in
"install")
    # This repository provides the backported libapt-pkg-dev package.
    if [ ! -f /etc/apt/sources.list.d/computology_apt-backport.list ]; then
        echo "[TASK] Installing computology/apt-backport repository..."
        wget -qO- https://packagecloud.io/install/repositories/computology/apt-backport/script.deb.sh | sudo bash
    fi
    if [ ! -x $VIRTUALENV_PATH/bin/activate ]; then
        echo "[TASK] Installing Ansible dependencies and setting up virtual environment..."
        sudo apt-get update
        sudo apt-get install -y python-pip python-dev libffi-dev libyaml-dev libssl-dev build-essential git python-virtualenv
        sudo pip install virtualenv --upgrade
        virtualenv $VIRTUALENV_PATH
    fi
    source $VIRTUALENV_PATH/bin/activate
    if [ ! -x $VIRTUALENV_PATH/bin/ansible-playbook ]; then
        echo "[TASK] Installing Ansible..."
        #pip install -U "pip<9.0.0"
        pip install ansible
    fi
    echo "[TASK] Packaging lae.travis-lxc role and installing it in guest..."
    cd /vagrant
    git archive --format tar.gz HEAD > lae.travis-lxc.tar.gz
    ansible-galaxy install lae.travis-lxc.tar.gz,$(git rev-parse HEAD),lae.travis-lxc --force
    rm lae.travis-lxc.tar.gz
    ;;
"syntax")
    source $VIRTUALENV_PATH/bin/activate
    echo "[TASK] Performing Ansible role syntax check..."
    cd /vagrant/tests/
    ansible-playbook -i inventory deploy.yml --syntax-check
    ;;
"idempotence")
    source $VIRTUALENV_PATH/bin/activate
    echo "[TASK] Performing idempotency check..."
    cd /vagrant/tests/
    ANSIBLE_STDOUT_CALLBACK=debug unbuffer ansible-playbook -vvi inventory deploy.yml > play.log ||
        (e=$?; echo "Ansible playbook failed to complete. Check tests/play.log."; exit $e)
    printf "Idempotence: "
    grep -A1 "PLAY RECAP" play.log | grep -qP "changed=0 .*failed=0 .*" &&
        (echo "PASS"; exit 0) ||
        (echo "FAIL"; echo "Check tests/play.log for more information."; exit 1)
    ;;
esac
