require 'net/http'
require 'uri'

module Jekyll
    class ContributorsTag < Liquid::Tag
        
        def getContributors
            uri = URI.parse("https://api.github.com/repos/peruanosdev/peruanos.github.io/contributors")
            response = Net::HTTP.get_response(uri)

            contributors = JSON.parse(response.body)
            return contributors
        end

        def render(context)
            contributors = getContributors

            element = "<div class='contributors'>"
            contributors.each do |contributor|
                element += "<div class='contributor'>"
                element +=      "<img class='User__image' src='#{contributor[:avatar_url]}'>"
                element +=      "<a href='#{contributor[:html_url]}'> #{contributor[:login]} </a>"
                element += "</div>"
            end
            element += "</div>"
        end
    end
end

Liquid::Template.register_tag('contributors', Jekyll::ContributorsTag)