#
# Copyright 2016-2018, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# pmempool_sync/TEST11w -- test for checking pmempool sync
#                          check for healthy replicas cycles
#
[CmdletBinding(PositionalBinding=$false)]
Param(
    [alias("d")]
    $DIR = ""
    )

. ..\unittest\unittest.ps1

require_test_type medium
require_fs_type any

setup

$LOG = "out${Env:UNITTEST_NUM}.log"
$LOG_TEMP = "out${Env:UNITTEST_NUM}_part.log"
rm $LOG -Force -ea si
touch $LOG
rm $LOG_TEMP -Force -ea si
touch $LOG_TEMP

$LAYOUT = "OBJ_LAYOUT${Env:SUFFIX}"
$POOLSET1 = "$DIR\poolset1"
$POOLSET2 = "$DIR\poolset2"
$POOLSET3 = "$DIR\poolset3"

# Create poolset files
create_poolset $POOLSET1 `
	10M:$DIR\part00:x `
	r `
	10M:$DIR\part10:x

create_poolset $POOLSET2 `
	10M:$DIR\part20:x

create_poolset $POOLSET3 `
	10M:$DIR\part00:x `
	r `
	10M:$DIR\part10:x `
	r `
	10M:$DIR\part20:x


# Log poolset structures
echo poolset1: >> $LOG_TEMP
cat $POOLSET1 >> $LOG_TEMP
echo poolset2: >> $LOG_TEMP
cat $POOLSET2 >> $LOG_TEMP
echo poolset3: >> $LOG_TEMP
cat $POOLSET3 >> $LOG_TEMP

# Create poolsets
expect_normal_exit $PMEMPOOL create --layout=$LAYOUT obj $POOLSET1
cat $LOG >> $LOG_TEMP
expect_normal_exit $PMEMPOOL create --layout=$LAYOUT obj $POOLSET2
cat $LOG >> $LOG_TEMP

# Spoil the first and the third replicas
rm $DIR\part00 -Force -ea si
rm $DIR\part20 -Force -ea si

# Try to synchronize replicas using the second poolset
expect_abnormal_exit $PMEMPOOL sync $POOLSET3 >> $LOG_TEMP 2>$null

mv -Force $LOG_TEMP $LOG
check

pass
