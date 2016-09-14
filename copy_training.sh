#!/bin/sh

i=1

mkdir "training"

while [ $i -lt 51 ]
do
	mkdir "training/$i"
	k=1
	while [ $k -lt 3 ]
	do
		j=1
		while [ $j -lt 100 ]
		do
			origin="data/$i/screen_$j""_$k.jpg"
			destination="training/$i/screen_$j""_$k.jpg"
			cp $origin $destination
			j=`expr $j + 1`
		done
		k=`expr $k + 1`
	done
	i=`expr $i + 1`
done
