$LOAD_PATH.unshift(Dir.getwd)
require "feed"
run Sinatra::Application
