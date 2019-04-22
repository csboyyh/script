#!/usr/bin/python

import sys,os

def add_wav_header(sample_rate,channel_count,bit_deep,pcm_file)
try:
  size = os.path.getsize(pcm_file);
  print(pcm_file" size:",size);
except Exception as err:
  print(err);
  return;
  
  ckId   = 'RIFF';
  ckSize = size + 44 - 8;
  ctype  = 'WAVE';

  sId      = 'fmt ';
  sSize    = 0x10;
  stag     = 1;
  sChnl    = channel_count;
  sSampleR = sample_rate;
  sBytePS  = sample_rate * (bit_deep / 8) * channel_count;
  sBlockA  = bit_deep * channel_count / 8;
  sBitD    = bit_deep;

  dId      = 'data';
  dSize    = size;
  
  os.copy(pcm_file,pcm_file+".wav");

  dst_file = open(pcm_file+".wav","w");
  wavHeader= struct.pack(">4sI4s4sIHHIIHH4sI",ckId,ckSize,
                        ctype,sId,sSize,stag,sChnl,sSampleR,sBytePS,
                        sBlockA,sBitD,dId,dSize);
  dst_file.write(dst_file)

def resample_wav(wav_source,wav_dst,dst_rate)
  

