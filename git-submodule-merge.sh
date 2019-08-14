#!/bin/bash

# Simple script to merge submodules of a git repo(A) into the repo(A) while preserving commit history.
# NOTE: The script will make some EXTRA commits while merging

script_path=$BASH_SOURCE
script_dir=$(dirname "$script_path")

source $script_dir/colors.sh

set -e
trap 'echo -e "${RED}-------------------------\nScript Failed\n-------------------------${NC}"' ERR

LOCAL_PATH=${PWD}

echo -e "${GREEN} - Updating all submodules...${NC}"
git submodule update --init --recursive

echo -e "${GREEN} - Generating list of submodule paths...${NC}"
mapfile -t submodule_paths < <( git submodule status --recursive | cut -d" " -f3 )
total_count=${#submodule_paths[@]}
echo -e "${BLUE}   Total submodules found: $total_count${NC}"
count=0
for i in "${submodule_paths[@]}"
do
   :
   submodule_dir=$(realpath $i)

   count=$((count+1))

   echo -e "${PURPLE} - Processing submodule $i ${GREEN}[$count/$total_count]${NC}"
   echo -e "${YELLOW}   Preparing for separation${NC}"
   cd $i
   mkdir tmpGitDir
   git mv -k * tmpGitDir/
   sub_dir=$(dirname $i)
   if [ "$sub_dir" != "." ];then
     mkdir -p $sub_dir
   fi
   mv tmpGitDir $i
   git add .
   git commit -m "Prepare ${i} for import" &>/dev/null

   echo -e "${YELLOW}   Creating empty repo for temp backup...${NC}"
   tmp_dir=$(mktemp -d -t git-XXXXXXXXXX)
   cd $tmp_dir
   git init  &>/dev/null &>/dev/null
   touch t
   git add .
   git commit -m tmp &>/dev/null
   git config receive.denyCurrentBranch ignore
   cd $submodule_dir

   echo -e "${YELLOW}   Pushing submodule to temp repo...${NC}"
   git push $tmp_dir HEAD:master --force &>/dev/null

   echo -e "${YELLOW}   Cleaning up repos...${NC}"
   cd $tmp_dir
   git reset --hard &>/dev/null

   cd $LOCAL_PATH
   echo -e "${YELLOW}   Removing submodule $i${NC}"
   git submodule deinit -f $i &>/dev/null
   git rm -f $i &>/dev/null
   git commit -m "Removed submodule $i" &>/dev/null
   rm -rf .git/modules/$i &>/dev/null
   
   echo -e "${YELLOW}   Merging temp repo of submodule as subdir with history...${NC}"
   git fetch $tmp_dir &>/dev/null
   git pull --no-edit --allow-unrelated-histories $tmp_dir &>/dev/null
   git commit --amend -m "Merge submodule $i as directory" &>/dev/null
done