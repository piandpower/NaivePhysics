#!/bin/bash
#
# Copyright 2016 Mario Ynocente Castro, Mathieu Bernard
#
# You can redistribute this file and/or modify it under the terms of
# the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

#
# This is the installation script of the NaivePhysics data generator
# (optimized for Debian jessie)
#

export NAIVEPHYSICS_ROOT=$(readlink -f .)
[ ! -f $NAIVEPHYSICS_ROOT/build_package.sh ] \
    && echo "Error: build_package.sh not found, are you in the NaivePhysics directory?" \
    && exit 1

export UNREALENGINE_ROOT=$NAIVEPHYSICS_ROOT/UnrealEngine
TORCH_ROOT=$NAIVEPHYSICS_ROOT/torch


# echo "Step 1: setup Torch and Lua"

git clone --branch master --depth 1 git@github.com:torch/distro.git $TORCH_ROOT
cd $TORCH_ROOT
bash install-deps
TORCH_LUA_VERSION=LUA52 ./install.sh -s
source $TORCH_ROOT/install/bin/torch-activate
luarocks install lua-cjson
luarocks install paths
luarocks install luaposix


echo "Step 2: setup Unreal Engine and UETorch"

# Because /UnrealEngine/Engine/Build/BatchFiles/Linux/Setup.sh lack of
# Debian support, we install required dependencies here if on Debian
if [ -e /etc/os-release ]; then
    source /etc/os-release
    if [[ "$ID" == "debian" ]]; then
        DEPS="mono-xbuild \
       mono-dmcs \
       libmono-microsoft-build-tasks-v4.0-4.0-cil \
       libmono-system-data-datasetextensions4.0-cil
       libmono-system-web-extensions4.0-cil
       libmono-system-management4.0-cil
       libmono-system-xml-linq4.0-cil
       libmono-corlib4.5-cil
       libmono-windowsbase4.0-cil
       libmono-system-io-compression4.0-cil
       libmono-system-io-compression-filesystem4.0-cil
       libmono-system-runtime4.0-cil
       mono-devel
       clang
       "

        for DEP in $DEPS; do
            if ! dpkg -s $DEP > /dev/null 2>&1; then
                echo "Attempting installation of missing package: $DEP"
                set -x
                sudo apt-get install -y $DEP
                set +x
            fi
        done

    fi
fi


# clone only branch 4.13 to save space and bandwidth
git clone --branch 4.13 --depth 1 git@github.com:EpicGames/UnrealEngine.git $UNREALENGINE_ROOT
cd $UNREALENGINE_ROOT
git clone git@github.com:bootphon/UETorch.git Engine/Plugins/UETorch
Engine/Plugins/UETorch/Setup.sh
./Setup.sh
./GenerateProjectFiles.sh
make  # this takes a while...
source $UNREALENGINE_ROOT/Engine/Plugins/UETorch/uetorch_activate.sh
cd $NAIVEPHYSICS_ROOT


echo "Step 3: write the activate-naivephysics script and add it in your ~/.bashrc"
cat > activate-naivephysics << EOF
#!/bin/bash
#
# Setup environment to run the NaivePhysics project.
# Load torch and uetorch, update the Lua path.

export NAIVEPHYSICS_ROOT=$NAIVEPHYSICS_ROOT
export UNREALENGINE_ROOT=$UNREALENGINE_ROOT

source \$NAIVEPHYSICS_ROOT/torch/install/bin/torch-activate
source \$UNREALENGINE_ROOT/Engine/Plugins/UETorch/uetorch_activate.sh > /dev/null

LUA_PATH="\$NAIVEPHYSICS_ROOT/UnrealProject/Scripts/?.lua;\$LUA_PATH"

export NAIVEPHYSICS_BINARY=\$NAIVEPHYSICS_ROOT/UnrealProject/Package/LinuxNoEditor/NaivePhysics/Binaries/Linux/NaivePhysics

EOF

source $NAIVEPHYSICS_ROOT/activate-naivephysics
echo "source $NAIVEPHYSICS_ROOT/activate-naivephysics" >> ~/.bashrc


echo "Step 4: packaging the NaivePhysics Unreal project"
./build_package.sh


echo "
Successful installation of the Unreal Engine with UETorch.

Please source ~/.bashrc to activate your NaivePhysics environment.

"
