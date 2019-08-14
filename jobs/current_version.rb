require 'httparty'
require 'json'

class CurrentVersion

  def initialize(config)
    @config = config
  end

  def retrieve_latest_version
    response = HTTParty.get(versions_info_url, {
      :basic_auth => {
        :username => @config['jira']['username'],
        :password => @config['jira']['password']
      }
    })
    body = JSON.parse(response.body)
    version = latest_released_version body

    { 
      version_name: version['name'],
      version_description: version['description']
    }
  end

  private

  def latest_released_version(versions_json)
    released_versions = versions_json.select { |v| v['released'] == true }
    released_versions.last
  end
  
  def versions_info_url
    "#{@config['jira']['endpoint']}/project/BAUEN/versions"
  end
end

config = YAML.load_file('config.yml')
current_version = CurrentVersion.new config

SCHEDULER.every '60s', :first_in => 0 do
  
  version_event = current_version.retrieve_latest_version
  send_event('currentVersion', version_event)
end