# frozen_string_literal: true

# Workshop AI Agent app — Pillar 1 (Ruby).
#
# Sinatra UI + SignalWire AgentBase mounted at /agent via Rack::URLMap.

require 'sinatra/base'
require 'json'
require 'rack'
require 'signalwire'
require_relative 'agent'

SHARED_UI = File.expand_path('../../../../shared/ui', __dir__)

STATE = { creds: nil, numbers: [] }

class WorkshopUI < Sinatra::Base
  set :show_exceptions, false

  get '/' do
    send_file File.join(SHARED_UI, 'creds-form.html')
  end

  get '/demo.js' do
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
      client = SignalWire::REST::RestClient.new(project: project_id, token: token, host: space)
      numbers_resp = client.phone_numbers.list(limit: 20)
    rescue => e
      halt 400, { ok: false, error: "Credential check failed: #{e.message}" }.to_json
    end

    numbers = (numbers_resp.is_a?(Array) ? numbers_resp : []).map do |n|
      { sid: n['sid'], phone_number: n['phone_number'] }
    end

    jwt = ''
    subscriber_id = ''
    begin
      tok = client.fabric.create_subscriber_token(reference: 'workshop-attendee',
                                                   permissions: ['fabric.subscriber.read'])
      if tok.is_a?(Hash)
        jwt = tok['token'].to_s
        subscriber_id = tok['subscriber_id'].to_s
      end
    rescue StandardError
      # Fabric subscriber tokens may not be enabled on the account.
    end

    STATE[:creds] = { project_id: project_id, space: space, token: token }
    STATE[:numbers] = numbers

    { ok: true, jwt: jwt, subscriber_id: subscriber_id, numbers: numbers, agent_path: '/agent' }.to_json
  end

  post '/api/wire-number' do
    content_type :json
    halt 400, { ok: false, error: 'Run /api/setup first' }.to_json unless STATE[:creds]
    data = JSON.parse(request.body.read) rescue {}
    sid = (data['sid'] || '').strip
    public_url = (data['public_url'] || '').strip
    halt 400, { ok: false, error: 'sid + public_url required' }.to_json if sid.empty? || public_url.empty?

    creds = STATE[:creds]
    client = SignalWire::REST::RestClient.new(project: creds[:project_id], token: creds[:token], host: creds[:space])
    voice_url = public_url.chomp('/') + '/agent'
    begin
      client.phone_numbers[sid].update(voice_url: voice_url, voice_method: 'POST')
      { ok: true, voice_url: voice_url }.to_json
    rescue => e
      halt 400, { ok: false, error: "Update failed: #{e.message}" }.to_json
    end
  end
end

# Combine Sinatra UI + AgentBase's Rack app + static file serving.
workshop_agent = WorkshopAgent.new

app = Rack::Builder.new do
  map '/shared' do
    run Rack::Files.new(SHARED_UI)
  end
  map '/agent' do
    run workshop_agent.rack_app
  end
  map '/' do
    run WorkshopUI
  end
end

if $PROGRAM_NAME == __FILE__
  port = ENV.fetch('PORT', '8000').to_i
  Rack::Handler.pick(%w[puma webrick]).run(app, Port: port, Host: '0.0.0.0')
end
