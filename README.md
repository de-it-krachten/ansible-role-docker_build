[![CI](https://github.com/de-it-krachten/ansible-role-docker_build/workflows/CI/badge.svg?event=push)](https://github.com/de-it-krachten/ansible-role-docker_build/actions?query=workflow%3ACI)


# ansible-role-docker_build

Install tooling for settings up automatic docker builds


## Platforms

Supported platforms

- Red Hat Enterprise Linux 7<sup>1</sup>
- Red Hat Enterprise Linux 8<sup>1</sup>
- Red Hat Enterprise Linux 9<sup>1</sup>
- CentOS 7
- CentOS 8
- RockyLinux 8
- OracleLinux 8
- AlmaLinux 8
- AlmaLinux 9
- Debian 10 (Buster)
- Debian 11 (Bullseye)
- Ubuntu 18.04 LTS
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Fedora 35
- Fedora 36

Note:
<sup>1</sup> : no automated testing is performed on these platforms

## Role Variables
### defaults/main.yml
<pre><code>
# Prepare host (docker/python)
docker_build_preparation: false

# target location
docker_build_location: /usr/local/docker-build

# list of OS packages to install
docker_build_packages:
   - rsync
   - git

# list of pip packages to install
docker_build_pip_packages:
  - e2j2
  - jmespath
</pre></code>

### vars/default.yml
<pre><code>

</pre></code>



## Example Playbook
### molecule/default/converge.yml
<pre><code>
- name: sample playbook for role 'docker_build'
  hosts: all
  vars:
    docker_build_preparation: True
    docker_daemon_options: {'storage-driver': 'vfs'}
  tasks:
    - name: Include role 'docker_build'
      include_role:
        name: docker_build
</pre></code>
