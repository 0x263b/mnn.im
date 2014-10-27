require 'sinatra'
require 'sinatra/activerecord'
require './environments'

require 'date'
require 'kramdown'
require 'cgi'
require 'json'

enable :sessions
set :static_cache_control, [:public, max_age: 60 * 60 * 24 * 365]
set :server, :puma

class Paste < ActiveRecord::Base
	validates :body, presence: true
end

class Short < ActiveRecord::Base
	validates :long, presence: true
end

# --------------------------------------------------------------
#                           Basic pages
# --------------------------------------------------------------

# new
get %r{\/(p?|u?)\z} do
	erb :index
end

get '/api' do
	erb :api
end

get '/about' do
	erb :about
end

get '/api/langs' do
	output = {
		:lang_codes => ["text", "c_cpp", "clojure", "coffee", "css", "csharp", "golang", "haskell", "html", "html_ruby", "java", "javascript", "json", "llvm", "lua", "markdown", "objectivec", "perl", "php", "python", "ruby", "rust", "sh"]
	}
	content_type 'application/json'
	output.to_json
end

# --------------------------------------------------------------
#                         POST requests
# --------------------------------------------------------------

# Create paste on the site
post '/p' do
	begin
		short_id = rand(36**4).to_s(36)
		esc_body = CGI::escapeHTML(params[:paste_body])
		params[:paste_title].empty? ? title = "Untitled" : title = params[:paste_title][0..139]

		@paste = Paste.new(
			:title      => title, 
			:lang_code  => params[:paste_high], 
			:body       => esc_body,
			:short      => short_id,
			:life_time  => 1209600
		)
		@paste.save

		redirect "/p#{@paste.short}"
	rescue
		nil
	end
end


# Create paste via command line
post '/c' do
	begin
		short_id = rand(36**4).to_s(36)
		esc_body = CGI::escapeHTML(params[:paste])

		params[:lang].nil? ? high = "text" : high = params[:lang].downcase

		case high
		when "txt", "text"
			high = "text"
		when "c", "cpp", "cxx", "c++", "h", "hh", "hpp", "hxx", "h++", "c_cpp"
			high = "c_cpp"
		when "clj", "edn", "clojure"
			high = "clojure"
		when "coffee"
			high = "coffee"
		when "css"
			high = "css"
		when "cs", "csharp"
			high = "csharp"
		when "go", "golang"
			high = "golang"
		when "hs", "haskell"
			high = "haskell"
		when "htm", "html"
			high = "html"
		when "java"
			high = "java"
		when "js", "javascript"
			high = "javascript"
		when "json"
			high = "json"
		when "ll", "llvm"
			high = "llvm"
		when "lua"
			high = "lua"
		when "md", "markdown"
			high = "markdown"
		when "m", "mm", "objectivec"
			high = "objectivec"
		when "pl", "pm", "t", "pod", "perl"
			high = "perl"
		when "php"
			high = "php"
		when "py", "python"
			high = "python"
		when "rb", "ruby"
			high = "ruby"
		when "rs", "rust"
			high = "rust"
		when "rc", "sh"
			high = "sh"
		when "swift"
			high = "swift"
		else
			high = "text"
		end

		params[:life].nil? ? life_time = 1209600 : life_time = params[:life].to_i

		if life_time < 60
			life_time = 60
		elsif life_time > 2592000
			life_time = 2592000
		end
		
		params[:title].nil? ? title = "Untitled" : title = params[:title][0..139]

		@paste = Paste.new(
			:title      => title, 
			:lang_code  => high, 
			:body       => esc_body,
			:short      => short_id,
			:life_time  => life_time
		)
		@paste.save
		
		expiration_date = DateTime.strptime((Time.now.to_i + @paste.life_time).to_s,'%s')

		output = {
			:paste  => {
				:id              => @paste.short,
				:link            => request.base_url + "/p" + @paste.short,
				:raw             => request.base_url + "/r" + @paste.short,
				:lang_code       => @paste.lang_code,
				:expiration_date => expiration_date
			},
			:status => "success"
		}

		if high == 'markdown'
			output[:paste][:formatted] = request.base_url + "/f" + @paste.short
		end

		content_type 'application/json'
		output.to_json
	rescue
		output = {
			:error_code => 1, 
			:status     => "error"
		}
		content_type 'application/json'
		output.to_json
	end
end


# Shorten url via command line
post '/s' do
	begin
		short_id = rand(36**4).to_s(36) 
		@short = Short.new(
			:long      => request.body.read,
			:short     => short_id,
			:life_time => 1209600
		)
		@short.save

		expiration_date = DateTime.strptime((Time.now.to_i + @short.life_time).to_s,'%s')

		output = {
			:url    => {
				:id              => @short.short,
				:short_url       => request.base_url + "/u" + @short.short,
				:long_url        => @short.long,
				:expiration_date => expiration_date
			},
			:status => "success"
		}
		content_type 'application/json'
		output.to_json
	rescue
		output = {
			:error_code => 1, 
			:status     => "error"
		}
		content_type 'application/json'
		output.to_json
	end
end

# --------------------------------------------------------------
#                         Show the goods
# --------------------------------------------------------------

# show paste
get '/p:id' do
	begin
		@paste = Paste.find_by short: params[:id]

		if @paste.created_at.to_time.to_i > (Time.now.to_i - @paste.life_time)
			erb :show
		else
			@paste.destroy
			redirect '/'
		end
	rescue
		redirect '/'
	end
end

# show raw paste
get '/r:id' do
	begin
		@paste = Paste.find_by short: params[:id]

		if @paste.created_at.to_time.to_i > (Time.now.to_i - @paste.life_time)
			content_type 'text/plain'
			CGI::unescapeHTML(@paste.body)
		else
			@paste.destroy
			redirect '/'
		end
	rescue
		redirect '/'
	end
end

# show formatted markdown paste
get '/f:id' do
	begin
		@paste = Paste.find_by short: params[:id]

		if @paste.lang_code != "markdown"
			redirect '/'
		end

		if @paste.created_at.to_time.to_i > (Time.now.to_i - @paste.life_time)
			formatted = CGI::unescapeHTML(@paste.body).to_s
			@formatted = Kramdown::Document.new(formatted).to_html
			erb :markdown
		else
			@paste.destroy
			redirect '/'
		end
	rescue
		redirect '/'
	end
end

# redirect url
get '/u:id' do
	begin
		@short = Short.find_by short: params[:id]

		if @short.created_at.to_time.to_i > (Time.now.to_i - @short.life_time)
			redirect @short.long
		else
			@short.destroy
			redirect '/'
		end
	rescue
		redirect '/'
	end
end
