# frozen_string_literal: true

# Workshop REST tour — Pillar 2 (Ruby).
#
# Mirror of the Python REST tour: 4 demo endpoints exercising RestClient.

require 'sinatra/base'
require 'json'
require 'rack'
require 'signalwire'

SHARED_UI = File.expand_path('../../../../shared/ui', __dir__)
STATE = { creds: nil }

def rest_client
  c = STATE[:creds]
  SignalWire::REST::RestClient.new(project: c[:project_id], token: c[:token], host: c[:space])
end

class WorkshopRest < Sinatra::Base
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
    STATE[:creds] = { project_id: project_id, space: space, token: token }
    { ok: true, jwt: 'session-validated', subscriber_id: 'n/a' }.to_json
  end

  get '/api/list-numbers' do
    content_type :json
    halt 400, { ok: false, error: 'Run setup first' }.to_json unless STATE[:creds]
    begin
      response = rest_client.phone_numbers.list(limit: 20)
      { ok: true, sdk_call: 'client.phone_numbers.list(limit: 20)', response: response }.to_json
    rescue => e
      halt 400, { ok: false, error: e.message }.to_json
    end
  end

  post '/api/send-sms' do
    content_type :json
    halt 400, { ok: false, error: 'Run setup first' }.to_json unless STATE[:creds]
    data = JSON.parse(request.body.read) rescue {}
    from = (data['from'] || '').strip
    to = (data['to'] || '').strip
    body = (data['body'] || 'Hello from the SignalWire workshop!').strip
    halt 400, { ok: false, error: 'from + to required' }.to_json if from.empty? || to.empty?
    begin
      response = rest_client.compat.messages.create(from: from, to: to, body: body)
      {
        ok: true,
        sdk_call: "client.compat.messages.create(from: #{from.inspect}, to: #{to.inspect}, body: ...)",
        response: response,
      }.to_json
    rescue => e
      halt 400, { ok: false, error: e.message }.to_json
    end
  end

  get '/api/recent-calls' do
    content_type :json
    halt 400, { ok: false, error: 'Run setup first' }.to_json unless STATE[:creds]
    begin
      response = rest_client.compat.calls.list(page_size: 10)
      { ok: true, sdk_call: 'client.compat.calls.list(page_size: 10)', response: response }.to_json
    rescue => e
      halt 400, { ok: false, error: e.message }.to_json
    end
  end

  post '/api/wire-number' do
    content_type :json
    halt 400, { ok: false, error: 'Run setup first' }.to_json unless STATE[:creds]
    data = JSON.parse(request.body.read) rescue {}
    sid = (data['sid'] || '').strip
    voice_url = (data['voice_url'] || '').strip
    halt 400, { ok: false, error: 'sid + voice_url required' }.to_json if sid.empty? || voice_url.empty?
    begin
      response = rest_client.phone_numbers[sid].update(voice_url: voice_url, voice_method: 'POST')
      {
        ok: true,
        sdk_call: "client.phone_numbers[#{sid.inspect}].update(voice_url: #{voice_url.inspect})",
        response: response,
      }.to_json
    rescue => e
      halt 400, { ok: false, error: e.message }.to_json
    end
  end
end

app = Rack::Builder.new do
  map('/shared') { run Rack::Files.new(SHARED_UI) }
  map('/') { run WorkshopRest }
end

if $PROGRAM_NAME == __FILE__
  port = ENV.fetch('PORT', '8001').to_i
  Rack::Handler.pick(%w[puma webrick]).run(app, Port: port, Host: '0.0.0.0')
end
