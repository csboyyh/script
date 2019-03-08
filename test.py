#!/usr/bin/python

import struct

chunkID   = 'RIFF';
chunkSize =  total_size - 8;
ftype     = 'WAVE';

scId      =  'fmt ';
scSize    = 0x10;
sctag     = 1;
scchnl    = channels;
scSampeRate    = sample_rate;
scBytePerSec   = sampleRate * (bitsPerSample / 8) * channels;
scBlockAlign   = bitsPerSample * channels / 8;
scBitPerSample = bitsPerSample;

sdId      = 'data';
sdSize    = total_size;


bytes=struct.pack('4si4s4sihh',a,b,c,d)
file = open("test.wav","w");
file.write(bytes);
print b
