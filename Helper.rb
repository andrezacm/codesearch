#Auxiliar functions for script
require 'csv'

class Helper 

  def initialize(data_source) 
    @csv_file = data_source
    @users = Hash.new
    save_user_csv_header
  end

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

  def save_users response, token
    response['items'].each do |item|
      username = item['repository']['owner']['login']
      reponame = item['repository']['name']
      
      save_user(username, token)
      save_collaborators(username, reponame, token)
      save_contributors(username, reponame, token)
    end
  end

  def save_user_csv_header
    begin
      CSV.open(@csv_file, "ab") do |writer|
        writer << ['login', 
                   'email', 
                   'name',
                   'location', 
                   'blog', 
                   'company', 
                   'public_repos', 
                   'followers', 
                   'following', 
                   'created_at']
      end
    rescue Exception => e
      puts e.inspect
    end
  end

  def save_user_csv(user)
    begin
      CSV.open(@csv_file, "ab") do |writer|
        writer << user.values
      end
    rescue Exception => e
      puts e.inspect
    end
  end

  def save_user login, token
    if !@users.has_key?(login) then 
      url = 'https://api.github.com/users/' + login
      response = get_response(url, token)
      ap response
      user = {'login' => login,
              'email' => response['email'],
              'name' => response['name'],
              'location' => response['location'],
              'blog' => response['blog'],
              'company' => response['company'],
              'public_repos' => response['public_repos'],
              'followers' => response['followers'],
              'following' => response['following'],
              'created_at' => response['created_at']}
      # add to a hash
      @users[login] = user
      # save to csv
      save_user_csv(user)
      puts "User #{login} saved."
    else
      puts "User #{login} already in database"
    end
  end

  def save_contributors owner, repos, token
    url = 'https://api.github.com/repos/' + owner + '/' + repos + '/contributors'
    response = get_response(url, token)

    response.each do |item|
      begin
        save_user(item['login'], token)
      rescue Exception => e
        puts e.inspect
      end
    end
  end

  def save_collaborators owner, repos, token
    url = 'https://api.github.com/repos/' + owner + '/' + repos + '/collaborators'
    response = get_response(url, token)
    
    response.each do |item|
      begin
        save_user(item['login'], token)
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

end

