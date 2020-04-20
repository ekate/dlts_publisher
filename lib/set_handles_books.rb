require 'open3'
#require_relative '../lib/encode_rhs.rb'
#takes in a file of directories
#
def help
  puts "usage: $0 path/to/wip/ filename url-prefix"
  puts "eg:"
  puts "$0 /se/path/ filename dlib.nyu.edu/aco/book/"
  exit 1
end

def chk_url
  url = ARGV[2]
  if url.nil? || url.empty? 
    puts "ERROR: please enter url-prefix "
    help
  end
  url
end


def chk_path
  path = ARGV[0]
  puts "#{path} is not valid" unless File.directory?(path)
end

def chk_args
  help if ARGV.size != 3 
  chk_path
  chk_url
end

chk_args
url = chk_url

path=ARGV[0]
file = ARGV[1]
entries = []
if File.exist?(file)
   File.open(file,"r").each_line do |line|
      dir = line.chomp
      entries.push(path+dir)
   end
else
  puts "ERROR: #{file} doesn't exist"
  exit 1
end
hsh = Hash.new
entries.each{|e| 
    file_id = File.basename(e)
    puts file_id
    handle_file="#{e}/handle"
    handle = File.open(handle_file).first
    hsh = { :prefix => handle.split("/")[0], :noid => handle.split("/")[1].chomp }
    address = url + "#{file_id}"
    prefix = hsh[:prefix]
    local_name = hsh[:noid]
    binding = address
    p "ruby encode_rhs.rb -p #{prefix} -l #{local_name} -b '#{binding}'"
    stdout,stderr,status = Open3.capture3("ruby lib/encode_rhs.rb -p #{prefix} -l #{local_name} -b '#{binding}'")
    if status.success?
       puts "Updated #{stdout.chomp} to point to #{address}"
    else
      puts "ERROR Processing #{file_id}: #{stderr}" 
   end 
}


