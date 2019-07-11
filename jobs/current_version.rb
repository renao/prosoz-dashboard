require 'httparty'
require 'json'

retrieve_version_uri = 'https://graph.facebook.com'

SCHEDULER.every '3s' do
  response_body = {
    "version": "2019.8.1"
  }.to_json

  response = HTTParty.get(retrieve_version_uri)
  body = JSON.parse(response.body)

  send_event('currentVersion', { version_name: body['error']['code'] })
end