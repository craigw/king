require 'sinatra'
require 'readability'
require 'open-uri'
require 'cgi'
require 'base64'
require 'stomp'
require 'json'

get '/' do
  erb :index
end

get '/read' do
  client = Stomp::Client.new
  my_channel = '/queue/king.' + Time.now.to_i.to_s + '.' + rand(1_000_000).to_s
  client.subscribe my_channel do |message|
    reply = JSON.parse message.body
    audio_data = Base64.decode64 reply['output']
    content_type "audio/mpeg3"
    body audio_data
    client.close
  end

  html = open(CGI.unescape(params[:url])).read
  doc = Readability::Document.new html
  readable = doc.content
  html = Nokogiri::HTML readable
  content = Base64.encode64 html.inner_text

puts html.inner_text

  conversion = {
    'text' => content,
    'speed' => params[:speed] || 140,
    'pitch' => params[:pitch] || 200,
    'voice' => params[:voice] || 'en-uk'
  }

  client.publish '/queue/bach', conversion.to_json, 'reply-to' => my_channel
  client.join
end
