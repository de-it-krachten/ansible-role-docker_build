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

function Python
{

  OS_NAME=$(lsb_release -is)
  OS_RELEASE=$(lsb_release -rs | sed "s/\..*//")

  if [[ $OS_NAME == "RedHatEnterpriseServer" && $OS_RELEASE =~ "7" ]]
  then
    Force_python2=true
  fi

}

function Setup
{

  echo "Copying ansible code into temporary directory '${TMPDIR}'"
  rsync -av ${TEMPLATEDIR}/ansible ${TMPDIR}
  cp docker-settings.yml ${TMPDIR}/ansible
  [[ -f requirements.yml ]] && cp requirements.yml ${TMPDIR}/ansible/roles
  [[ -f build-custom.yml ]] && cp build-custom.yml ${TMPDIR}/ansible
  [[ -d additional_files ]] && rsync -av additional_files/ ${TMPDIR}

  cd ${TMPDIR}/ansible
  Ansible_args="-i localhost, -c local -e build_refresh=$Build_refresh"
  [[ -n $Force_python2 ]] && Ansible_args="$Ansible_args -e force_python2=$Force_python2"
  ansible-galaxy install -r ${TMPDIR}/ansible/roles/requirements.yml -p ${TMPDIR}/ansible/roles/ --ignore-errors

}


Debug=false
Build=true
Push=false
Build_refresh=true

# parse command line into arguments and check results of parsing
while getopts :bBdpPrR OPT
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
     r) Build_refresh=true
        ;;
     R) Build_refresh=false
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

Python


if [[ ! -f docker-settings.yml ]]
then
  echo "Docker build project not initialized!" >&2
  echo "Execute 'docker-init.sh' and edit docker-settings.yml to reflect your requirements." >&2
  exit 1
fi


#----------------------------------------------------------
# set-up required structure
#----------------------------------------------------------

echo "================================================================="
echo "Executing setup phase"
echo "================================================================="
Setup


#----------------------------------------------------------
# build image
#----------------------------------------------------------

if [[ $Build == true ]]
then
  echo "================================================================="
  echo "Executing build phase"
  echo "================================================================="
  ansible-playbook ${TMPDIR}/ansible/build.yml $Ansible_args
fi


#----------------------------------------------------------
# push image
#----------------------------------------------------------

if [[ $Push == true ]]
then
  echo "================================================================="
  echo "Executing push phase"
  echo "================================================================="
  ansible-playbook ${TMPDIR}/ansible/push.yml $Ansible_args
fi
