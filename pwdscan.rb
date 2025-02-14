#!/usr/bin/env ruby
base_path = __dir__
$LOAD_PATH.unshift(base_path,'lib')
data_pwd = File.join(base_path,'data','')
common_file = File.join(base_path,'data','common.txt')
require 'thread'
require 'colorize'
require 'timeout'
require 'uri'
require 'net/http'
require 'optparse'
require 'browser'
require_relative(File.join(base_path,'version','version.rb'))
help = ''
time = 0
thread = 1
set = Hash.new
set['download'] = "No"
set['download_pwd'] = nil
if ARGV.empty?
  puts "Use " + "-h".colorize(:green) + " or " + "--help".colorize(:green) + " to view the help information."
    exit
end
OptionParser.new do |opts|
  help = <<-BANNER
Option:
+\t-h,--help\tHelp
+\t-f,--file=\tSet Up a Web Dictionary
+\t-t,--timeout=\tSet timeout period
+\t-d,--download=\tDownload the scanned directory to a local directory
-----------------------------------------------------------------------------
+\t--download-catalogue=\tSpecify the directory to save after downloading
EXAMPLES: ruby pwdscan.rb <address>
\truby pwdscan.rb http://www.example.com
\truby pwdscan.rb http://www.example.com --timeout=3
\truby pwdscan.rb http://www.example.com --download="Yes"
BANNER
  opts.on("-h","--help","Help") do
    puts help
    exit
  end
  opts.on("-fFILE","--file=FILE","Set Up a Web Dictionary") do |f|
    common_file = f.to_s
  end
  opts.on("-tTIME","--timeout=TIME","Set timeout period") do |t|
    time = t.to_i
  end
  opts.on("-dSET","--download=SET","Download the scanned directory to a local directory") do |set2|
    set['download'] = set2
  end
  opts.on("--download-catalogue=PWD","Specify the directory to save after downloading") do |p|
    set['download_pwd'] = p.chomp('/')
    set['download_pwd'] += '/'
  end
end.parse!
addr = ARGV[0].sub('http://','').chomp('/')
if_subdomain = addr.count('.')
code = ''
unless File.file?(common_file)
  puts "Unable to open the file " + common_file.colorize(:yellow)
  puts "\n[!] Aborting...".colorize(:red)
  exit
end
if if_subdomain <= 1
  puts "[!] You are not entering a full URL".colorize(:red)
  exit
end
begin
  addr_host = "http://#{addr}"
  puts <<-LOG
                  _                     
 _ ____      ____| |___  ___ __ _ _ __  
| \'_ \\ \\ /\\ / / _` / __|/ __/ _` | \'_ \\ 
| |_) \\ V  V / (_| \\__ \\ (_| (_| | | | |
| .__/ \\_/\\_/ \\__,_|___/\\___\\__,_|_| |_|
|_|                                     
  LOG
  puts
  puts "\t+----------------------------------------+"
  puts "\t|  name: pwdscan                         |"
  puts "\t|  version: #{PWDS::VERSION}                          |"
  puts "\t|  author: molovi                        |"
  puts "\t|  github: https://github/molovi/pwdscan |"
  puts "\t|  describe: Web directory scanning tool |"
  puts "\t+----------------------------------------+"
  puts "[*] ".colorize(:blue) + "Checking if " + "#{addr} ".colorize(:yellow) + "is accessible."
  print "Access status-----------------------------"
  begin
    Timeout.timeout(time) do
      uri = URI(addr_host)
      response = Net::HTTP.get_response(uri)
      code = response.code
    end
  rescue Timeout::Error
    puts "[!] Connection Timeout".colorize(:red)
    exit
  rescue SocketError
    puts "NO".colorize(:red)
    puts "\n[!] ".colorize(:red) + "Unable to access"
    exit
  end
  begin
    if code == '200'
      puts "OK".colorize(:green)
      puts "+ ".colorize(:green) + "address: " + "#{addr_host}".colorize(:green)
      puts "+ ".colorize(:green) + "status code: " + "#{code}".colorize(:green)
      sleep time if time != 0
      puts "+ ".colorize(:green) + "server: " + "#{PWDS.server_scan(addr)}".colorize(:green)
    else
      puts "NO".colorize(:red)
      puts "Too many errors connecting to host => " + "#{addr}".colorize(:yellow)
      exit
    end
  end
  puts "\n[" + "+".colorize(:green) + "] Start runing"
  puts "wordlist_files => " + common_file.colorize(:white)
  puts "Scanning URI => " + addr_host.colorize(:white)
  err,f,d = [],[],[]
  a,b,c = 0,0,0
    begin
      begin
        IO.foreach(common_file) do |text|
          sleep time if time != 0
          if return_c = PWDS.scanner(addr_host,text.chomp) == "file"
            f[a] = addr_host + "/" + text.chomp
            a+=1
          elsif return_c == "dir"
            d[b] = text.chomp
            b+=1
          end
        end
      rescue EOFError
      end
      b2 = b
      start = 1
      begin
        loop do
          for i in start..b
            sleep time if time != 0
            IO.foreach(common_file) do |text|
              new_text = d[i].to_s + "/" + text.chomp
              if return_c = PWDS.scanner(addr_host,new_text) == "file"
                f[a] = addr_host + "/" + new_text
                a+=1
              elsif return_c == "dir"
                d[b] = new_text
                b+=1
              end
            end
          end
          start = b2+1
          b2 = b
          break unless b > b2
        end
      end
    rescue SocketError
    rescue Errno::ENETUNREACH
      puts "[!] Cannot connect".colorize(:red)
    rescue Errno::ECONNREFUSED
    end
    puts "[!] ".colorize(:green) + "#{a} ".colorize(:green) + "files were scanned"
    if set['download'] == "Yes"
      puts "[*] ".colorize(:blue) + "Start downloading file"
      time = 
      f.each do |file|
        file = file.sub('http://','')
        dir_and_file = file.split('/')
        number = file.count('/') + 1
        for i in 1..(number - 1)
          unless File.exist?("#{set['download_pwd']}#{dir_and_file[i]}")
            Dir.mkdir("#{set['download_pwd']}#{dir_and_file[i]}")
          end
        end
      end
    end
rescue Interrupt
  puts "\n[!] Aborting...".colorize(:red)
  exit
end
