require 'net/http'
require 'uri'
require 'json'
require 'uri'

module Jekyll
    class MeetupMembersCounterTag < Liquid::Tag

        def authorization_string
            return "client_id=#{ENV['CLIENT_ID']}&client_secret=#{ENV['CLIENT_SECRET']}"
        end

        def countCommits(user)
            uri = URI.parse("https://api.github.com/search/commits?q=author-name:#{user}&#{authorization_string}")

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            request = Net::HTTP::Get.new(uri)
            request["Accept"] = 'application/vnd.github.cloak-preview'

            response = http.request(request)

            commits = JSON.parse(response.body) 
            
            return commits["total_count"]
        end

        def countStarts(user)
            uri = URI.parse("https://api.github.com/search/repositories?q=user:#{user} stars:>0&#{authorization_string}")
            response = Net::HTTP.get_response(uri)
            repos = JSON.parse(response.body) 
            counter = 0

            p repos
 

            repos["items"].each do |repo| 
                
                counter += (repo["stargazers_count"].to_i)
            end
            return counter
            
        end

        def getUserData(user)
            uri = URI.parse("https://api.github.com/users/#{user}?#{authorization_string}")
            response = Net::HTTP.get_response(uri)
            user = JSON.parse(response.body) 
             
            return user
        end

        def getTopUsersData
            @top_users = {}

            max_commits = 0
            max_stars = 0
            max_followers = 0
            
            (1..1).each do |i|

                uri = URI.parse("https://api.github.com/search/users?q=location:lima followers:>10&per_page=30&page=#{i}&sort=followers&order=desc&#{authorization_string}")
                p uri
                response = Net::HTTP.get_response(uri)
                users = JSON.parse(response.body)

                users["items"].each do |user|

                    sleep(5)

                    data = getUserData(user["login"])
                    commits = countCommits(user["login"])
                    stars = countStarts(user["login"])
                    followers = data["followers"]

                    max_commits = commits if commits > max_commits
                    max_stars = stars if stars > max_stars
                    max_followers = followers if followers > max_followers
                    
                    @top_users[user["login"]] = {
                        name: data["name"],
                        email: data["email"],
                        company: data["company"],
                        followers: followers,
                        url: data["html_url"],
                        commits: commits,
                        stars: stars
                    }
                end

            end
            
            @top_users.each do |user|
                user["score"] = (user["commits"] / max_commits + user["stars"] / max_stars + user["followers"] / max_followers) / 3
            end

            return @top_users
        end

        def render(context)
            data = getTopUsersData
        end

        def initialize(tag_name, text, tokens)
            super
        end
    end
end

Liquid::Template.register_tag('top_users', Jekyll::MeetupMembersCounterTag)