#!/bin/bash

MAX_PAGE_COUNT=4
ALL_GIT_REPO_FILE="allgitrepo.tmp"
j=1
#wget all page
for ((i=1;i<=${MAX_PAGE_COUNT};i++))
do
  wget "https://github.com/linuxdeepin?page=${i}" -O "page${i}"
done

grep repo-list-name -A 1 page* | sed '/<h3/d'| sed '/--/d' | sed 's/page.-//g' | sed 's/<a href="//g' | sed  's/[[:space:]]//g' |sed 's/"itemprop=.namecodeRepository.>//g' > "${ALL_GIT_REPO_FILE}"

all_repo_count=`cat ${ALL_GIT_REPO_FILE} | wc -l`
echo "repo count is ${all_repo_count}"

for ((j=1;j<=${all_repo_count};j++))
do
  gitreponame=`sed -n "${j}p" ${ALL_GIT_REPO_FILE}`
  gitaddrs="https://github.com${gitreponame}.git"  
  git clone ${gitaddrs}
done

