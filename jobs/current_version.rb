require 'httparty'
require 'json'

config = YAML.load_file('config.yml')
USERNAME = config['confluence']['username']
PASSWORD = config['confluence']['password']
ENDPOINT = config['jira']['endpoint']

versions_uri = "#{ENDPOINT}/project/BAUEN/versions"

SCHEDULER.every '60s' :first_in => 0 do
  response = HTTParty.get(versions_uri, {
    :basic_auth => {
      :username => USERNAME,
      :password => PASSWORD
    }
  })
  body = JSON.parse(response.body)

  version = latest_released_version body

  puts version

  send_event('currentVersion', { 
    version_name: version['name'],
    version_description: version['description'] })
end

def latest_released_version(versions_json)
  released_versions = versions_json.select { |v| v['released'] == true }
  released_versions.last
end