#!/bin/bash

# remove temp files at exit
trap "rm -f gifs train test meta md" EXIT


##
## parameters
##

# argument parsing
[ ! $# -eq 2 ] && echo "Usage: $0 <data-directory> <html-directory>" && exit 1
data_dir=$(readlink -f $1)
html_dir=$(readlink -f $2)

# width of each image in pixels
width=256


##
## selection of random samples
##

# get the list of gif files in data_dir
find $data_dir -type f -name *.gif -exec readlink -f {} \; > gifs


# select train exemples (scene only, 8 random videos)
cat gifs | grep scene | grep train | sort -R | head -12 > train


# select test exemple (scene only, 1 random static)
sample=$(cat gifs | grep scene | grep test | sed -r 's|^(.*)/[0-9]+/scene/video.gif$|\1|' | \
              uniq | grep static | sort -R | head -1)
find $sample -type f -name video.gif | grep scene | sort > test

# select test exemple (scene only, 1 random dynamic1)
sample=$(cat gifs | grep scene | grep test | sed -r 's|^(.*)/[0-9]+/scene/video.gif$|\1|' | \
                uniq | grep dynamic_1 | sort -R | head -1)
find $sample -type f -name video.gif | grep scene | sort >> test

# select test exemple (scene only, 1 random dynamic2)
sample=$(cat gifs | grep scene | grep test | sed -r 's|^(.*)/[0-9]+/scene/video.gif$|\1|' | \
              uniq | grep dynamic_2 | sort -R | head -1)
find $sample -type f -name video.gif | grep scene | sort >> test


# select random videos with depth and mask (two train)
samples=$(cat gifs | grep scene | grep train | sort -R | head -2)
for sample in $samples
do
    echo $sample >> meta
    echo $sample | sed -r 's|^(.*/)scene(/video.gif)$|\1depth\2|' >> meta
    echo $sample | sed -r 's|^(.*/)scene(/video.gif)$|\1mask\2|' >> meta
done


##
## generation of markdown code
##

mkdir -p $html_dir/gif
mkdir -p $html_dir/avi

cp template.md md

# setup train exemples
train_files=""
i=0
while read source
do
    i=$(($i + 1))
    target=$html_dir/gif/train_$i.gif
    cp $source $target
    cp ${source//gif/avi} ${target//gif/avi}

    [ $(( $i % 4 )) == 1 ] && train_file="$train_file\n"
    train_file="$train_file <img src=\"$target\" width=\"$width\">\n"
done < train
sed -i "s|@@TRAIN@@|$train_file|" md

# setup test exemples
test_files=""
i=0
while read source
do
    i=$(($i + 1))
    target=$html_dir/gif/test_$i.gif
    cp $source $target
    cp ${source//gif/avi} ${target//gif/avi}

    [ $(( $i % 4 )) == 1 ] && test_file="$test_file\n"
    test_file="$test_file <img src=\"$target\" width=\"$width\">\n"
done < test
sed -i "s|@@TEST@@|$test_file|" md

# setup meta exemples
meta_files=""
i=0
while read source
do
    i=$(($i + 1))
    target=$html_dir/gif/meta_$i.gif
    cp $source $target
    cp ${source//gif/avi} ${target//gif/avi}

    [ $(( $i % 3 )) == 1 ] && meta_file="$meta_file\n"
    meta_file="$meta_file <img src=\"$target\" width=\"$width\">\n"
done < meta
sed -i "s|@@META@@|$meta_file|" md


##
## generation of html source
##

mkdir -p $html_dir
markdown md > $html_dir/naivephysics.html
