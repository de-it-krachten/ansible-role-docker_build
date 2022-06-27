[![CI](https://github.com/de-it-krachten/ansible-role-docker_build/workflows/CI/badge.svg?event=push)](https://github.com/de-it-krachten/ansible-role-docker_build/actions?query=workflow%3ACI)


# ansible-role-docker_build

Install tooling for settings up automatic docker builds


## Platforms

Supported platforms

- Red Hat Enterprise Linux 7<sup>1</sup>
- Red Hat Enterprise Linux 8<sup>1</sup>
- CentOS 7
- CentOS 8
- RockyLinux 8
- AlmaLinux 8<sup>1</sup>
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
# target location
docker_build_location: /usr/local/docker-build

# list of OS packages to install
docker_build_packages:
   - rsync
   - git

# list of pip packages to install
docker_build_pip_packages:
  - e2j2
  - "yq==2.12.2"
  - jmespath
</pre></code>



## Example Playbook
### molecule/default/converge.yml
<pre><code>
- name: sample playbook for role 'docker_build'
  hosts: all
  vars:
  pre_tasks:
    - name: Create 'remote_tmp'
      file:
        path: /root/.ansible/tmp
        state: directory
        mode: "0700"
  roles:
    - python
    - docker
    - docker_compose
  tasks:
    - name: Include role 'docker_build'
      include_role:
        name: docker_build
</pre></code>
