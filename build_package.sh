#!/bin/bash
#
# Build (or rebuild) the NaivePhysics.uproject into a standalone
# binary. The UNREALENGINE_ROOT and NAIVEPHYSICS_ROOT variable are set
# in the activate-naivephysics script. See
# https://wiki.unrealengine.com/Cooking_On_Linux

mkdir -p $NAIVEPHYSICS_ROOT/UnrealProject/Package/

cd $UNREALENGINE_ROOT/Engine/Build/BatchFiles

./RunUAT.sh BuildCookRun \
            -project="$NAIVEPHYSICS_ROOT/UnrealProject/NaivePhysics.uproject" \
            -noP4 -platform=Linux -clientconfig=Development -serverconfig=Development \
            -cook -allmaps -build -stage -pak -archive \
            -archivedirectory="$NAIVEPHYSICS_ROOT/UnrealProject/Package/"

cd -
