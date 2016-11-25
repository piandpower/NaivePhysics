#!/bin/bash


# setup output directory
test_dir=./data_test
rm -rf $test_dir
mkdir -p $test_dir

# setup config file
cat > $test_dir/config.json <<EOF
{
    "blockC1_static" :
    {
        "train": 1,
        "test": 0
    }
}
EOF

# generate images
./naivedata.py $test_dir/config.json $test_dir/data --seed ${1:-2}

# make them gif videos
./images2video.sh $test_dir/data --gif

# get the list of gif files an d put them in a markdown
for gif in $(find $test_dir/data -type f -name *.gif -exec readlink -f {} \;)
do
    echo -e "<img src=\"$gif\" width=\"512\">\n$gif\n\n" >> $test_dir/test.md
done

# make an html page
markdown $test_dir/test.md > $test_dir/test.html
