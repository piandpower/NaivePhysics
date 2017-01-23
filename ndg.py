from scipy import misc

im_file = './data/train/1_blockC1_train/mask/mask_100.png'
im = misc.imread(im_file)
print set(im.flatten())
