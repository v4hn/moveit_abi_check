#!/bin/bash
# Copyright (c) 2017, Michael Goerner <me@v4hn.de>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the <organization> nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -o errexit

cleanup(){
    rm -rf build devel install
}

create_dumps(){
    catkin_make install -DCMAKE_BUILD_TYPE=Debug -DCATKIN_ENABLE_TESTING=0 -DCMAKE_CXX_FLAGS="-Og"

    mkdir $1.dumps
    for lib in $(ls install/lib/*.so); do
        abi-dumper $lib -o $1.dumps/$(basename $lib).dump -lver $1
    done
}

REPOSITORIES="$(ls src/ | grep -v CMakeLists.txt)"

for repo in $REPOSITORIES; do
    pushd src/$repo >/dev/null
    previous_release=$(git describe --tags --abbrev=0 HEAD^)
    echo "$repo - comparing ${previous_release} to $(git rev-parse --abbrev-ref HEAD)"
    eval "prev_$repo=${previous_release}"
    eval "curr_$repo=$(git rev-parse HEAD)"
    popd >/dev/null
done

echo
echo "Is that correct? Press Enter to continue"
read

cleanup

echo
echo "*** Create new API/ABI dumps ***"
echo

( [[ -d new.dumps ]] && echo "*** Already present ***" || create_dumps new )

cleanup

echo
echo "*** Checkout previous repository versions ***"
echo

for repo in $REPOSITORIES; do
        pushd src/$repo >/dev/null
        prev=prev_${repo}
        git checkout ${!prev}
        popd >/dev/null
done

echo
echo "*** Create old API/ABI dumps ***"
echo

( [[ -d old.dumps ]] && echo "*** Already present ***" || create_dumps old )

echo
echo "*** Restore repository checkouts ***"
echo

for repo in $REPOSITORIES; do
        pushd src/$repo >/dev/null
        curr=curr_${repo}
        git checkout ${!curr}
        popd >/dev/null
done

echo
echo "*** Generating Reports ***"
echo

for dump in libmoveit_trajectory_processing.so.dump; do # $(ls new.dumps/); do
    libname=$(echo $dump | sed 's:lib\(.*\).so.dump:\1:') &&
    if ! abi-compliance-checker -l $libname -old old.dumps/$dump -new new.dumps/$dump > tmp.log; then
        echo "*********** Report states $libname is INCOMPATIBLE *************"
        grep -A4 INCOMPATIBLE tmp.log
    fi
done

rm tmp.log
