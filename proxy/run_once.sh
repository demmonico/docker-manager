#!/usr/bin/env bash
#
# This file has executed after container's builds
#
# tech-stack: ubuntu / nginx
#
# @author demmonico
# @image proxy
# @version v3.3



### users

# set root password
echo "root:${DMC_ROOT_PASSWD:-rootPasswd}" | chpasswd

# add dm user, set password
DMC_DM_USER="${DMC_DM_USER:-dm}"
useradd -m ${DMC_DM_USER} && \
    usermod -a -G root ${DMC_DM_USER} && \
    adduser dm sudo && \
    echo "${DMC_DM_USER}:${DMC_DM_PASSWD:-${DMC_DM_USER}Passwd}" | chpasswd



# colored term
VC='\[\033[01;35m\]'
GC='\[\033[01;32m\]'
BC='\[\033[01;34m\]'
NC='\[\033[00m\]'
PS1="PS1='${VC}\t${NC} \${debian_chroot:+(\$debian_chroot)}${GC}\u@\${DMC_EXEC_NAME:-proxy}${NC} ${VC}\h${NC}:${BC}\w${NC}\\$ '"
# prepare to sed
PS1=$( echo ${PS1} | sed 's/\\/\\\\/g' )
# replace colors
declare -a RC_FILES=("/root/.bashrc" "/home/${DMC_DM_USER}/.bashrc")
for RC_FILE in "${RC_FILES[@]}"
do
    START=$( cat ${RC_FILE} | sed "/^# set a fancy prompt/,\$d" )
    END=$( cat ${RC_FILE} | sed "/^# enable color support/,\$!d" )
    echo -e "${START}\n\n# set a fancy prompt\n${PS1}\n\n${END}" > ${RC_FILE}
done



### run custom script if exists
CUSTOM_ONCE_SCRIPT="${DMC_INSTALL_DIR}/custom_once.sh"
if [ -f ${CUSTOM_ONCE_SCRIPT} ]; then
    chmod +x ${CUSTOM_ONCE_SCRIPT} && source ${CUSTOM_ONCE_SCRIPT}
fi
if [ ! -z "${DMC_CUSTOM_RUNONCE_COMMAND}" ]; then
    eval ${DMC_CUSTOM_RUNONCE_COMMAND}
fi
