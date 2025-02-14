module PWDS
  def self.server_scan(url)
    server = nil
    begin
      s = TCPSocket.new(url,80)
      s.write("GET / HTTP/1.0\r\n\r\n")
      read = s.read.split("\n")
      read.each do |i|
        if i.match('Server: ')
          server = i.sub("Server: ",'')
        end
      end
      return server
    rescue
      return nil
    ensure
      s.close if s
    end
  end
  def self.get_request(url)
    response = Net::HTTP.get_response(URI(url))
    return response.code
  end
  def self.scanner(url,text)
    code = PWDS.get_request("#{url}/#{text}")
    if code == '302'
      puts "#{url}/#{text.chomp}\t302\t" + "exist".colorize(:green)
      return "file"
    elsif code == '200'
      puts "#{url}/#{text.chomp}\t302\t" + "exist".colorize(:green)
      return "file"
    elsif code == '301'
      puts "#{url}/#{text.chomp}\t301\t" + "directory".colorize(:yellow)
      return "dir"
    end
  end
end
