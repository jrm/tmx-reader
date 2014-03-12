require 'sinatra'
require 'action_view'
require './helpers/sinatra'
require './helpers/helpers'
require 'haml'
require 'nokogiri'

require './lib/sinatra_ad_auth'

APP_NAME = "TMX Reader"

#require 'benchmark'
#ActiveRecord::Base.default_timezone = :utc
#ActiveRecord::Base.logger = Logger.new( File.join(File.expand_path("../log", __FILE__),"app-#{settings.environment}.log") )
#I18n.enforce_available_locales = false

#helpers ActionView::Helpers::NumberHelper

helpers Helpers

include FileUtils::Verbose

configure do
  enable :sessions
  set :session_secret, 'jY0EPiwDlxsppapEc5fmr2X7QuDwmvQiBAYkzyMZbx4ipy4P3LXq12Toqkw8w4dRRRFJnyLf3aqvlBXH'
end

get '/login' do
  haml :login_form, :layout => :login_layout
end

get '/logout' do
  session[:authorized] = nil
  redirect '/login'
end

post '/login' do
  #conf = File.join(settings.root,'config','ldap.yml')
  #user = Sinatra::ADAuth::User.authenticate(params[:user],params[:pass], conf)
  #if ! user.nil? && user.member_of?("RequiredADGroupName")
  if ! user.nil?
    session[:authorized] = true
    redirect '/'
  else
    session[:authorized] = false
    redirect '/login'
  end
end


get '/:file?' do
  @files = Dir.glob('data/*.tmx').collect {|f| File.basename(f,".*")}
  @doc = Nokogiri::XML(File.open("data/#{params[:file]}.tmx")) if params[:file]
  if @doc
    @langs = @doc.xpath("//tuv").collect {|t| t.attributes["lang"].value }.uniq
    @src_lang = @doc.xpath("//header/@srclang")
    @target_langs = @langs - [@src_lang.text]
    @headers = @doc.xpath("//header/prop")
    @tus = @doc.xpath("//body/tu")
  end
  haml :index
end


post '/upload' do
  tempfile = params[:file][:tempfile] 
  filename = params[:file][:filename] 
  cp(tempfile.path, "data/#{filename}")
  redirect '/'
end

def protected_page
  redirect '/login' unless session[:authorized]
end