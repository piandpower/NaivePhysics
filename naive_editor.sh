#!/bin/bash
#
# Run the NaivePhysics project within the UE4Editor, and define the
# required environment variable for the program to be run within the
# editor. This script assumes activate-naivephysics has been run.


# Setup the output data directory

NAIVEPHYSICS_DATA=${1:-data}
NAIVEPHYSICS_DATA=$(readlink -f $NAIVEPHYSICS_DATA)/  # trailing slash matters

if [ -d $NAIVEPHYSICS_DATA ]; then
    echo "WARNING: Directory exists $NAIVEPHYSICS_DATA"
else
    mkdir -p $NAIVEPHYSICS_DATA
fi

export NAIVEPHYSICS_DATA=$NAIVEPHYSICS_DATA


# Setup the input configuration file
NAIVEPHYSICS_JSON=${2:-config.json}
NAIVEPHYSICS_JSON=$(readlink -f $NAIVEPHYSICS_JSON)

if [ ! -f $NAIVEPHYSICS_JSON ]; then
    echo "ERROR: File doesn't exist $NAIVEPHYSICS_JSON"
    exit 1
fi

export NAIVEPHYSICS_JSON=$NAIVEPHYSICS_JSON

cd $UNREALENGINE_ROOT
$UNREALENGINE_ROOT/Engine/Binaries/Linux/UE4Editor \
    $NAIVEPHYSICS_ROOT/UnrealProject/NaivePhysics.uproject
