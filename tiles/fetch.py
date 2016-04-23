from mpmath import sec, pi, log, tan
import urllib
import os


def make_dirs(z, x):
    try:
        os.stat("%d/" % z)
    except:
        os.mkdir("%d/" % z)
    try:
        os.stat("%d/%d/" % (z, x))
    except:
        os.mkdir("%d/%d/" % (z, x))


# longitude
left_x = 2.768555
right_x = 7.558594

# latitudes
left_y = 50.439432
right_y = 54.158682

# Zoomlevels
zoom_min = 0
zoom_max = 8

for zoom in range(zoom_min, zoom_max + 1):
    num_tiles = 2 ** zoom
    if zoom > 5:
        x = int(num_tiles * (left_x + 180.0) / 360.0)
        X = int(num_tiles * (right_x + 180.0) / 360.0)
        y = int(num_tiles * (1.0 - log(tan(left_y * pi / 180.0) + sec(left_y * pi / 180.0)) / pi) / 2.0)
        Y = int(num_tiles * (1.0 - log(tan(right_y * pi / 180.0) + sec(right_y * pi / 180.0)) / pi) / 2.0)
    else:
        x = 0
        y = 0
        X = num_tiles - 1
        Y = num_tiles - 1

    y, Y = sorted((y, Y))
    x, X = sorted((x, X))

    for q_x in range(x, X + 1):
        for q_y in range(y, Y + 1):
            filename = "%d/%d/%d.png" % (zoom, q_x, q_y)
            if not os.path.isfile(filename):
                url = "http://a.tile.openstreetmap.org/%d/%d/%d.png" % (zoom, q_x, q_y)
                make_dirs(zoom, q_x)
                testfile = urllib.URLopener()
                testfile.retrieve(url, filename)
