require 'httparty'
require 'json'
require 'date'
require_relative 'gitlab_ci_status/project'
require_relative 'gitlab_ci_status/gitlab_pipeline_status'


config = YAML.load_file('config.yml')

projects = config['gitlab']['ci']['projects']
ci_projects = projects.map { |project|  Project.new(project) }

#mobile_develop_ci_status = GitlabPipelineStatus.new config, 2, "develop", "Mobile Client"
#team_builder_master_ci_status = GitlabPipelineStatus.new config, 5, "master", "Team Builder"
rich_client_master_ci_status = GitlabPipelineStatus.new config, 10, "master", "PROSOZ Bau Rich Client", -> (event_data) { send_event("richClientCIStatusMaster", event_data) }
rich_client_develop_ci_status = GitlabPipelineStatus.new config, 10, "develop", "PROSOZ Bau Rich Client", -> (event_data) { send_event("richClientCIStatusDevelop", event_data) }
#prosoz_services_develop_ci_status = GitlabPipelineStatus.new config, 18, "develop", "PROSOZ Services (XmlService)"
#prosoz_services_master_ci_status = GitlabPipelineStatus.new config, 18, "master", "PROSOZ Services (XmlService)"
#bauportal_master_ci_status = GitlabPipelineStatus.new config, 19, "master", "BauPortal"
#bauportal_develop_ci_status = GitlabPipelineStatus.new config, 19, "develop", "BauPortal"

SCHEDULER.every '10s', :first_in => 0 do

  ci_projects.each { |project| project.update_pipelines }

  rich_client_master_event_data = rich_client_master_ci_status.retrieve_latest_pipeline_status
  # send_event("richClientCIStatusMaster", rich_client_master_event_data)

  rich_client_develop_event_data = rich_client_develop_ci_status.retrieve_latest_pipeline_status
  # send_event("richClientCIStatusDevelop", rich_client_develop_event_data)

  #mobile_develop_event_data = mobile_develop_ci_status.retrieve_latest_pipeline_status
  #send_event('mobileCIStatusDevelop', mobile_develop_event_data)
  
  #team_builder_master_event_data = team_builder_master_ci_status.retrieve_latest_pipeline_status
  #send_event("teamBuilderCIStatusMaster", team_builder_master_event_data)
end