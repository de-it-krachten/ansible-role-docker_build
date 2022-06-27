#!/bin/bash

dir=../../git-tools/cicd/docker

rsync -c -av $dir/docker-init.sh  files/
rsync -c -av $dir/docker-build.sh files/
rsync -c -av $dir/ansible         files/
rsync -c -av $dir/templates       files/

