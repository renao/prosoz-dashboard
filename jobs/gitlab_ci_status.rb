require 'httparty'
require 'json'
require 'date'

class GitlabPipelineStatus

  def initialize(config, project_id, branch, project_name)
    @config = config
    @project_id = project_id
    @project_name = project_name
    @branch = branch
    @pipelines_endpoint = "#{@config['gitlab']['api_endpoint']}/projects/#{@project_id}/pipelines?ref=#{@branch}"
  end

  def retrieve_latest_pipeline_status
    response = HTTParty.get(@pipelines_endpoint, {
      headers: {
        'Private-Token' => @config['gitlab']['access_token']
      }
    })

    body = JSON.parse(response.body)
    pipeline = latest_completed_pipeline_for_branch body
    return {
      project: @project_name,
      branch: pipeline['ref'],
      status: pipeline['status'],
      updated_at: DateTime.now.strftime('%H:%M Uhr, %d.%m.%Y')
    }
  end

  private

  def latest_completed_pipeline_for_branch(pipelines_json)
    pipeline = pipelines_json.find do |p|
      has_relevant_status?(p)
    end
  end

  def has_relevant_status?(pipeline)
    ['success', 'failed'].include?(pipeline['status'])
  end
end

config = YAML.load_file('config.yml')
#mobile_develop_ci_status = GitlabPipelineStatus.new config, 2, "develop", "Mobile Client"
#team_builder_master_ci_status = GitlabPipelineStatus.new config, 5, "master", "Team Builder"
rich_client_master_ci_status = GitlabPipelineStatus.new config, 10, "master", "PROSOZ Bau Rich Client"
rich_client_develop_ci_status = GitlabPipelineStatus.new config, 10, "develop", "PROSOZ Bau Rich Client"
#prosoz_services_develop_ci_status = GitlabPipelineStatus.new config, 18, "develop", "PROSOZ Services (XmlService)"
#prosoz_services_master_ci_status = GitlabPipelineStatus.new config, 18, "master", "PROSOZ Services (XmlService)"
#bauportal_master_ci_status = GitlabPipelineStatus.new config, 19, "master", "BauPortal"
#bauportal_develop_ci_status = GitlabPipelineStatus.new config, 19, "develop", "BauPortal"

SCHEDULER.every '10s', :first_in => 0 do
  rich_client_master_event_data = rich_client_master_ci_status.retrieve_latest_pipeline_status
  send_event("richClientCIStatusMaster", rich_client_master_event_data)

  rich_client_develop_event_data = rich_client_develop_ci_status.retrieve_latest_pipeline_status
  send_event("richClientCIStatusDevelop", rich_client_develop_event_data)

  #mobile_develop_event_data = mobile_develop_ci_status.retrieve_latest_pipeline_status
  #send_event('mobileCIStatusDevelop', mobile_develop_event_data)
  
  #team_builder_master_event_data = team_builder_master_ci_status.retrieve_latest_pipeline_status
  #send_event("teamBuilderCIStatusMaster", team_builder_master_event_data)
end