[![Build Status](https://travis-ci.org/lae/ansible-role-travis-lxc.svg?branch=master)](https://travis-ci.org/lae/ansible-role-travis-lxc)
[![Galaxy Role](https://img.shields.io/badge/ansible--galaxy-travis--lxc-blue.svg)](https://galaxy.ansible.com/lae/travis-lxc/)

lae.travis-lxc
=========

Configures and starts N LXC containers to use in the Travis CI environment for
simpler testing of Ansible roles across different distributions.


Role Variables
--------------
By default, the environment variables `LXC_DISTRO` and `LXC_RELEASE` are used
for selecting which LXC container template to test from (see below). Using the
following `env` config in your `.travis.yml` will test against all supported
LXC templates:

    env:
      - LXC_DISTRO=debian LXC_RELEASE=stretch
      - LXC_DISTRO=debian LXC_RELEASE=jessie
      - LXC_DISTRO=debian LXC_RELEASE=wheezy
      - LXC_DISTRO=ubuntu LXC_RELEASE=xenial
      - LXC_DISTRO=ubuntu LXC_RELEASE=trusty
      - LXC_DISTRO=ubuntu LXC_RELEASE=precise
      - LXC_DISTRO=centos LXC_RELEASE=7
      - LXC_DISTRO=centos LXC_RELEASE=6
      - LXC_DISTRO=fedora LXC_RELEASE=25
      - LXC_DISTRO=fedora LXC_RELEASE=26
      - LXC_DISTRO=fedora LXC_RELEASE=27

The default template this role uses is the Debian Jessie template:

    template: "{{ lookup('env', 'LXC_DISTRO') | default('debian', true) }}"
    release: "{{ lookup('env', 'LXC_RELEASE') | default('jessie', true) }}"

The following role variables may also be overridden:

- `host_prefix: test`: containers are given hostnames of the format
  `{{ host_prefix }}##.lxc` where ## is a zero-padded integer, i.e. by default
  the first container's hostname is `test01.lxc`.
- `host_quantity: 1`: the number of containers to start.

You can also override the container configuration used, if necessary (for e.g.
mounting a shared folder):

    container_config:
      - "lxc.aa_profile=unconfined"
      - "lxc.mount.auto=proc:rw sys:rw cgroup-full:rw"
      - "lxc.cgroup.devices.allow=a *:* rmw"

Example Playbook
----------------

See `example.yml`, as well as `.travis.yml`. Some more concrete documentation
will be written later.

Contributors
------------

Musee Ullah <lae@lae.is> (author and maintainer)
Wilmar den Ouden <@wilmardo>
