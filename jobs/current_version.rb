require 'httparty'
require 'json'

config = YAML.load_file('config.yml')
USERNAME = config['confluence']['username']
PASSWORD = config['confluence']['password']
ENDPOINT = config['confluence']['endpoint']

confluence_uri = "#{ENDPOINT}content/8389025?expand=body.storage"

SCHEDULER.every '30s' do
  response = HTTParty.get(confluence_uri, {
    :basic_auth => {
      :username => USERNAME
      :password => PASSWORD
    }
  })
  body = JSON.parse(response.body)

  send_event('currentVersion', { version_name: body['body']['storage']['value'].gsub(/<\/?[^>]*>/, "") })
end