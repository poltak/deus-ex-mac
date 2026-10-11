# wav-levels.py <file.wav> [seconds for each line]: print the sound level (RMS, in dB below full scale) and the peak of
# each second of a WAV file, with a small bar. A run with no sound gives "silent" for all lines.
import math, struct, sys

def read_wav(path):
    data = open(path, 'rb').read()
    if data[:4] != b'RIFF' or data[8:12] != b'WAVE':
        raise SystemExit('not a WAV file')
    pos = 12; fmt = None; pcm = b''
    while pos + 8 <= len(data):
        tag = data[pos:pos + 4]; size = struct.unpack_from('<I', data, pos + 4)[0]
        body = data[pos + 8:pos + 8 + size] if tag != b'data' else data[pos + 8:]   # a writer that was stopped has a wrong data size
        if tag == b'fmt ':
            fmt = list(struct.unpack_from('<HHIIHH', body))
            if fmt[0] == 0xFFFE and len(body) >= 26:   # WAVE_FORMAT_EXTENSIBLE: the real format is in the sub format
                fmt[0] = struct.unpack_from('<H', body, 24)[0]
        elif tag == b'data':
            pcm = body
            break
        pos += 8 + size + (size & 1)
    return fmt, pcm

fmt, pcm = read_wav(sys.argv[1])
step = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0
kind, channels, rate, _, align, bits = fmt
frames = len(pcm) // align
print(f"{sys.argv[1]}: {channels} channels, {rate} Hz, {bits} bits, {frames / rate:.1f} seconds")
if bits == 16:
    samples = struct.unpack_from('<%dh' % (frames * channels), pcm); scale = 32768.0
elif bits == 32 and kind == 3:
    samples = struct.unpack_from('<%df' % (frames * channels), pcm); scale = 1.0
elif bits == 32 and kind == 1:
    samples = struct.unpack_from('<%di' % (frames * channels), pcm); scale = 2147483648.0
elif bits == 8:
    samples = [b - 128 for b in pcm[:frames * channels]]; scale = 128.0
else:
    raise SystemExit(f'sample format {kind}/{bits} is not supported')
block = int(rate * step) * channels
loud = 0
for i in range(0, len(samples), block):
    part = samples[i:i + block]
    if not part: break
    rms = math.sqrt(sum(s * s for s in part) / len(part)) / scale
    peak = max(abs(s) for s in part) / scale
    if rms < 1e-5:
        text = 'silent'
    else:
        db = 20 * math.log10(rms)
        text = f"{db:6.1f} dB  peak {peak:4.2f}  " + '#' * max(0, int((db + 60) / 2))
        loud += 1
    print(f"{i / channels / rate:6.1f} s  {text}")
print(f"{loud} of {math.ceil(len(samples) / block)} blocks have sound")
