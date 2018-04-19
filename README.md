[![Build Status](https://travis-ci.org/lae/ansible-role-travis-lxc.svg?branch=master)](https://travis-ci.org/lae/ansible-role-travis-lxc)
[![Galaxy Role](https://img.shields.io/badge/ansible--galaxy-travis--lxc-blue.svg)](https://galaxy.ansible.com/lae/travis-lxc/)

lae.travis-lxc
=========

Configures and starts N LXC containers to use in the Travis CI environment for
simpler testing of Ansible roles across different distributions.


Role Variables
--------------
By default, the environment variables `LXC_DISTRO` and `LXC_RELEASE` are used
for selecting which LXC container template to test from. If not specified, this
role defaults to the Debian Stretch template.

    template: "{{ lookup('env', 'LXC_DISTRO') | default('debian', true) }}"
    release: "{{ lookup('env', 'LXC_RELEASE') | default('stretch', true) }}"

To give an example, a full test suite (in your `.travis.yml`) against all valid
distros and different Ansible versions would possibly look like this:

```
env:
  # Since the default is Stretch, no need to specify LXC_RELEASE/LXC_DISTRO
  - ANSIBLE_VERSION='git+https://github.com/ansible/ansible.git@devel' # 2.6 DEVEL
  - ANSIBLE_VERSION='ansible>=2.5.0,<2.6.0' # 2.5.x
  - ANSIBLE_VERSION='ansible>=2.4.0,<2.5.0' # 2.4.x
  - ANSIBLE_VERSION='ansible>=2.3.0,<2.4.0' # 2.3.x
  - LXC_DISTRO=debian LXC_RELEASE=jessie
  - LXC_DISTRO=debian LXC_RELEASE=wheezy
  - LXC_DISTRO=ubuntu LXC_RELEASE=xenial
  - LXC_DISTRO=ubuntu LXC_RELEASE=trusty
  - LXC_DISTRO=ubuntu LXC_RELEASE=precise
  - LXC_DISTRO=centos LXC_RELEASE=7
  - LXC_DISTRO=centos LXC_RELEASE=6
  - LXC_DISTRO=fedora LXC_RELEASE=27
  - LXC_DISTRO=fedora LXC_RELEASE=26
  - LXC_DISTRO=fedora LXC_RELEASE=25
install:
- if [ "$ANSIBLE_VERSION" ]; then pip install $ANSIBLE_VERSION; else pip install ansible; fi
- printf '[defaults]\nroles_path=../\ncallback_whitelist=profile_tasks' >ansible.cfg
- ansible-galaxy install lae.travis-lxc azavea.pip
- ansible-playbook -vvv tests/install.yml -i tests/inventory
```

Test containers are given hostnames of the format `{{ host_prefix }}##.lxc`
(where `##` is a zero-padded integer starting from `1`). `host_prefix`'s default
is `test` - e.g. hostnames would become `test01.lxc`, `test02.lxc` and so forth.

To create more than 1 test container, increase `host_quantity`.

You can also override the container configuration used, if necessary (for e.g.
mounting a shared folder):

    container_config:
      - "lxc.aa_profile=unconfined"
      - "lxc.mount.auto=proc:rw sys:rw cgroup-full:rw"
      - "lxc.cgroup.devices.allow=a *:* rmw"

On the off-chance you need to ("missing" packages should be installed by default
within this role, so open an issue), you can install extra packages inside the
test containers as well:

    additional_packages:
      - make

Example Playbook
----------------

See `example.yml`, as well as `.travis.yml`. Some more concrete documentation
will be written later.

Contributors
------------

Musee Ullah <lae@lae.is> (author and maintainer)  
Wilmar den Ouden <@wilmardo>
