NAIVEPHYSICS=/home/mbernard/dev/NaivePhysics-4.8

# building an html page from gif files
html: data
	./build_html.sh $< $@

# generate data in gif and avi from config file
data: config.json
	$(NAIVEPHYSICS)/naivedata.py $< $@ -f
	$(NAIVEPHYSICS)/images2video.sh $@ -gif
	$(NAIVEPHYSICS)/images2video.sh $@

clean:
	rm -rf html
