require 'httparty'
require 'json'
require 'date'
require_relative 'gitlab_ci_status/project'


config = YAML.load_file('config.yml')

projects = config['gitlab']['ci']['projects']
ci_projects = projects.map { |project|  Project.new project, config }

def refresh_ci_states(projects)
  ci_states = []
  projects.each do |project|
    project.refresh
    project_meta = { name: project.name, id: project.id }
    ci_states << {meta: project_meta, pipelines: project.pipeline_states}
  end
  ci_states
end

SCHEDULER.every '10s', :first_in => 0 do
  ci_states = refresh_ci_states ci_projects
  puts ci_states
  send_event("CIStatusUpdate", { ci_states: ci_states })
end