#Auxiliar functions for script
require 'csv'

def pagination header
	links = {}
 
	header['link'].split(',').each do |link|
  	link.strip!
  
  	parts = link.match(/<(.+)>; *rel="(.+)"/)
  	links[parts[2]] = parts[1]
	end
	return links
end

def verify_rate_limit header
	if header['x-ratelimit-remaining'].to_i < 2
		wait = Time.at(header['x-ratelimit-reset'].to_i) - Time.now
		puts '[log] Low rate limit, wait ' +  wait.to_s + 'seconds to reset'
		if(wait > 0); sleep(wait) end
	end
end

def process_users response, users, token
	response['items'].each do |item|
    username = item['repository']['owner']['login']
    reponame = item['repository']['name']
    
    get_user(username, users, token)
    get_collaborators(username, reponame, users, token)
    get_contributors(username, reponame, users, token)
  end
end

def save_users_csv(file, users)
  begin
    CSV.open(file , "w") do |writer|
      users.each do |login, values|
        writer << [login, values['email'], values['location']] 
      end
    end
  rescue Exception => e
      puts e.inspect
  end
end

def get_user login, users, token
  if !users.has_key?(login) then 
	  url = 'https://api.github.com/users/' + login
    response = get_response(url, token)
    ap response
	  users[login] = {'email' => response['email'], 'location' => response['location']}
  end
end

def get_contributors owner, repos, users, token
	url = 'https://api.github.com/repos/' + owner + '/' + repos + '/contributors'
	response = get_response(url, token)

	response.each do |item|
    begin
      get_user(item['login'], users, token)
    rescue Exception => e
      puts e.inspect
    end
	end
end

def get_collaborators owner, repos, users, token
	url = 'https://api.github.com/repos/' + owner + '/' + repos + '/collaborators'
	response = get_response(url, token)
	
  response.each do |item|
    begin
      get_user(item['login'], users, token)
    rescue Exception => e
      puts e.inspect
    end
	end
end

def get_response url, token
	headers = { 'Accept' => 'application/vnd.github.preview.text-match+json', 'User-Agent' => 'coopera-codesearch' }
	url += '?' + token

	begin
		response = HTTParty.get(url, headers)
		verify_rate_limit(response.headers)
	rescue Exception => e
		puts e.inspect
	end

	return response
end


