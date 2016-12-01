#!/bin/bash
#
# Usage: test_naive.sh [seed=1]


# setup output directory
test_dir=./data_test
rm -rf $test_dir
mkdir -p $test_dir

# setup config file
cat > $test_dir/config.json <<EOF
{
    "blockC1_dynamic_1" :
    {
        "train": 0,
        "test": 1
    }
}
EOF

# generate images
./naivedata.py $test_dir/config.json $test_dir/data --seed ${1:-1} || exit -1

# make them gif videos
./images2video.sh $test_dir/data --gif

# get the list of gif files and put them in a markdown
rm -f $test_dir/test.md
for type in "scene" "mask"
do
    for gif in $(find $test_dir/data -type f -name *.gif -exec readlink -f {} \; \
                        | grep $type | sort)
    do
        echo -e "<img src=\"$gif\" width=\"256\">" >> $test_dir/test.md
    done
    echo -e "\n" >> $test_dir/test.md
done

# make an html page*
markdown $test_dir/test.md > $test_dir/test.html
