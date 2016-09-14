#!/bin/sh

i=50

mkdir "testing"

while [ $i -lt 101 ]
do
	mkdir "testing/$i"
	k=1
	while [ $k -lt 5 ]
	do
		j=1
		while [ $j -lt 100 ]
		do
			origin="data/$i/screen_$j""_$k.jpg"
			destination="testing/$i/screen_$j""_$k.jpg"
			cp $origin $destination
			j=`expr $j + 1`
		done
		k=`expr $k + 1`
	done
	i=`expr $i + 1`
done
