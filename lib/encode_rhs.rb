# this script must be run in an environment with the appropriate gems
# e.g., $ rvm gemset use pr-tools
#
# overview:
# ---------
# This script interacts with the RESTful Handle Service to generate handles.
# (See http://v1.home.nyu.edu/svn/dlib/pr/handle-rest/trunk/docs/README.TXT )
#
# Upon success, the handle prefix/<NOID> is output to stdout,
# e.g., 2333.1/cnp5hs50
#
# The test-handle-service prefix is 10676.
#
# Usage:
# ruby __FILE__ [options]
#   options:
#   -d, --description 'text string'  
#   -b, --binding     'URL'          [defaults to 'http://dlib.nyu.edu/object-in-processing']
#   -p, --prefix      'prefix'       [defaults to 10676]
#   -l, --local_name  'local name'   
#
#
# use cases:
# ----------
# create new handle pointing to default placeholder URL    : ruby __FILE__
# create new handle pointing to known URL                  : ruby __FILE__ -b http://hidvl.nyu.edu/video/000031640.html
# create new handle pointing to known URL with description : ruby __FILE__ -b http://hidvl.nyu.edu/video/000031640.html -d 'this is an awesome handle!'
# update existing handle                                   : ruby __FILE__ -p 2333.1 -b 'http://www.example.com/a/b' -l 41ns1v3d
#

require 'rest-client'
require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'pp'
require 'uri'
require 'optparse'
options = {}

DEFAULT_BINDING = 'http://dlib.nyu.edu/object-in-processing'
DEFAULT_PREFIX  = '10676'
# defaults
options[:binding] = DEFAULT_BINDING
options[:prefix]  = DEFAULT_PREFIX

def usage
<<EOF
  usage: #{$PROGRAM_NAME} [-p <prefix>] [-l <local name (e.g., a NOID)>] [-b <handle binding URL>] [-d <description>]
  examples:
         update an existing handle                                          : #{$PROGRAM_NAME} -p 2333.1 -b 'http://www.example.com/a/b' -l 41ns1v3d
         create new handle in default prefix namespace bound to default URL : #{$PROGRAM_NAME}
         create new handle in default prefix namespace bound to a known URL : #{$PROGRAM_NAME} -b http://hidvl.nyu.edu/video/000031640.html
         create new handle in default prefix namespace bound to a known URL with description : #{$PROGRAM_NAME} -b http://hidvl.nyu.edu/video/000031640.html -d 'HIDVL:The Red Rose'
EOF
end

OptionParser.new do |opts|
  opts.banner = usage
  opts.on('-d', '--description description', 'Add handle description') do |d|
    options[:description] = d
  end

  opts.on('-b', '--binding binding', "Handle binding    (defaults to #{DEFAULT_BINDING})") do |b|
    options[:binding] = b
    abort("'#{options[:binding]}' does not appear to be a URL") unless (URI.parse(options[:binding]).host && URI.parse(options[:binding]).scheme)
  end

  opts.on('-p', '--prefix prefix', "Handle prefix     (defaults to #{DEFAULT_PREFIX})") do |p|
    options[:prefix] = p
  end

  opts.on('-l', '--local_name local_name', 'Handle local_name (usually a NOID)') do |l|
    options[:local_name] = l
  end
end.parse!

# fail if any arguments left over after options parsing
abort("Argument Error. The following arguments are missing a flag: #{ARGV}\n#{usage}") unless ARGV.length == 0

home  = ENV['HOME']
creds_file_path = File.join(home, '.rhs', 'credentials.yml')
creds = YAML.load_file(creds_file_path)
abort("unable to parse credentials file: #{creds_file_path}") unless creds

@user = creds['user']
@pass = creds['pass']

abort('missing username or password') unless @user && @pass

xml = %Q[<?xml version="1.0" encoding="UTF-8"?>
<hs:info xmlns:hs="info:nyu/dl/v1.0/identifiers/handle">
    <hs:binding>#{options[:binding]}</hs:binding>
    <hs:description>#{options[:description]}</hs:description>
</hs:info>]

# puts '------------------------------------------------------------------------------'
# puts "#{xml}"

path = ''
method = nil
if options[:local_name]
  path = "https://#{@user}:#{@pass}@handle.dlib.nyu.edu/id/handle/#{options[:prefix]}/#{options[:local_name]}"
  method = :put
else
  path = "https://#{@user}:#{@pass}@handle.dlib.nyu.edu/id/handle/#{options[:prefix]}"
  method = :post
end

# puts "--------> #{path}"
# puts "========> #{method}"
# pp options

begin
  response = RestClient.send(method, path, xml, :content_type => :xml)
  doc = Nokogiri::XML(response.body)
  fix_url = (doc.xpath('//hs:location').text).strip
  path = URI.parse(fix_url).path
  abort('unable to extract path') unless path
  puts path.gsub(/\A\//,'')
rescue Exception => e
  abort(e.message)
end

exit 0
