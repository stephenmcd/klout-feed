
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
  builder :feed
end
