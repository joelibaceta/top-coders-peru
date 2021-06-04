require 'net/http'
require 'uri'
require 'json'
require 'uri'

module Jekyll
    class TopUsersTag < Liquid::Tag

        attr_accessor :technologies
        attr_accessor :top_users
        attr_accessor :storage

        def make_get_request(uri) 
            uri = URI.parse(uri)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            request = Net::HTTP::Get.new(uri)
            request["Accept"] = 'application/vnd.github.cloak-preview'
            #request["Authorization"] = 'Bearer ' + ENV['GH_ACCESS_TOKEN']

            response = http.request(request)
            return response.body
        end

        def percentile(values, percentile)
            values_sorted = values.sort
            k = (percentile*(values_sorted.length-1)+1).floor - 1
            f = (percentile*(values_sorted.length-1)+1).modulo(1)
            return values_sorted[k] + (f * (values_sorted[k+1] - values_sorted[k]))
        end

        def countRepos(user)
            size = 0
            begin
                (1..3).each do |i|
                    uri = "https://api.github.com/users/#{user}/repos?per_page=100&page=#{i}"
                    raw_response = make_get_request(uri)
                    repos = JSON.parse(raw_response) 
                    repos.each { |repo| getTechnologies(user, repo["name"]) }
                    repos = repos.select { |repo| !repo["fork"] }
                    size += repos.size
               end
            return size
          rescue
            return size
          end
        end

        def countCommits(user)
            now = Time.new
            date_one_year_ago = "#{(now.year - 1).to_s}-#{now.month.to_s.rjust(2, '0')}-#{now.day.to_s.rjust(2, '0')}"
            uri = "https://api.github.com/search/commits?q=author:#{user} committer-date:>#{date_one_year_ago}&per_page=1" 
            raw_response = make_get_request(uri) 
            commits = JSON.parse(raw_response) 
            return commits["total_count"]
        end
        

        def countPRs(user)
            uri = "https://api.github.com/search/issues?q=involves:#{user} type:pr is:merged is:public not #{user}  &per_page=1"
            raw_response = make_get_request(uri) 
            commits = JSON.parse(raw_response) 
            return commits["total_count"]
        end

        def countStarts(user)
            uri = "https://api.github.com/search/repositories?q=user:#{user} repo:#{user}"
            raw_response = make_get_request(uri)
            repos = JSON.parse(raw_response)
            counter = 0
            repos["items"].each do |repo|
                counter += (repo["stargazers_count"].to_i)
            end
            return counter
        end



        def getTechnologies(user, repo)
            uri = "https://api.github.com/repos/#{user}/#{repo}/languages"
            raw_response = make_get_request(uri) 
            languages = JSON.parse(raw_response)

            languages.each do |language, lines|
                counter = @technologies[language] || 0
                @technologies[language] = (counter + 1 ) 
            end
        end

        def getUserData(user)
            uri = "https://api.github.com/users/#{user}"
            raw_response = make_get_request(uri) 
            return JSON.parse(raw_response)
        end

        def getEachUserData
            top_users = []
            (1..3).each do |i|

                uri = "https://api.github.com/search/users?q=location:lima location:peru followers:>10 repos:>10 type:user&per_page=10&page=#{i}&sort=followers&order=desc"

                raw_response = make_get_request(uri)
                users = JSON.parse(raw_response)

                users["items"].each do |user|
                    
                    data = getUserData(user["login"])  
                    commits = countCommits(user["login"])
                    stars = countStarts(user["login"])
                    followers = data["followers"]
                    repos = countRepos(user["login"])
                    prs = countPRs(user["login"])

                    p data["name"]
 
                    top_users << {
                        "id" => user["login"],
                        "pic" => data["avatar_url"],
                        "name" => data["name"],
                        "email" => data["email"],
                        "company" => data["company"],
                        "followers" => followers,
                        "repos" => repos,
                        "url" => data["html_url"],
                        "commits" => commits,
                        "stars" => stars,
                        "prs" => prs
                    }
                end
            end
            return top_users
        end

        def calcMaxs(users)
            commits, stars, followers, prs = [], [], [], []

            users.each do |user|
                commits   << user["commits"] 
                stars     << user["stars"]
                followers << user["followers"]
                prs       << user["prs"]
            end

            p95_commits      = percentile(commits, 0.95)
            p95_stars        = percentile(stars, 0.95)
            p95_followers    = percentile(followers, 0.95) 
            p95_prs          = percentile(prs, 0.95)

            return p95_commits, p95_stars, p95_followers, p95_prs
        end

        def getTopUsersData 

            if File.exist?("top_users_data.json")
                data = JSON.parse(open("top_users_data.json").read())
                @top_users      = data["users"]
                @technologies   = data["technologies"]
            else
                @top_users = getEachUserData
            end

            max_commits, max_stars, max_followers, max_prs = calcMaxs(@top_users)

            @top_users.each do |user|
                
                contributions_score = (
                    [(user["prs"] / max_prs.to_f), 1.0].min + 
                    [(user["stars"] / max_stars.to_f), 1.0].min
                ) / 2 

                user["score"] = ((
                    [(user["commits"] / max_commits.to_f), 1.0].min +
                    contributions_score +
                    [(user["followers"] / max_followers.to_f), 1.0].min 
                ) / 3) * 5
                
                user["commits_pct"]     = [(user["commits"]   / max_commits.to_f), 1.0].min * 5
                user["contribs_pct"]     = contributions_score * 5
                user["followers_pct"]   = [(user["followers"] / max_followers.to_f), 1.0].min * 5 

            end

            f = open("top_users_data.json", "w")
            f.write({ users: @top_users, technologies: @technologies }.to_json)

            languages = @technologies.sort_by {|k,v| v}.reverse.first(15).to_h 
            sum = languages.values.reduce(:+).to_f
            languages.each do |language, value|
                languages[language] = (value/sum * 100).round(2)
            end
            
            return @top_users.sort_by {|obj| obj["score"]}.reverse, languages
        end

        def render(context)
            
            users, languages = getTopUsersData

            element = "<script> draw_languages_chart(" + languages.to_json + ") </script>\n"
            element += "<div class='UsersTableContainer'> <table>\n"
            element += "<thead><th><td>User</td>"
            element += "<td>Info</td>"
            element += "<td>Score</td>"
            element += "<td>Popularity</td>"
            element += "<td>Contributions</td>"
            element += "<td>Activity</td>"
            element += "<tbody>"
            users.each_with_index do |user, i|
                element += "<tr><td>#{i + 1}</td>"
                element += "<td><a href='#{user["url"]}'><img class='User__image' src='#{user["pic"]}'></a></td>"
                element += "<td><div class='score-detail'><b>#{user["name"]}</b><span>#{user["email"]}</span><i>#{user["company"]}</i></div></td>"

                element += "<td><div class='score-box'>"
                element +=      "<div class='score-title'><span>#{user["score"].round(1)}</span></div>"
                element +=      "</div>"
                element += "</td>"
                element += "<td><div class='score-box'>"
                element +=      "<div class='score-title'><span>#{user["followers_pct"].round(1)}</span></div>"
                element +=      "<div class='score-detail'>" 
                element +=          "<small>#{user["followers"].round(1)} followers</small></div>"
                element +=      "</div>"
                element += "</td>"
                element += "<td><div class='score-box'>"
                element +=      "<div class='score-title'><span>#{user["contribs_pct"].round(1)}</span></div>"
                element +=      "<div class='score-detail'>" 
                element +=          "<small>#{user["stars"].round(1)} stars on public repos</small>"
                element +=          "<small>#{user["prs"].round(1)} PRs merged on public repos</small></div>"
                element +=      "</div>"
                element += "</td>"
                element += "<td><div class='score-box'>"
                element +=      "<div class='score-title'><span>#{user["commits_pct"].round(1)}</span></div>"
                element +=      "<div class='score-detail'>"
                element +=          "<small>#{user["commits"].round(1)} commits in the last year</small></div></td>" 
            end
            element += "</tbody>"
            element += "</table> </div>\n"
        end

        def initialize(tag_name, text, tokens)
            super
            @technologies = Hash.new
        end
    end
end

Liquid::Template.register_tag('top_users', Jekyll::TopUsersTag)
