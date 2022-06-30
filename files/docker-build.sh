#!/bin/bash -e
#
#=====================================================================
#
# Name        :
# Version     :
# Author      :
# Description :
#
#
#=====================================================================
unset Debug
#export Debug="set -x"
$Debug


##############################################################
#
# Defining standard variables
#
##############################################################

# Set temporary PATH
export PATH=/bin:/usr/bin:/sbin:/usr/sbin:$PATH

# Get the name of the calling script
FILENAME=$(readlink -f $0)
BASENAME="${FILENAME##*/}"
BASENAME_ROOT=${BASENAME%%.*}
DIRNAME="${FILENAME%/*}"

# Define temorary files, debug direcotory, config and lock file
TMPDIR=$(mktemp -d)
TMPFILE=${TMPDIR}/${BASENAME}.${RANDOM}.${RANDOM}
DEBUGDIR=${TMPDIR}/${BASENAME_ROOT}_${USER}
CONFIGFILE=${DIRNAME}/${BASENAME_ROOT}.cfg
LOCKFILE=${VARTMP}/${BASENAME_ROOT}.lck

# Logfile & directory
LOGDIR=$DIRNAME
LOGFILE=${LOGDIR}/${BASENAME_ROOT}.log

# Set date/time related variables
DATESTAMP=$(date "+%Y%m%d")
TIMESTAMP=$(date "+%Y%m%d.%H%M%S")

# Figure out the platform
OS=$(uname -s)

# Get the hostname
HOSTNAME=$(hostname -s)


##############################################################
#
# Defining custom variables
#
##############################################################

[[ $DIRNAME == /usr/local/bin ]] && TEMPLATEDIR=/usr/local/${BASENAME_ROOT} || TEMPLATEDIR=${DIRNAME}


##############################################################
#
# Defining standarized functions
#
#############################################################

FUNCTIONS=${DIRNAME}/functions.sh
if [[ -f ${FUNCTIONS} ]]
then
   . ${FUNCTIONS}
#else
#   echo "Functions file '${FUNCTIONS}' could not be found!" >&2
#   exit 1
fi


##############################################################
#
# Defining customized functions
#
#############################################################

function Usage
{

  cat << EOF | grep -v "^#"

$BASENAME

Usage : $BASENAME <flags> <arguments>

Flags :

   -d|--debug      : Debug mode (set -x)
   -D|--dry-run    : Dry run mode
   -h|--help       : Prints this help message
   -v|--verbose    : Verbose output

   -b|--build      : Run build phase (default)
   -B|--no-build   : Do not run build phase 
   -c|--cleanup    : Cleanup old image/container (default)
   -C|--no-cleanup : Do not cleanup old image/container
   -p|--push       : Push docker image to registry
   -P|--no-push    : Do not push docker image to registry (default)

EOF

}

function Cleanup
{

  [[ $Debug == false ]] && rm -fr ${TMPDIR}
  rm -f ${HOME}/.docker/config.json

}

function Initialize
{

  # Get distro specifics
  OS_NAME=$(lsb_release -is)
  OS_RELEASE=$(lsb_release -rs)
  OS_RELEASE_MAJOR=$(lsb_release -rs | sed "s/\..*//")

  # Force Ansible to use colors
  export PY_COLORS=1
  export ANSIBLE_FORCE_COLOR=1

  if [[ $OS_NAME == "RedHatEnterpriseServer" && $OS_RELEASE_MAJOR == "7" ]]
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


##############################################################
#
# Main programs
#
#############################################################

# Make sure temporary files are cleaned at exit
trap 'rm -f ${TMPFILE}*' EXIT
trap 'exit 1' HUP QUIT KILL TERM INT

# Set the defaults
Debug_level=0
Verbose=false
Verbose_level=0
Dry_run=false
Echo=

Build=true
Push=false
Build_refresh=true

# parse command line into arguments and check results of parsing
while getopts :bBdDghv-: OPT
do

  # Support long options
  if [[ $OPT = "-" ]] ; then
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi

  case $OPT in
    b|build)
      Build=true
      ;;
    B|no-build)
      Build=false
      ;;
    c|cleanup)
      Cleanup=true
      ;;
    C|no-cleanup)
      Cleanup=false
      ;;
    d|debug)
      Verbose=true
      Verbose_level=2
      Verbose1="-v"
      Debug_level=$(( $Debug_level + 1 ))
      export Debug="set -vx"
      $Debug
      eval Debug${Debug_level}=\"set -vx\"
      ;;
    D|dry-run)
      Dry_run=true
      Dry_run1="-D"
      Echo=echo
      ;;
    h|help)
      Usage
      exit 0
      ;;
    p|push)
      Push=true
      ;;
    P|no-push)
      Push=false
      ;;
    v|verbose)
      Verbose=true
      Verbose_level=$(($Verbose_level+1))
      Verbose1="-v"
      ;;
    *)
      echo "Unknown flag -$OPT given!" >&2
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

Initialize


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
  if [[ -n $DOCKER_AUTH_CONFIG && ! -f ${HOME}/.docker/config.json ]]
  then
    echo "Writing docker credentials"
    echo "${DOCKER_AUTH_CONFIG}" | jq . > ${HOME}/.docker/config.json
  fi
  ansible-playbook ${TMPDIR}/ansible/push.yml $Ansible_args
fi

# Exit cleanly
exit 0
