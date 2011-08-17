
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
  builder :feed
end
