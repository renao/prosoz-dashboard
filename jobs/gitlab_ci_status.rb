require 'httparty'
require 'json'
require 'date'

class GitlabPipelineStatus

  def initialize(config, project_id, branch)
    @config = config
    @project_id = project_id
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
      branch: pipeline['ref'],
      status: pipeline['status'],
      updated_at: DateTime.now.strftime('%H:%M Uhr - %d.%m.%Y')
    }
  end

  private

  def latest_completed_pipeline_for_branch(pipelines_json)
    pipeline = pipelines_json.find do |p|
      has_relevant_status?(p) && is_branch?(p)
    end
  end

  def has_relevant_status?(pipeline)
    pipeline['status'] == 'success' || pipeline['status'] == 'failed'
    #['success', 'failed'].include?(pipeline['status'])
  end

  def is_branch?(pipeline)
    pipeline['ref'] == @branch
  end
end

config = YAML.load_file('config.yml')
teambuilder_ci_status = GitlabPipelineStatus.new config, 5, "master"

SCHEDULER.every '10s', :first_in => 0 do
  pipeline_event = teambuilder_ci_status.retrieve_latest_pipeline_status
  send_event('prosozbauCIStatus', pipeline_event)
end