import cv2

path = "data/"
suffix = "_screen"
width, height = 1171, 584
fps = 24

ndata = 12

for i in range(1,1 + ndata):
	video = cv2.VideoWriter(path + '/video' + str(i) + '.avi', cv2.cv.CV_FOURCC('M','J','P','G'), fps, (width,height))
	pos = 1

	while True:
		name = path + str(i) + "/" + str(pos) + suffix + '.jpg'
		img = cv2.imread(name)

		if img is None:
			break

		video.write(img)
		pos += 1

	video.release()