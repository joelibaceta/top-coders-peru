require 'net/http'
require 'uri'
require 'json'
require 'uri'

module Jekyll
    class MeetupMembersCounterTag < Liquid::Tag

        

        def countCommits(user)
            uri = URI.parse("https://api.github.com/search/commits?q=author-name:#{user}")
            response = Net::HTTP.get_response(uri)
            commits = JSON.parse(response.body) 
            return commits["total_count"]
        end

        def countStarts(user)
            uri = URI.parse("https://api.github.com/search/repositories?q=user:#{user} stars:>0")
            response = Net::HTTP.get_response(uri)
            repos = JSON.parse(response.body) 
            counter = 0
            
            repos["items"].each do |repo| 
                counter += (repo["stargazers_count"]).to_i
            end
            return counter
        end

        def getTopUsersData
            @top_users = {}

            uri = URI.parse("https://api.github.com/search/users?q=location:lima")
            response = Net::HTTP.get_response(uri)
            users = JSON.parse(response.body)

            p response.body

            users["items"].each do |user|
                

                @top_users[user["login"]] = {
                    name: user["name"],
                    email: user["email"],
                    company: user["company"],
                    followers: user["followers"],
                    url: user["html_url"],
                    commits: countCommits(user["login"]),
                    stars: countStarts(user["login"])
                }
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