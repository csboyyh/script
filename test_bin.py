#!/usr/bin/python

import struct

fmt  = 'fmt';
size = 100;
rate = 44100

bytes = struct.pack(">3shi",fmt,size,rate);

file = open("bin.test","w");

file.write(bytes);
