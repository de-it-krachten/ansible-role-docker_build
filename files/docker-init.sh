#!/bin/bash -e

# Get the name of the calling script
FILENAME=$(readlink -f $0)
BASENAME="${FILENAME##*/}"
BASENAME_ROOT=${BASENAME%%.*}
DIRNAME="${FILENAME%/*}"
TMPDIR=$(mktemp -d)
TMPFILE=${TMPDIR}/.tmp.${RANDOM}.${RANDOM}
[[ $DIRNAME == /usr/local/bin ]] && TEMPLATEDIR=/usr/local/${BASENAME_ROOT} || TEMPLATEDIR=${DIRNAME}

function File
{

  File=$1

  if [[ ! -f $File ]]
  then
    cp ${DIRNAME}/templates/${File} ${PWD}
  fi

}


function Template
{

  File=$1

  if [[ ! -f $File ]]
  then
    cp ${DIRNAME}/templates/${File}.j2 ${PWD}
    e2j2 -m "<=" -f ${File}.j2 || exit 1
    rm -f ${File}.j2
  fi

}

Template docker-settings.yml
Template Dockerfile.j2
Template build-custom.yml
Template requirements.yml
