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
            uri = URI.parse("https://api.github.com/search/commits?q=author:#{user}&#{authorization_string}")

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
            @top_users = []

            max_commits = 0
            max_stars = 0
            max_followers = 0
            max_public_repos = 0
            
            (1..3).each do |i|

                sleep(30)

                uri = URI.parse("https://api.github.com/search/users?q=location:lima followers:>10&per_page=30&page=#{i}&sort=followers&order=desc&#{authorization_string}")
                
                response = Net::HTTP.get_response(uri)
                users = JSON.parse(response.body)

                users["items"].each do |user|

                    sleep(5)

                    data = getUserData(user["login"])

                    p data["name"]

                    commits = countCommits(user["login"])
                    stars = countStarts(user["login"])
                    followers = data["followers"]
                    repos = data["public_repos"]

                    max_commits = commits if commits > max_commits
                    max_stars = stars if stars > max_stars
                    max_followers = followers if followers > max_followers
                    max_public_repos = repos if repos > max_public_repos
                    
                    @top_users << {
                        id: user["login"],
                        pic: data["avatar_url"],
                        name: data["name"],
                        email: data["email"],
                        company: data["company"],
                        followers: followers,
                        repos: repos,
                        url: data["html_url"],
                        commits: commits,
                        stars: stars
                    }
                end

            end
            
            @top_users.each do |user|
                user[:score] = (user[:commits] / max_commits.to_f + user[:stars] / max_stars.to_f + user[:followers] / max_followers.to_f + user[:repos] / max_public_repos.to_f) / 4.0
            end

            return @top_users.sort_by {|obj| obj[:score]}.reverse
        end

        def render(context)
            users = getTopUsersData
            element = "<table>\n"
            element += "<thead><th><td colspan='2'>user</td><td>name</td><td>email</td><td>company</td><td>followers</td><td>commits</td><td>stars</td><td>repos</td></th><thead>\n"
            element += "<tbody>"
            users.each_with_index do |user, i|
                element += "<tr><td>#{i}</td>"
                element += "<td><img  width='60px' src='#{user[:pic]}'></td>"
                element += "<td><a href='#{user[:url]}'>#{user[:id]}</a></td><td>#{user[:name]}</td><td>#{user[:email]}</td><td>#{user[:company]}</td>"
                element += "<td>#{user[:followers]}</td><td>#{user[:commits]}</td><td>#{user[:stars]}</td><td>#{user[:repos]}</td></tr>\n"
            end
            element += "</tbody>"
            element += "</table>\n"
        end

        def initialize(tag_name, text, tokens)
            super
        end
    end
end

Liquid::Template.register_tag('top_users', Jekyll::MeetupMembersCounterTag)