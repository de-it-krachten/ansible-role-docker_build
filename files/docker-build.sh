#!/bin/bash -e

# Get the name of the calling script
FILENAME=$(readlink -f $0)
BASENAME="${FILENAME##*/}"
BASENAME_ROOT=${BASENAME%%.*}
DIRNAME="${FILENAME%/*}"
TMPDIR=$(mktemp -d)
TMPFILE=${TMPDIR}/.tmp.${RANDOM}.${RANDOM}
[[ $DIRNAME == /usr/local/bin ]] && TEMPLATEDIR=/usr/local/${BASENAME_ROOT} || TEMPLATEDIR=${DIRNAME}

function Cleanup
{

  [[ $Debug == false ]] && rm -fr ${TMPDIR}
  # rm -f ${HOME}/.docker/config.json

}

Debug=false
Build=true
Push=false

# parse command line into arguments and check results of parsing
while getopts :bBdpP OPT
do
   case $OPT in
     b) Build=true
        ;;
     B) Build=false
        ;;
     d) Debug=true
        set -vx
        ;;
     p) Push=true
        ;;
     P) Push=false
        ;;
     *) echo "Unknown flag -$OPT given!" >&2
        exit 1
        ;;
   esac

   # Set flag to be use by Test_flag
   eval ${OPT}flag=1

done
shift $(($OPTIND -1))


# Make sure we cleanup our crap at exit
trap 'cd / ; Cleanup' EXIT


#----------------------------------------------------------
# export variables
#----------------------------------------------------------

export SOURCE_PATH=$PWD
export DOCKER_PUSH=$Push


#----------------------------------------------------------
# set-up required structure
#----------------------------------------------------------

if [[ $Build == true ]]
then
  echo "Copying ansible code into temporary directory '${TMPDIR}'"
  rsync -av ${TEMPLATEDIR}/ansible ${TMPDIR}
  cp docker-settings.yml ${TMPDIR}/ansible
  [[ -f requirements.yml ]] && cp requirements.yml ${TMPDIR}/ansible/roles
  [[ -f build-custom.yml ]] && cp build-custom.yml ${TMPDIR}/ansible
fi

#----------------------------------------------------------
# build image
#----------------------------------------------------------

if [[ $Build == true ]]
then
  cd ${TMPDIR}/ansible
  # Ansible_args="-i localhost, -c local -e ansible_python_interpreter=/usr/libexec/platform-python"
  Ansible_args="-i localhost, -c local -e ansible_python_interpreter=/usr/bin/python3"
  ansible-galaxy install -r roles/requirements.yml -p roles/ --ignore-errors
  ansible-playbook build.yml $Ansible_args
  cd - >/dev/null
fi
