require 'httparty'
require 'json'
require 'date'

class GitlabPipelineStatus

  def initialize(config, project_id, branch, project_name)
    @config = config
    @project_id = project_id
    @project_name = project_name
    @branch = branch
    @pipelines_endpoint = "#{@config['gitlab']['api_endpoint']}/projects/#{@project_id}/pipelines"
  end

  def retrieve_latest_pipeline_status
    response = HTTParty.get(@pipelines_endpoint, {
      :headers => {
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
      has_relevant_status?(p) && is_branch?(p)
    end
  end

  def has_relevant_status?(pipeline)
    ['success', 'failed'].include?(pipeline['status'])
  end

  def is_branch?(pipeline)
    pipeline['ref'] == @branch
  end
end

config = YAML.load_file('config.yml')
mobile_develop_ci_status = GitlabPipelineStatus.new config, 2, "develop", "Mobile Client"
team_builder_master_ci_status = GitlabPipelineStatus.new config, 5, "master", "Team Builder"

SCHEDULER.every '10s', :first_in => 0 do
  mobile_develop_event_data = mobile_develop_ci_status.retrieve_latest_pipeline_status
  send_event('mobileCIStatusDevelop', mobile_develop_event_data)
  
  team_builder_master_event_data = team_builder_master_ci_status.retrieve_latest_pipeline_status
  send_event("teamBuilderCIStatusMaster", team_builder_master_event_data)
end