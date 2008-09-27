#!/usr/bin/env python
#
# Arnaud Guignard - 2008
#
# Generates mime types configuration for lighttpd

from __future__ import with_statement

import sys

if len(sys.argv) == 1:
    print 'usage: confmimetype.py /path/to/mime.types'
    sys.exit(1)

print 'mimetype.assign = ('

with open(sys.argv[1]) as f:
    d = {}
    for l in f:
        l = l.strip()
        if not l or l.startswith('#'):
            continue
        t = l.split()
        for e in t[1:]:
            d[e] = t[0]
    for (ext, mime) in d.items():
        print '    ".%s" => "%s",' % (ext, mime)

# default mime type
print '    "" => "application/octet-stream",'
print ')'

# vim: et sw=4 ts=4
