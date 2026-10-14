import threading, queue, time
import numpy as np
import serial
import sounddevice as sd
from rtlsdr import RtlSdr

PORT, BAUD = "/dev/ttyUSB1", 5_000_000      
FC, FS_IN, SDR_GAIN = 90.3e6, 250_000, 30
AUDIO_FS = 50_000                           # 250 kS/s / 5
VOL = 1.0                               
PREBUF_S = 0.2                              # audio buffered before playback starts
MAXBUF = 2 * AUDIO_FS                       #max audio buffer size 

ser = serial.Serial(PORT, BAUD, timeout=0.1)
ser.reset_input_buffer()

tx_q = queue.Queue(maxsize=64)
rx_buf, rx_lock, stop = bytearray(), threading.Lock(), threading.Event()
stats = dict(tx=0, rx=0, under=0, qdrop=0, bufdrop=0)


sdr = RtlSdr()
sdr.sample_rate, sdr.center_freq, sdr.gain = FS_IN, FC, SDR_GAIN


def sdr_cb(data, ctx):
    try:
        tx_q.put_nowait(bytes(data))
    except queue.Full:
        stats["qdrop"] += 1

def sdr_thread():
    sdr.read_bytes_async(sdr_cb, 16384)      # blocks until cancel_read_async()

def writer():
    while not stop.is_set():
        try:
            b = tx_q.get(timeout=0.1)
        except queue.Empty:
            continue
        ser.write(b)
        stats["tx"] += len(b)


def reader():
    while not stop.is_set():
        b = ser.read(max(1, ser.in_waiting))
        if not b:
            continue
        with rx_lock:
            rx_buf.extend(b)
            stats["rx"] += len(b)
            excess = len(rx_buf) - MAXBUF
            if excess > 0:                   # drop an even count to keep 2-byte alignment
                del rx_buf[:excess + (excess & 1)]
                stats["bufdrop"] += 1


def audio_cb(outdata, frames, t, status):
    global dc
    need = 2 * frames
    with rx_lock:
        if len(rx_buf) < need:
            chunk = None
        else:
            chunk = bytes(rx_buf[:need])
            del rx_buf[:need]
    if chunk is None:
        outdata[:] = 0
        stats["under"] += 1
        return
    x = np.frombuffer(chunk, "<i2").astype(np.float32) / 32768.0
    outdata[:, 0] = np.clip(x * VOL, -1.0, 1.0)

for fn in (sdr_thread, writer, reader):
    threading.Thread(target=fn, daemon=True).start()

try:
    while len(rx_buf) < PREBUF_S * AUDIO_FS * 2:
        time.sleep(0.01)
    with sd.OutputStream(samplerate=AUDIO_FS, channels=1, dtype="float32",
                         blocksize=1024, callback=audio_cb):
        last = dict(stats)
        while True:
            time.sleep(1)
            d = {k: stats[k] - last[k] for k in ("tx", "rx")}
            last = dict(stats)
            print(f"in {d['tx']/1e3:.0f} kB/s  out {d['rx']/1e3:.0f} kB/s  "
                  f"buf {len(rx_buf)/2/AUDIO_FS*1e3:.0f} ms  "
                  f"underruns {stats['under']}  q-drops {stats['qdrop']}  buf-drops {stats['bufdrop']}")
except KeyboardInterrupt:
    pass
finally:
    stop.set()
    sdr.cancel_read_async()
    sdr.close()
    ser.close()
