import numpy as np
from scipy.signal import kaiserord, firwin, freqz

fs, fpass, fstop, atten = 250e3, 15e3, 25e3, 60     # fstop = 50k - 15k 

numtaps, beta = kaiserord(atten, (fstop - fpass) / (fs / 2))
numtaps |= 1                                         
h = firwin(numtaps, (fpass + fstop) / 2, window=("kaiser", beta), fs=fs) 
print("taps:", numtaps)
a = list(map(lambda x: int(x * 2**15), h))
print(a)
