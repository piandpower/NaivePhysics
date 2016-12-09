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
# Convert the jpeg files in a directory (and recursivly in
# subdirectories) into a video or into a gif (one video per
# directory).
#

# display a usage message if bad params
[ $# -lt 1 ] \
    && echo "Usage: $0 <directory> [--gif]" \
    && echo "Find subdirectories of <directory> which contain png files and \
convert them to video (or gif if the --gif option is specified as second \
argument). Create one video in each subdirectory." \
    && exit 0


# remove any trailing slash and make it absolute
data_dir=$(readlink -f ${1%/})

# output format is either "video" or "gif" (if --gif specified to $2)
if [[ "$2" == *gif* ]]; then
    format="gif"

    # make sure convert is installed (for gif conversion)
    [ -z $(which convert 2> /dev/null) ] \
        && echo "Error: convert not installed on your system." \
        && echo "Please run 'sudo apt-get install imagemagick'" \
        && exit 1

    # generate a black image to be inserted at the beginning and end
    # of each gif, delete it at exit
    convert -size 512x288 xc:black black.png
    trap "rm -rf black.png" EXIT
else
    format="video"

    # make sure avconv is installed (for avi conversion)
    [ -z $(which avconv 2> /dev/null) ] \
        && echo "Error: avconv not installed on your system." \
        && echo "Please run 'sudo apt-get install libav-tools'" \
        && exit 1
fi

# display error message if input is not a directory
[ ! -d "$data_dir" ] && echo "Error: $data_dir is not a directory"  && exit 1

# list all subdirectories containing at least one jpeg file
png_dirs=$(find $data_dir -type f -name "*.png" -exec dirname {} \; | uniq)

# display error message if no png found
[ -z "$png_dirs" ] && echo "Error: no png file in $data_dir" && exit 1

# process each png directory
for dir in $png_dirs;
do
    # list all png images in the directory
    png=$(ls $dir/*.png 2> /dev/null)

    # get the first png file in the list
    first=$(echo $png | cut -f1 -d' ')

    # find the length of the images index (just consider the first png, we
    # assume they all have same index length)
    index=$(echo $first | sed -r 's|^.+_([0-9]+)\.png$|\1|g')
    n=${#index}

    # png files basename, with extension and index removed
    base=$(basename $first | sed -r 's|^(.+_)[0-9]+\.png$|\1|g')

    case $format in
        "video"*)
            # the global pattern matching png files for avconv
            pattern=$(echo $dir/$base%0${n}d.png)

            # convert the png images into a video.avi
            avconv -y -framerate 24 -i $pattern -c:v libx264 -r 30 -pix_fmt yuv420p $dir/video.avi \
                || (echo "Error: failed to write video from $pattern"; exit 1)
            echo "Wrote $dir/video.avi"
            ;;
        "gif"*)
            # convert the png sequence to a video.gif (with black at
            # begin and end of the animation)
            convert -delay 10 -loop 0 black.png $dir/*.png black.png $dir/video.gif
            echo "Wrote $dir/video.gif"
            ;;
    esac
done

exit 0
