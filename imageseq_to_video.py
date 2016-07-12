import cv2

path = "data/"
prefix = "screen_"
width, height = 1128, 555
fps = 24

ndata = 12

for i in range(1,1 + ndata):
	tuple_pos = 0

	while True:
		name = path + str(i) + "/" + prefix + "1_" + str(tuple_pos) + ".jpg"
		img = cv2.imread(name)

		if img is None:
			break

		video = cv2.VideoWriter(path + '/video_' + str(i) + "_" + str(tuple_pos) + '.avi', cv2.cv.CV_FOURCC('M','J','P','G'), fps, (width,height))
		pos = 1

		while True:
			name = path + str(i) + "/" + prefix + str(pos) + "_" + str(tuple_pos) + '.jpg'
			img = cv2.imread(name)

			if img is None:
				break

			video.write(img)
			pos += 1

		video.release()
		tuple_pos += 1