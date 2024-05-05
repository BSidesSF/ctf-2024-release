require 'json'
require 'sinatra'
require 'pp'
require 'singlogger'
require 'open3'

::SingLogger.set_level_from_string(level: ENV['log_level'] || 'debug')
LOGGER = ::SingLogger.instance()

# Ideally, we set all these in the Dockerfile
set :bind, ENV['HOST'] || '0.0.0.0'
set :port, ENV['PORT'] || '8080'

SAFER_STREETS_PATH = ENV['SAFER_STREETS'] || '/app/safer-streets'

SCRIPT = File.expand_path(__FILE__)

LOGGER.info("Checking for required binaries...")
if File.exist?(SAFER_STREETS_PATH)
  LOGGER.info("* Found `safer-streets` binary: #{ SAFER_STREETS_PATH }")
else
  LOGGER.fatal("* Couldn't find `safer-streets` binary #{ SAFER_STREETS_PATH } - use the `SAFER_STREETS` env var to change")
  exit(1)
end

get '/' do
  erb :index, :locals => { }
end

get '/display' do
  content_type 'image/jpeg'

  begin
    return File.read(File.join(File.dirname(SCRIPT), "data", params['name']))
  rescue StandardError => e
    return "Error in script #{SCRIPT}: #{e.to_s}"
  end
end

get '/upload' do
  erb :upload, :locals => { 'msg' => (params['msg'] || nil) }
end

post '/upload' do
  speed = params['speed'].to_i
  photo = params['photo']['tempfile'].path

  Open3.popen2("#{SAFER_STREETS_PATH} '#{photo}' '#{speed}'")  do |stdin, stdout, wait_thr|
    pid = wait_thr.pid # pid of the started process.

    result = stdout.read()

    if result && result =~ /n\/a/
      return "No visible plate detected!"
    end


    if wait_thr.value.success?
      result = JSON::parse(result)
      system("/usr/bin/report-infraction --node='#{result['node']}' --img='#{photo}'")

      redirect('/upload?msg=Success!')
    else
      return "Error running #{ SAFER_STREETS_PATH }! Are you sure you're uploading a real image?"
    end
  end

end
