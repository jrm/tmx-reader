require 'sinatra'
require 'action_view'
require './helpers/sinatra'
require './helpers/helpers'
require 'haml'
require 'nokogiri'

require './lib/sinatra_ad_auth'
require './lib/translation_memory'


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
  set :data_dir, File.expand_path("../data", __FILE__)
  set :index_file, File.join(settings.data_dir, "tmx-index.yml")
end

before do
  if File.exist? settings.index_file
    File.open(settings.index_file, 'r') do |file|
      @memory_index = YAML::load(File.open(settings.index_file, 'r'))
    end
  end
  @memory_index ||= {}
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


get '/:id?' do
  if params[:id] && @record = @memory_index[params[:id]]
    @tmx = TranslationMemory.new( @record[:fullpath] )
    @src_lang = @record[:source_lang] 
    @target_langs = @record[:target_langs]
    @properties = @tmx.properties
    @tus = @tmx.translation_units
  end
  haml :index
end


post '/upload' do
  tempfile = params[:file][:tempfile] 
  filename = params[:file][:filename] 
  target_file = File.join(settings.data_dir, filename)
  cp tempfile.path, target_file
  
  id = File.basename(filename,".*")
  translation_memory = TranslationMemory.new(target_file)
  record = { :id => id,
             :filename => File.basename(target_file), 
             :fullpath => target_file,
             :tmx_version => translation_memory.version,
             :uploaded_at => File.mtime(target_file),
             :source_lang => translation_memory.source_language,
             :target_langs => translation_memory.target_languages,
             :translation_unit_count => translation_memory.translation_units.size }
  @memory_index[id] = record
  puts @memory_index.inspect
  File.open(settings.index_file, 'w') do |f|
    YAML::dump(@memory_index, f)
  end
  redirect '/'
end

delete '/delete/:id' do
  record = @memory_index[params[:id]]
  if File.exist? record[:fullpath]
    File.delete record[:fullpath]
  end
  @memory_index.delete(params[:id])
  File.open(settings.index_file, 'w') do |f|
    YAML::dump(@memory_index, f)
  end
  redirect '/'
end

def protected_page
  redirect '/login' unless session[:authorized]
end