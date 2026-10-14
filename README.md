# FPGA FM Demodulator

Real-time FM demodulation on an FPGA. IQ samples from an RTL-SDR are streamed
from a PC over UART (5 Mbaud), demodulated with a CORDIC phase detector,
low-pass filtered/decimated with a FIR, and sent back to the PC as audio.
Tested on a Basys 3.


