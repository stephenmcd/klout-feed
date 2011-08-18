
require "rubygems"
require "sinatra"
require "erubis"
require "builder"
require "sass"
require "./models"
#require "ruby-debug/debugger"

set :erubis, :escape_html => true

# Show the homepage form.
get "/" do
  erubis :index
end

# Handle post to the homepage form - display a valid feed URL or error.
post "/" do
  @user = User.first_or_create(:name => params[:username])
  @error = @user.load_scores params[:api_key]
  @success = @error.length == 0
  erubis :index
end

# Render Sass stylesheet.
get "/stylesheet.css" do
    scss :stylesheet, :style => :compact
end

# RSS feed for the given API Key and username.
get "/feed/:api_key/:username.xml" do
  @user = User.first_or_create(:name => params[:username])
  @user.load_scores params[:key]
  #builder :feed
  builder do |xml|
    xml.instruct! :xml, :version => '1.0'
    xml.rss :version => "2.0" do
      xml.channel do
        xml.title "Klout Scores for #{@user}"
        xml.description "Klout Scores for #{@user}"
        xml.link request.url
        @user.scores.latest.each do |score|
          xml.item do
            xml.title score
            xml.link "http://klout.com/##{@user}"
            xml.description score
            xml.pubDate Time.parse(score.created_at.to_s).rfc822()
            xml.guid
          end
        end
      end
    end
  end
end
