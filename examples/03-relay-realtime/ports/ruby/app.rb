# frozen_string_literal: true

# Workshop RELAY realtime — Pillar 3 (Ruby).
#
# Sinatra + faye-websocket + EventMachine for WS support. Use Thin as
# the Rack handler since Puma doesn't play well with Rack-hijack WS upgrades.
#
#   bundle install
#   ruby app.rb     # listens on 8002 via Thin

require 'sinatra/base'
require 'json'
require 'rack'
require 'faye/websocket'
require 'eventmachine'
require 'signalwire'

SHARED_UI = File.expand_path('../../../../shared/ui', __dir__)
STATE = { creds: nil, relay: nil }
SUBS = []  # array of Faye::WebSocket connections
KEEPALIVE = 25

def broadcast(event)
  json = JSON.generate(event)
  SUBS.each { |ws| ws.send(json) }
end

class WorkshopRelay < Sinatra::Base
  set :show_exceptions, false

  get('/') { send_file File.join(SHARED_UI, 'creds-form.html') }
  get('/demo.js') do
    content_type 'application/javascript'
    send_file File.join(__dir__, 'demo.js')
  end

  post '/api/setup' do
    content_type :json
    data = JSON.parse(request.body.read) rescue {}
    project_id = (data['project_id'] || '').strip
    space = (data['space'] || '').strip
    token = (data['token'] || '').strip
    halt 400, { ok: false, error: 'All fields required' }.to_json if project_id.empty? || space.empty? || token.empty?

    begin
      SignalWire::REST::RestClient.new(project: project_id, token: token, host: space)
        .phone_numbers.list(limit: 1)
    rescue => e
      halt 400, { ok: false, error: "Credential check failed: #{e.message}" }.to_json
    end

    # Disconnect any prior client
    if STATE[:relay]
      begin STATE[:relay].disconnect rescue nil end
      STATE[:relay] = nil
    end

    rl = SignalWire::Relay::Client.new(
      project: project_id, token: token, host: space, contexts: ['workshop'],
    )
    rl.on_call do |call|
      broadcast(kind: 'call', state: 'incoming', call_id: call.call_id)
      begin
        call.answer
        broadcast(kind: 'call', state: 'answered', call_id: call.call_id)
      rescue => e
        broadcast(kind: 'error', message: "answer failed: #{e.message}")
      end
    end

    EM.next_tick do
      begin
        rl.connect
        broadcast(kind: 'system', message: 'RELAY connected')
      rescue => e
        broadcast(kind: 'error', message: "RELAY connect failed: #{e.message}")
      end
    end

    STATE[:creds] = { project_id: project_id, space: space, token: token }
    STATE[:relay] = rl
    { ok: true, jwt: 'session-validated', subscriber_id: 'n/a' }.to_json
  end

  post '/api/dial' do
    content_type :json
    halt 400, { ok: false, error: 'Run setup first' }.to_json unless STATE[:relay]
    data = JSON.parse(request.body.read) rescue {}
    from = (data['from'] || '').strip
    to = (data['to'] || '').strip
    halt 400, { ok: false, error: 'from + to required' }.to_json if from.empty? || to.empty?
    devices = [[{ type: 'phone', from: from, to: to, timeout: 30 }]]
    begin
      call = STATE[:relay].dial(devices)
      { ok: true, call_id: call.call_id }.to_json
    rescue => e
      halt 400, { ok: false, error: e.message }.to_json
    end
  end

  get '/ws/events' do
    if Faye::WebSocket.websocket?(request.env)
      ws = Faye::WebSocket.new(request.env, nil, ping: KEEPALIVE)
      ws.on(:open) do
        SUBS << ws
        if STATE[:relay]
          ws.send(JSON.generate(kind: 'system', message: 'ws connected'))
        else
          ws.send(JSON.generate(kind: 'error', message: 'Run setup first'))
        end
      end
      ws.on(:close) { SUBS.delete(ws) }
      ws.rack_response  # async hijack
    else
      [400, {}, ['Expected WebSocket upgrade']]
    end
  end
end

app = Rack::Builder.new do
  map('/shared') { run Rack::Files.new(SHARED_UI) }
  map('/') { run WorkshopRelay }
end

if $PROGRAM_NAME == __FILE__
  port = ENV.fetch('PORT', '8002').to_i
  # Use Thin (EventMachine-based) so faye-websocket can hijack the socket.
  require 'rack/handler/thin'
  Rack::Handler::Thin.run(app, Host: '0.0.0.0', Port: port)
end
