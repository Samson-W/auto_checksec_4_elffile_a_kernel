#!/bin/bash

# now github max page is 4, we need to be modified according to the latest situation.
MAX_PAGE_COUNT=4
ALL_GIT_REPO_FILE="allgitrepo.tmp"
STATIC_ANALYSIS_LOG_DIR="static_analysis_log"
j=1

mkdir -p ${STATIC_ANALYSIS_LOG_DIR}
mkdir -p deepin_all_repo
cd deepin_all_repo
#wget all page
for ((i=1;i<=${MAX_PAGE_COUNT};i++))
do
  wget "https://github.com/linuxdeepin?page=${i}" -O "page${i}"
done

# get all repo name write to file.
grep repo-list-name -A 1 page* | sed '/<h3/d'| sed '/--/d' | sed 's/page.-//g' | sed 's/<a href="//g' | sed  's/[[:space:]]//g' |sed 's/"itemprop=.namecodeRepository.>//g' | sed 's/^\///g'  > "${ALL_GIT_REPO_FILE}"

all_repo_count=`cat ${ALL_GIT_REPO_FILE} | wc -l`
echo "repo count is ${all_repo_count}"


for ((j=1;j<=${all_repo_count};j++))
do
  gitrepopathname=`sed -n "${j}p" ${ALL_GIT_REPO_FILE}`
  # if repo is exist, git pull for release of up-to-date; else git clone to local.
  gitreponame=`echo ${gitrepopathname} | sed -e 's/[a-z]*\///g'`
  if [ -d ${gitreponame} ]; then
     cd ${gitreponame}
     git pull
     cd ..
  else
     gitaddrs="https://github.com/${gitrepopathname}.git"  
     git clone ${gitaddrs}
  fi
  # Static analysis begin
  echo "-------------------------------${gitreponame} static analysis begin--------------------------------------------------"
  # Finding the appropriate language file exists, using the corresponding static code checking tool.
  # for c/c++
  C_file_count=`find ${gitreponame} -name "*.c" | wc -l`
  Cplus_file_count=`find ${gitreponame} -name "*.cpp" | wc -l`
  log_filename="../${STATIC_ANALYSIS_LOG_DIR}/`date +%F`_${gitreponame}_SA.log"
  if [ ${C_file_count} -gt 0 -o ${Cplus_file_count} -gt 0 ];then
    echo "-----------------------C/C++ static analysis start----------------------" >> ${log_filename}
    flawfinder ${gitreponame} >> ${log_filename} 2>&1
    echo "-----------------------C/C++ static analysis end  ----------------------" >> ${log_filename}
  fi

  # for python
  python_file_count=`find ${gitreponame} -name "*.py" | wc -l`
  if [ ${python_file_count} -gt 0 ];then
    echo "-----------------------python static analysis start----------------------"
    
    echo "-----------------------python static analysis end  ----------------------"
  fi
  # for go
  go_file_count=`find ${gitreponame} -name "*.go" | wc -l`
  if [ ${go_file_count} -gt 0 ];then
    echo "--------------------------go  static analysis start----------------------" >> ${log_filename}
    go tool vet -all ${gitreponame} >> ${log_filename} 2>&1
    echo "--------------------------go  static analysis end  ----------------------" >> ${log_filename}
  fi

  # for javasecript
  #js_file_count=`find ${gitreponame} -name "*.js" | wc -l`
  #if [ ${python_file_count} -gt 0 ];then
  #  echo "---------------------javsecript static analysis start--------------------"
  #  
  #  echo "---------------------javasecript static analysis end---------------------"
  #fi
  
  if [ $C_file_count -eq 0 -a $Cplus_file_count -eq 0 -a $python_file_count -eq 0 -a $go_file_count -eq 0 ]; then
    echo "---------------------------This repo not is c/c++,python,go program.----------------------------------"
  fi  

  echo "-------------------------------${gitreponame} static analysis end  --------------------------------------------------"
done

