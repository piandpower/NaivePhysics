#!/bin/bash
#
# Setup environment to run the NaivePhysics project. Setup torch, uetorch, and Lua path

export NAIVEPHYSICS_ROOT=/home/mbernard/dev/naive_physics/NaivePhysics
export UNREALENGINE_ROOT=$(readlink -f $NAIVEPHYSICS_ROOT/../UnrealEngine)

. $NAIVEPHYSICS_ROOT/../torch/install/bin/torch-activate
source $UNREALENGINE_ROOT/Engine/Plugins/UETorch/uetorch_activate.sh > /dev/null
LUA_PATH="$NAIVEPHYSICS_ROOT/Scripts/?.lua;$LUA_PATH"

export NAIVEPHYSICS_BINARY=$NAIVEPHYSICS_ROOT/Package/LinuxNoEditor/NaivePhysics/Binaries/Linux/NaivePhysics

alias naive_editor="$UNREALENGINE_ROOT/Engine/Binaries/Linux/UE4Editor $NAIVEPHYSICS_ROOT/NaivePhysics.uproject"
