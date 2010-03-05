#!/usr/bin/env python
#
# Arnaud Guignard - 2008-2009
#
# usage: clean_id3v2.py dir1 <dir2 .. dirN>
#
# dependencies: eyeD3
#
# Forces id3v2.3 tags and removes tags which prevent the Sansa
# Fuze to read tags correctly.

import os
import sys

import eyeD3

def main(all_dirs):
    t = eyeD3.Tag()
    for dir in all_dirs:
        for root, dirs, files in os.walk(dir):
            print "===>", root
            for f in files:
                fp = os.path.join(root, f)
                if eyeD3.isMp3File(fp):
                    t.link(fp, eyeD3.ID3_V2)
                    t.frames.removeFramesByID('TPE2')
                    t.frames.removeFramesByID('TDAT')
                    t.frames.removeFramesByID('TPUB')
                    t.update(eyeD3.ID3_V2_3)
                else:
                    print f

if __name__ == '__main__':
    if len(sys.argv) == 1:
        print 'usage: %s dir1 <dir2 .. dirN>' % os.path.basename(sys.argv[0])
        sys.exit(1)
    main(sys.argv[1:])

# vim: set et sw=4 ts=4:
