require 'sinatra'
require 'json'
require 'httparty'
use Rack::Logger

helpers do
  def logger
    request.logger
  end
end

def get_camera_url(provider, camera)
  case provider
  when 'surfchex'
    markup = HTTParty.get("https://www.surfchex.com/cams/#{camera}/").body
    markup.scan(/src:  \"(https:\/\/\w+\.streamlock.*\.m3u8)\"/m).flatten.first
  when 'ipcamlive'
    stream_data = JSON.parse(HTTParty.get("https://www.ipcamlive.com/ajax/getcamerastreamstate.php?cameraalias=#{camera}").body)
    logger.info "Stream data: #{stream_data}"
    "#{stream_data['details']['address']}streams/#{stream_data['details']['streamid']}/stream.m3u8"
  end
end

get '/' do
  'Get a camera stream URL by visiting /camera/:provider/:camera. For example, /camera/ipcamlive/1234567890.\n\n' +
  'Stream from the camera by visiting /stream/:provider/:camera. For example, /stream/ipcamlive/1234567890.'
end

get '/camera/:provider/:camera' do
  url = get_camera_url(params['provider'], params['camera'])
  if url
    url
  else
    status 404
    'Camera not found'
  end
end

get '/stream/:provider/:camera' do
  url = get_camera_url(params['provider'], params['camera'])
  if url
    redirect url
  else
    status 404
    'Camera not found'
  end
end


