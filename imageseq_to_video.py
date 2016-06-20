import cv2

path = "data/1/"
suffix = "_screen"
width, height = 1128, 555
fps = 24

video = cv2.VideoWriter(path + 'video.avi', cv2.cv.CV_FOURCC('M','J','P','G'), fps, (width,height))

pos = 1

while True:
	name = path + str(pos) + suffix + '.jpg'
	img = cv2.imread(name)
	
	if img is None:
		break

	video.write(img)
	pos += 1

video.release()