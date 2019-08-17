require 'httparty'
require 'json'

class CurrentVersion

  def initialize(jira_sprint)
    @sprint = jira_sprint
  end

  def retrieve_latest_version
    response = HTTParty.get(versions_info_url, {
      :basic_auth => @sprint.jira_auth
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
    "#{@sprint.jira_url}/project/BAUEN/versions"
  end
end