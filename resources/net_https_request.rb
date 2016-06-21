require 'openssl'
require 'net/http'

url = 'https://blog.foxxx0.de/'

uri = URI.parse(url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER
@data = http.get(uri.request_uri).read_body

STDOUT.write @data
