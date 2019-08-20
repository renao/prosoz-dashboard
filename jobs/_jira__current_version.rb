require 'httparty'
require 'json'

class CurrentVersion

  def initialize(jira_sprint)
    @sprint = jira_sprint
  end

  def retrieve_latest_version
    response = get_response_for(versions_info_url)
    body = JSON.parse(response.body)
    version = latest_released_version body

    { 
      version_name: version['name'],
      version_description: version['description']
    }
  end

  private

  def get_response_for(resource)
    HTTParty.get(resource, basic_auth: @sprint.jira_auth)
  end

  def latest_released_version(versions_json)
    released_versions = versions_json.select { |v| v['released'] == true }
    released_versions.last
  end
  
  def versions_info_url
    @sprint.jira_resource "rest/api/2/project/BAUEN/versions"
  end
end