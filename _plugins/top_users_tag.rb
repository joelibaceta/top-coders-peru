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
            response = Net::HTTP.get_response(uri)
            commits = JSON.parse(response.body) 
            return commits["total_count"]
        end

        def countStarts(user)
            uri = URI.parse("https://api.github.com/search/repositories?q=user:#{user} stars:>0&#{authorization_string}")
            response = Net::HTTP.get_response(uri)
            repos = JSON.parse(response.body) 
            counter = 0
            p uri
            repos["items"].each do |repo| 
                counter += (repo["stargazers_count"]).to_i
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

            (1..3).each do |i|

                uri = URI.parse("https://api.github.com/search/users?q=location:lima followers:>10&per_page=100&page=#{i}&sort=followers&order=desc&#{authorization_string}")
                p uri
                response = Net::HTTP.get_response(uri)
                users = JSON.parse(response.body)

                users["items"].each do |user|

                    sleep(3)

                    data = getUserData(user["login"])
                    
                    @top_users[user["login"]] = {
                        name: data["name"],
                        email: data["email"],
                        company: data["company"],
                        followers: data["followers"],
                        url: data["html_url"],
                        commits: countCommits(user["login"]),
                        stars: countStarts(user["login"])
                    }
                end

            end

            return @top_users
        end

        def render(context)
            data = getTopUsersData
            return "<span>#{data}</span>" 
        end

        def initialize(tag_name, text, tokens)
            super
        end
    end
end

Liquid::Template.register_tag('top_users', Jekyll::MeetupMembersCounterTag)