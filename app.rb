
require "rubygems"
require "sinatra"
require "builder"
require "sass"
require "./models"
#require "ruby-debug/debugger"

get "/" do
  erb :index
end

get "/stylesheet.css" do
    scss :stylesheet, :style => :compact
end

get "/feed/:key/:name.xml" do
  @user = User.first_or_create(:name => params[:name])
  @user.load_scores params[:key]
  builder :feed, :locals => {:user => @user}

#builder do |xml|
#  xml.instruct! :xml, :version => '1.0'
#  xml.rss :version => "2.0" do
#    xml.channel do
#      xml.title "Klout Scores for #{@user}"
#      xml.description "Klout Scores for #{@user}"
#      xml.link request.url
#      @user.scores.latest.each do |score|
#        xml.item do
#          xml.title score
#          xml.link "http://klout.com/##{@user}"
#          xml.description score
#          xml.pubDate Time.parse(score.created_at.to_s).rfc822()
#          xml.guid
#        end
#      end
#    end
#  end
#end

end
