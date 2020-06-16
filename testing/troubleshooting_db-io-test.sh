#!/bin/bash

#---------------------------------------------------------------------------------------------
#
#      Copyright (c) 2020, Avocent, Vertiv Infrastructure Ltd.
#      All rights reserved.
#
#      Redistribution and use in source and binary forms, with or without
#      modification, are permitted provided that the following conditions are met:
#      1. Redistributions of source code must retain the above copyright
#         notice, this list of conditions and the following disclaimer.
#      2. Redistributions in binary form must reproduce the above copyright
#         notice, this list of conditions and the following disclaimer in the
#         documentation and/or other materials provided with the distribution.
#      3. All advertising materials mentioning features or use of this software
#         must display the following acknowledgement:
#         This product includes software developed by the Emerson Electric Co.
#      4. Neither the name of the Emerson Electric Co. nor the
#         names of its contributors may be used to endorse or promote products
#         derived from this software without specific prior written permission.
#
#      THIS SOFTWARE IS PROVIDED BY VERTIV INFRASTRUCTURE LTD ''AS IS'' AND ANY
#      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#      DISCLAIMED. IN NO EVENT SHALL VERTIV INFRASTRUCTURE LTD BE LIABLE FOR ANY
#      DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#      (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#      LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#      ON ANY THEORY OF LIABILITY, WHOS_NIC_NAMEER IN CONTRACT, STRICT LIABILITY, OR TORT
#      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
# Script Name: troubleshooting_db-io.sh
# Description: Prepares and runs Oracle Orion test script on a RHEL/CentOS/OEL 6.x/7.x host 
#              for simulating database performance with Trellis(tm) Enterprise installation.
# Created: 2020/04/15
# Modified: 2020/04/15
# Authors: Scott Donaldson [VERTIV/AVOCENT/UK]
# Contributors:
# Company: Vertiv Infrastructure Ltd.
# Group: Software Delovery, Services
# Email: global.services.delivery.development@vertivco.com
#---------------------------------------------------------------------------------------------


#
#  Global Variables
#
ENV_CURRENT_USER=`whoami`
ENV_REAL_USER=`who am i | awk '{print $1}'`
ENV_HOSTNAME=`hostname`
ENV_ORIGIN_FOLDER=`pwd`

DD_PARAM_FLUSHED="bs=8k count=100k conv=fdatasync"
DD_PARAM_CACHED="bs=8k count=100k"
DD_OUTFILE="/tmp/output.img"
SCRIPT_VERSION="0.0.1"

CFG_OUTPUT_FOLDER="~${ENV_REAL_USER}"
CFG_OUTPUT_TMP_FOLDER="/tmp"
CFG_LOGFILE="trellis-precheck_${ENV_HOSTNAME}_`date +"%Y%m%d-%H%M"`.log"
CFG_LOGFILE_PATH="${CFG_OUTPUT_TMP_FOLDER}/${CFG_LOGFILE}"
CFG_OUTPUT_BUNDLE_FOLDER="${CFG_OUTPUT_TMP_FOLDER}/trellis_config"

ORACLE_HOME=/u01/app/oracle/product/12.1.0.2
ORACLE_LUNS=/u02/app/oracle/oradata/luns
TEST_BLOCKS=1024
TEST_BLOCK_SZ=1024k
TEST_FILES=( "lun1" "lun2" "lun3" "lun4" )
TEST_NAME=baseline
TEST_CONF=${ENV_CURRENT_USER}/${TEST_NAME}.lun

true=true
false=false

#
# The following are used for terminal output
#
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
#####

#
#  Save Location
#
pushd /tmp

#
#  Check Running User
#
if [ "$ENV_CURRENT_USER" == "oracle" ]; then
    echo '[Info]: Script launched by oracle user.'> `tty`
else
	echo '[Error]: Script not run by oracle, cannot continue.'> `tty`
	exit 1
fi
#####

cd $ENV_CURRENT_USER
#
#  Check LUN files
#
if [ -d "$ORACLE_LUNS" ]; then
  echo "[Info]: Test directory exists."
else
  echo "[Info]: Creating test directory $ORACLE_LUNS"
  mkdir /u02/app/oracle/oradata/luns
fi

if [ ! -e "/home/oracle/baseline.lun" ]; then
  touch $TEST_CONF
fi
  
cat > $TEST_CONF << EOF
EOF

for FILE in "${TEST_FILES[@]}"
do
  echo "[Debug]: Validating test file ${FILE}"
  if [ ! -f "$FILE" ]; then
    dd if=/dev/zero of=${ORACLE_LUNS}/${FILE} bs=${TEST_BLOCK_SZ} count=${TEST_BLOCKS}
    cat >> $TEST_CONF << EOF
$ORACLE_LUNS/$FILE
EOF
  elif [ ! -O "$FILE" ]; then
    echo "[Info]: File exists and is owned by user."
    cat >> $TEST_CONF << EOF
$ORACLE_LUNS/$FILE
EOF
  else
    echo "[Error]: Unable to process test files."
  fi
done

$ORACLE_HOME/bin/orion -run normal -testname ${TEST_NAME}

echo""
echo "[Info]: Oracle Orion baseline test script has completed."

popd

