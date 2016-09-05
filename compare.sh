#!/bin/sh

i=1

while [ $i -lt 16 ]
do
	cur=0

	while [ $cur -lt 3 ]
	do
		#echo "data/$i/data_$cur.txt"
		next=`expr $cur + 1`
		if diff -q "data/$i/data_$cur.txt" "data/$i/data_$next.txt" > /dev/null; then
		    : # files are the same
		else
		    echo "$i : $cur and $next differ"
		fi
		cur=`expr $cur + 1`
	done
	i=`expr $i + 1`
done
