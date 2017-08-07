#!/usr/bin/env bash 
#set -x

##############################################################
# Function to checkout PE submodules to a specified branch
##############################################################

ws=`pwd`
git_params="$@"

REPOS=(
 "3rdParty/externalLibs"
 "data-plane-common"
 "Packaging"
 "traffic-server"
 "unittest-content"
 "."
)

ORGANIZATION="Interstellar"

for item in ${REPOS[@]}
do
	cd $ws
	if [ -d $item ]; then
		echo "run git checkout $git_params in ${itme}"
		cd $item
		git checkout $git_params
	else
		echo "submodule $item doesn't exist! "
		exit 1
	fi
done


