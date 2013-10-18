# Usage: $ ruby script.rb [repositories|code|issues|users] [query_string]
require 'httparty'
require 'launchy'
require 'socket'
require 'awesome_print'
require_relative 'aux'

params = {}
params[:q]     = ARGV[0]

if params[:q].nil? 
  puts "Usage: $ ruby script.rb [query_string]"
  exit
end

#START OAuth
	client_id = 'd74fcf012a3e382c7fed'
	client_secret = '653999ffa39d81e9ae4b0138d4685045a625d967' 

	#open authorize page
	Launchy.open ('https://github.com/login/oauth/authorize?client_id=' + client_id)

	input = nil

	#start server to get value of code
	puts 'Starting up server...'

	server = TCPServer.new(2000)
	loop do
  	t = Thread.new(server.accept) do |session|
    	puts "[log] Connection from #{session.peeraddr[2]} at #{session.peeraddr[3]}"
   		puts "[log] Got input from client"
    	input = session.gets
    	session.puts "Permissions granted!\nClosing connection.\nBye :)"
    	puts "[log] Closing connection"
    	session.close
  	end
  	t.join()
  	break if !t.status
	end

	code = input.split("?code=")[1].split(" ")[0]

	#get token
	token = HTTParty.post('https://github.com/login/oauth/access_token', 
        :query => {:client_id => client_id, :client_secret => client_secret, :code => code})
#END OAuth

params[:q] = params[:q].gsub(/\s/, '+')

url = "https://api.github.com/search/code?q=#{params[:q]}"
url += "&" + token
url += "&per_page=100"

headers = { 'Accept' => 'application/vnd.github.preview.text-match+json', 'User-Agent' => 'coopera-codesearch' }

puts "URL: #{url}"
response = HTTParty.get(url, :headers => headers)

users = Hash.new
process_users(response, users, token) 

#Pagination
unless response.headers['link'].nil?
	links = pagination(response.headers)

	while !links['next'].nil? do
		response = HTTParty.get(links['next'], :headers => headers)
		links = pagination(response.headers)
		verify_rate_limit(response.headers)
		process_users(response, users, token)
	end
end

# save users in csv
file = "[#{params[:q]}][#{Time.now}].csv"
save_users_csv(file, users)

