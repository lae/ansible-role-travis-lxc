[![Build Status](https://travis-ci.org/lae/ansible-role-travis-lxc.svg?branch=master)](https://travis-ci.org/lae/ansible-role-travis-lxc)
[![Galaxy Role](https://img.shields.io/badge/ansible--galaxy-travis--lxc-blue.svg)](https://galaxy.ansible.com/lae/travis-lxc/)

lae.travis-lxc
==============

Configures and starts N LXC containers to use in the Travis CI environment for
simpler testing of Ansible roles across different distributions.

# Usage

So you want to test your Ansible roles on Travis CI, but you don't want to use
Docker because it doesn't mimic a full OS? LXC is what you want to use. This
role will hopefully abstract much of the boilerplate you might otherwise use.

To get started, a minimal `.travis.yml` that thoroughly tests that your role is
valid, idempotent, and functional may look like this:

```yaml
---
language: python
sudo: required
dist: trusty
install:
- pip install ansible
- ansible-galaxy install lae.travis-lxc,v0.7.3
- ansible-playbook tests/install.yml -i tests/inventory
before_script: cd tests/
script:
- ansible-playbook -i inventory deploy.yml --syntax-check
- ansible-playbook -i inventory -v deploy.yml
- 'ANSIBLE_STDOUT_CALLBACK=debug unbuffer ansible-playbook -vv -i inventory
  deploy.yml > play.log || (e=$?; cat play.log; exit $e); printf "Idempotence: ";
  grep -A1 "PLAY RECAP" play.log | grep -qP "changed=0 .*failed=0 .*"
  && (echo "PASS"; exit 0) || (echo "FAIL"; cat play.log; exit 1)'
- ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook -i inventory -v test.yml
```

You'll note that four files are referenced. You can decide how to define your
build process, but the following is what typically serves most purposes:

- **tests/install.yml**: executes `lae.travis-lxc` and other pre-install steps
- **tests/deploy.yml**: executes the role you're testing
- **tests/test.yml**: executes validation tests against your deployment
- **tests/inventory**: contains a list of LXC container hostnames

`install.yml` may look like this:

```yaml
---
- hosts: localhost
  connection: local
  roles:
    - lae.travis-lxc
  vars:
    test_profiles:
      - profile: debian-stretch
      - profile: ubuntu-bionic
      - profile: centos-7
      - profile: alpine-v3.8

- hosts: all
  tasks: []
```

The first play brings up three containers of three different distributions. The
second play could be used to either run other roles or pre-installation tasks
that you would expect your role not to do (for example, install `epel-release`
or create a device node for FUSE (because LXC doesn't do that for you)).

`deploy.yml` may look like this:

```yaml
---
- hosts: all
  become: true
  any_errors_fatal: true
  roles:
    - ansible-role-strawberry-milk
  vars:
    number_of_cartons: 15
```

This is basically a rendition of what `ansible-galaxy init` would spit out in
`test.yml`. This would have everything you need to execute your role properly.
For more complex roles, it makes sense to split variables out into the
`tests/group_vars` folder and configure your inventory appropriately.

`test.yml` should contain your tests, if you wanted to run any:

```yaml
---
- hosts: all
  tasks:
    - name: Ensure that the Strawberry Milk HTTP service is running
      uri:
        url: "http://{{ inventory_hostname }}:1515"
    - block:
      - name: Print out Strawberry Milk configuration
        shell: cat /etc/strawberry_milk.conf
        changed_when: false
      - name: Print out system logs
        shell: "cat /var/log/messages || cat /var/log/syslog || journalctl -xb"
      ignore_errors: yes
```

This can be useful to ensure that a service is running, that a cluster is in a
healthy state, that certain files are being created...you get the idea. The
`block` I have here is an area where I run diagnostic-like tasks to help me
debug issues, which includes printing out logs and the sort. It's wrapped with
`ignore_errors` so that tasks here don't affect the build (one major
contendant that errors is the log printing task when testing multiple distros).

And finally, the inventory:

```ini
debian-stretch-01
ubuntu-bionic-01
centos-7-01
alpine-v3-8-01
```

Hostnames are generated from two parts, a prefix and suffix. By default, these
are generated from the `profile` key in `test_profiles` in the format of
`{{ profile }}-{{ suffix }}`, where suffix by default is `01`.

> **Note**: If `test_profiles` is not specified, the role defaults to creating
> one Debian Stretch container named `test01.lxc` (which is further overridable
> with environment variables and other role variables). This is in order to
> maintain backwards compatibility with an older version of this role but will
> eventually be deprecated - so be sure to specify `test_profiles`.

Once you have those files written, you're ready to test your role in Travis CI.
However, you probably want more out of it, so let's go over some other topics.

### Testing multiple Ansible versions

It's likely you'll want to test your role against the development branch as well
as all currently supported Ansible releases. This is something you'd want to
configure in `.travis.yml` and there are various ways to go about it:

```yaml
env:
- ANSIBLE_GIT_VERSION='devel' # 2.8.x development branch
- ANSIBLE_VERSION='<2.8.0' # 2.7.x
- ANSIBLE_VERSION='<2.7.0' # 2.6.x
- ANSIBLE_VERSION='<2.6.0' # 2.5.x
install:
- if [ "$ANSIBLE_GIT_VERSION" ]; then pip install "https://github.com/ansible/ansible/archive/${ANSIBLE_GIT_VERSION}.tar.gz";
  else pip install "ansible${ANSIBLE_VERSION}"; fi
- ansible --version
```

Here, we've added an install task that will either take `ANSIBLE_GIT_VERSION`,
as a valid reference in the Ansible git repository, or `ANSIBLE_VERSION`, a
valid version string that can be passed to pip during installation.

### Ansible performance and profiling

You can drop pretty much anything in `tests/ansible.cfg`.

```ini
[defaults]
callback_whitelist=profile_tasks
forks=20
internal_poll_interval = 0.001
```

This runs the `profile_tasks` callback on your playbook, which helps to identify
which tasks take the longest to complete. You could use this to identify any
performance regressions, for example. If you're bringing up and running your
playbook against multiple containers, specify `forks`. `internal_poll_interval`
is a good general setting to have when you have multiple tasks/loops.

### Caching

LXC images can be cached to save on bootstrapping time, especially when you're
testing against several profiles. Drop the following in your `.travis.yml` and
this role will take care of the rest.

```yaml
cache:
  directories:
  - "$HOME/lxc"
  pip: true
```

*(`pip: true` doesn't mean anything for this role, but it's included here since
you might want to cache your Ansible installation as well.)*

Role Variables
--------------

To specify what distributions to test against, use `test_profiles`. Supported
profiles include (feel free to request/contribute new ones):

```yaml
test_profiles:
  - profile: debian-stretch
  - profile: debian-jessie
  - profile: debian-wheezy # EOL
  - profile: centos-7
  - profile: centos-6
  - profile: ubuntu-bionic
  - profile: ubuntu-xenial
  - profile: ubuntu-trusty
  - profile: fedora-28
  - profile: fedora-27
  - profile: fedora-26 # EOL
  - profile: fedora-25 # EOL
  - profile: alpine-v3.8
  - profile: alpine-v3.7
  - profile: alpine-v3.6
```

Profiles marked as `EOL` above, while are EOL upstream, are still available, but
no guarantees are made that they are still functional (but they probably are).

You can look at `vars/main.yml` for more information about those profiles.

A test container, if no prefix is specified, is given a hostname of
`{{ profile }}-{{ suffix }}`, where `profile` is sanitized for usage in a DNS
name. Default prefixes are defined in `vars/main.yml`, so refer to it if you
are unsure what a particular profile's prefix is. If `test_host_suffixes` is
not defined, `suffix` here becomes a zero-padded double digit integer starting
from 1 (up to the requested number of hosts specified by
`test_hosts_per_profile`).

For example, the following creates `debian01`, `debian02`, and `debian03`:

```yaml
test_profiles:
  - profile: debian-stretch
    prefix: debian
test_hosts_per_profile: 3
```

The following creates `ubuntu-app-python2` and `ubuntu-app-python3`:

```yaml
test_profiles:
  - profile: ubuntu-bionic
    prefix: ubuntu-
test_host_suffixes:
  - app-python2
  - app-python3
```

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

If caching is identified to be enabled in `.travis.yml`, you can selectively
cache a subset of your test profiles by specifying them in `lxc_cache_profiles`.
These must be valid profiles and present in `test_profiles`.

To cache to directory different from `$HOME/lxc`, modify `lxc_cache_directory`.

If you need to disable the usage of OverlayFS in the LXC containers (e.g. if
you're attempting to use OverlayFS inside of the LXC container), set
`lxc_use_overlayfs` to `no` (or any `False` variant)

Contributors
------------

Musee Ullah ([@lae](https://github.com/lae), <lae@lae.is>)  
Wilmar den Ouden ([@wilmardo](https://github.com/wilmardo))

Stability
---------

This role is currently still pre-1.0 and thus is not guaranteed to be stable.
If you run into an issue using this role, please open an issue with a brief
description and any appropriate logs so that it can be fixed and we can be one
step closer to our first stable release.

Please make sure you are pinning to a specific version (pinning to minor may be
fine) when using this role. Failure to do so may result in your tests beginning
to fail due to breaking changes in a minor version release before a 1.0 release.
