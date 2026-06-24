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
    markup.scan(/src="(https:\/\/www\.surfchex\.com\/hls\/[^"]+\.m3u8)"/).flatten.first
  when 'ipcamlive'
    response = HTTParty.get("https://www.ipcamlive.com/ajax/getcamerastreamstate.php?cameraalias=#{camera}").body
    return nil if response.nil? || response.empty?
    stream_data = JSON.parse(response) rescue nil
    return nil unless stream_data&.dig('details', 'streamid')
    logger.info "Stream data: #{stream_data}"
    "#{stream_data['details']['address']}streams/#{stream_data['details']['streamid']}/stream.m3u8"
  when 'surfline'
    # Surfline Referer-gates the embed page (and the playlist), so send one.
    markup = HTTParty.get("https://embed.cdn-surfline.com/cam/#{camera}.html", headers: { 'Referer' => 'https://www.surfline.com/' }).body
    markup.scan(/(https:\/\/hls\.cdn-surfline\.com\/[^"']+?\.m3u8)/).flatten.first
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
  halt 404, 'Camera not found' unless url

  if params['provider'] == 'surfline'
    # Surfline gates the .m3u8 playlist behind a Referer header, but the .ts
    # segments are public. Fetch the (tiny) playlist ourselves with the Referer,
    # then rewrite the relative segment names to absolute CDN URLs so the client
    # pulls the video straight from Surfline's CDN -- no proxying, no disk.
    playlist = HTTParty.get(url, headers: { 'Referer' => 'https://www.surfline.com/' }).body
    base = url.rpartition('/').first
    content_type 'application/vnd.apple.mpegurl'
    playlist.each_line.map do |line|
      stripped = line.strip
      stripped.empty? || stripped.start_with?('#') ? line : "#{base}/#{stripped}\n"
    end.join
  else
    redirect url
  end
end


