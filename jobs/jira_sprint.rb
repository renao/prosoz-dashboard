require 'net/http'
require 'json'
require_relative '_jira__current_version'
require_relative '_jira__remaining_days'

class JiraSprint

  attr_reader :jira_url, :jira_auth, :view_id, :story_points_field_name
  attr_reader :backlog_state_id, :in_progress_state_id, :in_review_state_id
  attr_reader :in_test_state_id, :done_state_id
  def initialize(config)
    @config = config
    @jira_url = URI.parse(@config['jira']['url'])
    @view_id = @config['jira']['view']
    @story_points_field_name = @config['jira']['customfield']['storypoints']
    @jira_auth = {
      'name' => @config['jira']['username'],
      'password' => @config['jira']['password']
    }
    @backlog_state_id = @config['jira']['states']['backlog']
    @in_progress_state_id = @config['jira']['states']['in_progress']
    @in_review_state_id = @config['jira']['states']['in_review']
    @in_test_state_id = @config['jira']['states']['in_test']
    @done_state_id = @config['jira']['states']['in_progress']
  end
end

config = YAML.load_file('config.yml')
JIRA_SPRINT = JiraSprint.new config

current_version = CurrentVersion.new JIRA_SPRINT
remaining_sprint_days = RemainingDays.new JIRA_SPRINT

SCHEDULER.every '30s', first_in: 0 do
  version_event = current_version.retrieve_latest_version
  send_event('currentVersion', version_event)

  remaining = remaining_sprint_days.remaining_days

  send_event('view1', {
    sprintName: remaining[:sprint_name],
    daysRemaining: remaining[:days]
  })
end