#!/usr/bin/env bash

source $ROOT/envsetup.sh

REPOS=(
 "3rdParty/externalLibs"
 "data-plane-common"
 "Packaging"
 "traffic-server"
 "unittest-content"
 "."
)

ORGANIZATION="Interstellar"

######################################################
# Function to set the Github protections for a particular branch
#
# NOTE! The Protection REST API is currently in the pre-release
# phase for Github v2.8 so we have to slightly modify the JSON that we send
# as well as add an Accept header with a custom type to get the API to work.
# The API also doesn't set the correct required review permissions, so you'll
# have to do that manually.
#
# URL: https://developer.github.com/changes/2015-11-11-protected-branches-api/
#      https://developer.github.com/changes/2016-06-27-protected-branches-api-update/
######################################################
function set_branch_permissions() {

  local REPO=`basename $(git rev-parse --show-toplevel)`

  local PERMISSIONS='{ "required_pull_request_reviews": { "include_admins": true }, "required_status_checks": null, "restrictions": null }'

  echo "Launch this page to set the full permissions for $REPO:"
  echo "https://github4-chn.cisco.com/$organization/$REPO/settings/branches/$branch_type/$branch_name"
  curl \
    -H "Authorization: token $GITHUB_OAUTH_TOKEN" \
    -H "Accept: application/vnd.github.loki-preview" \
    -XPUT -d "$PERMISSIONS" \
    https://github4-chn.cisco.com/api/v3/repos/$organization/$REPO/branches/$branch_type%2F$branch_name/protection
}

######################################################
# Function to clear the branch permissions for the current repository in Github
#
# NOTE! Same notes listed above apply
######################################################
function clear_branch_permissions() {

  local REPO=`basename $(git rev-parse --show-toplevel)`

  local PERMISSIONS='{ "protection": { "enabled": false } }'

  echo "Clearing branch permissions for $REPO"
  echo "https://github4-chn.cisco.com/$organization/$REPO/branches/$branch_type/$branch_name"
  curl \
    -H "Authorization: token $GITHUB_OAUTH_TOKEN" \
    -H "Accept: application/vnd.github.loki-preview" \
    -XPATCH -d "$PERMISSIONS" \
    https://github4-chn.cisco.com/api/v3/repos/$organization/$REPO/branches/$branch_type%2F$branch_name
}

######################################################
# Function to create a branch
######################################################
function create() {

  echo $(pwd) >&3
  echo "Creating $branch_type/$branch_name"

  git flow $branch_type start $branch_name
  git flow $branch_type publish $branch_name

  # Mark the branch as protected
  set_branch_permissions
}

######################################################
# Function to close a release branch and update the
# remote repositories
######################################################
function finish() {

  echo $(pwd) >&3
  echo "Finishing $branch_type/$branch_name and attaching release notes $release_notes_file" >&3

  # Clear the branch permissions so we can delete the branch
  clear_branch_permissions

  # Make sure we are on the develop branch so that we can automatically delete the branch
  # we are finishing
  git checkout develop
  git flow $branch_type finish -p -f $release_notes_file $branch_name
  git push --tags

}


######################################################
# Function to excecute the specified function in each repo
######################################################
function foreach_repo() {

  OPERATION=$1

  T=$(gettop)

  local HERE=`pwd`

  # Go to the top of the build tree
  if [ -d "$T" ]; then

    cd $T

    for item in ${repos[*]}; do

      pushd . > /dev/null

      cd $item

      # Exectue the operation
      $OPERATION

      popd > /dev/null

    done

    cd $HERE

  else
    echo "Couldn't locate the top of the tree. Try setting TOP."
  fi
}

function show_help() {
  cat <<HERE

  create_branch.sh -t [hotfix, release] -n BRANCH_NAME -o [create, finish'] [-v] [RELEASE_NOTES]

  Script to create branches for release management

 -v Enable verbose logging
 -t The branch type to create 'hotfix' or 'release'
 -n The name for the branch to create
 -o The operation perform. Either 'create', or 'finish'
HERE
}

######################################################
# Parse the command line options
######################################################

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
output_file=""
verbose=0

while getopts "vt:o:n:f:u:r:" opt; do

  case "$opt" in
    v)  verbose=1
      ;;
    t)
      case "$OPTARG" in
        hotfix)
          branch_type=$OPTARG
          ;;
        release)
          branch_type=$OPTARG
          ;;
        *)
          echo "Invalid branch type specified: $OPTARG"
          show_help
          exit 0
          ;;
      esac
      ;;
    o)
      case "$OPTARG" in
        create)
          operation=$OPTARG
          ;;
        finish)
          operation=$OPTARG
          ;;
        *)
          echo "Invalid branch type specified: $OPTARG"
          show_help
          exit 0
          ;;
      esac
      ;;
    n)  branch_name=$OPTARG
      ;;
    u)  organization=$OPTARG
      ;;
    f)  release_notes_file=$OPTARG
      ;;
    *)
      show_help
      exit 0
      ;;

  esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

repos="$@"

# Redirect output if verbose is specified
if [[ $verbose -eq 0 ]]; then
  exec 3<>/dev/null
else
  exec 3>&1
fi

# Set the repos to the default if they are not specified
if [ -z $repos ]; then
  repos=( "${REPOS[@]}" )
fi

if [ -z $organization ]; then
  organization=$ORGANIZATION
fi

echo "verbose=$verbose, type='$branch_type', name: $branch_name, release_notes: $release_notes_file" >&3

# Debug prints
for r in ${repos[*]}; do
  echo $r >&3
done
echo $organization >&3

# Process each repository
foreach_repo $operation
