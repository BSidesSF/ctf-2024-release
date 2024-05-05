require 'yaml'

METADATA = YAML::load(File.read(File.join(__dir__, '../metadata.yml')))
CHALLENGE_NAME = File.basename(File.expand_path('..', __dir__))
TOOLS_DIR = File.expand_path('../../../tools', __dir__)

if METADATA['service_from_challenge']
  SERVICE_METADATA = YAML::load(File.read(File.join(__dir__, "../../#{ METADATA['service_from_challenge'] }/metadata.yml")))
else
  SERVICE_METADATA = METADATA
end

if !File.directory?(TOOLS_DIR)
  raise "Couldn't find the tools directory, it should be @ #{ TOOLS_DIR }"
end

def expected_flag
  METADATA['flag']
end

def protocol
  SERVICE_METADATA['protocol']
end

def generate_hostname
  if METADATA['service_from_challenge']
    `python #{ TOOLS_DIR }/get_hostname.py #{ METADATA['service_from_challenge'] }`.chomp
  else
    `python #{ TOOLS_DIR }/get_hostname.py #{ CHALLENGE_NAME }`.chomp
  end
end

def get_host_port
  if protocol() != 'tcp' && protocol() != 'udp'
    raise "Using get_host_port() on a non-tcp/udp service doesn't make sense!"
  end

  host = ARGV[0] || generate_hostname()
  port = (ARGV[1] || SERVICE_METADATA['port']).to_i

  return host, port
end

def get_url
  if protocol() != 'http'
    raise "Using get_url() on a non-http service doesn't make sense!"
  end

  if ARGV[0]
    if ARGV[0] !~ /^http/
      raise "Usage: #{ $0 } [http[s]://hostname:port/]"
    end

    if ARGV[0][-1] == '/'
      return ARGV[0]
    else
      return "#{ ARGV[0] }/"
    end
  else
    return "https://#{ generate_hostname() }/"
  end
end

def check_flag(flag, terminate: true)
  if flag.nil?
    raise "Expected flag, got nil!"
  end

  if flag == ''
    raise "Expected flag, got the empty string!"
  end

  flag = flag.chomp

  puts "Fetched flag: #{ flag } (\"#{ flag.unpack('H*').pop }\")"

  if flag != expected_flag()
    raise "We didn't get the correct flag!"
  end

  puts "Looks good!"

  if terminate
    exit 0
  end
end

puts "Loading checker..."
puts '--------'
puts "Challenge name:        #{ CHALLENGE_NAME }"
puts "Expected flag:         #{ expected_flag() } (\"#{ expected_flag().unpack('H*').pop }\")"
case protocol()
when 'http'
  puts "Using URL:             #{ get_url() }"
when 'tcp'
  puts "Using TCP host/port:   #{ get_host_port().join(':') }"
when 'udp'
  puts "Using UDP host/port:   #{ get_host_port().join(':') }"
else
  puts "Offline challenge"
end
puts '--------'
