#!/bin/bash

ELFPATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
CHECKSEC="./checksec"
ELFFILELISTFILE="./dde_exec_check.list"
CHECKSEC_CI="/tmp/systemcheck/checksec"
ELFFILELISTFILE_CI="/tmp/systemcheck/dde_exec_check.list"
ELFCHECKOPTION=$1

check-security-update()
{
  echo ".........................................................Start check updata of security......................................"
  apt-get upgrade -s | grep -i security > /tmp/updatasec
  linec=`cat /tmp/updatasec | wc -l`
  if [ $linec -gt 0 ]; then
    echo -e "\033[1;31;40m Updata of security info :\033[m"
    cat /tmp/updatasec
  elif [ $linec -eq 0 ]; then
    echo -e "\033[1;32;40m This system  is not need updata of security!\033[m"
  fi
  rm /tmp/updatasec
  echo -e "\033[1;31;40m End check updata of security.................\033[m"
}

check-kernel-chklist()
{
  # SYN flood attack protection
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++check-kernel-chklist++++++++++++++++++++++++++++++++++++++++++++++++"
  syncookret=`sysctl -a 2>/dev/null | grep "net.ipv4.tcp_syncookies"  | awk '{print $3}'`
  if [ $syncookret -eq 1 ]; then
    echo -e "\033[1;32;40m net.ipv4.tcp_syncookies set is ok.\033[m"
  else
    echo "\033[1;31;40m net.ipv4.tcp_syncookies set is 0.\033[m"
  fi
  # Check if files were orphange
  echo "--------------------------------------------------------Check orphange files list----------------------------------------------"
  find / -path /proc -prune -o -nouser -o -nogroup
  # List which users are unavailable 
  echo "------------------------------------------------------List which users are unavailable-----------------------------------------"
  grep -v ':x:' /etc/passwd
  # List expired passwords:
  echo "=====================================================List expired passwords===================================================="
  cat /etc/shadow | cut -d: -f 1,2 | grep '!'
  # Files with suid or sgid flags:
  echo "===================================================Files with suid or sgid flags list begin===================================="
  find / -xdev -user root \( -perm -4000 -o -perm -2000 \)
  echo "====================================================Files with suid or sgid flags list end====================================="
}

echo "Usage: ./check-elffile-kernel.sh"

# check all elf file of system 
checkallelffile()
{
  if [ -f $ELFFILELISTFILE ]; then
    :
  else
    ELFFILELISTFILE=$ELFFILELISTFILE_CI
  fi
  echo "-----------------------------------------------------------checkallelffile----------------------------------------------------------"
  if [ "$ELFCHECKOPTION" != "all" ]; then
    while read file
    do
      if [ -f $file ]; then
        if [ -f $CHECKSEC ]; then
          $CHECKSEC -f $file
        else
          $CHECKSEC_CI -f $file
        fi
      else
        echo "$file not exist!"
      fi
    done < $ELFFILELISTFILE
  else 
    for p in `echo $ELFPATH | tr : ' '`; 
    do 
      echo "Check executable dir: $p"
      if [ -f $CHECKSEC ]; then
        $CHECKSEC -d $p
      else
        $CHECKSEC_CI -d $p
      fi
    done
  fi
}
echo "check security update:"
check-security-update
checkallelffile 
check-kernel-chklist
# check kernel
echo "============================================================Check kernel============================================================== "
if [ -f $CHECKSEC ]; then
  $CHECKSEC -k
else
  $CHECKSEC -k
fi
