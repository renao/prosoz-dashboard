require 'net/http'
require 'json'

class JiraSprint

  attr_reader :jira_url, :jira_auth, :view_id, :story_points_field_name
  attr_reader :backlog_state_id, :in_progress_state_id, :in_review_state_id
  attr_reader :in_test_state_id, :done_state_id
  def initialize(config, sprint_view_id)
    @config = config
    @jira_url = URI.parse(@config['jira']['url'])
    @view_id = sprint_view_id
    @story_points_field_name = @config['jira']['customfield']['storypoints']
    @jira_auth = {
      username: @config['jira']['username'],
      password: @config['jira']['password']
    }
    @backlog_state_id = @config['jira']['states']['backlog']
    @in_progress_state_id = @config['jira']['states']['in_progress']
    @in_review_state_id = @config['jira']['states']['in_review']
    @in_test_state_id = @config['jira']['states']['in_test']
    @done_state_id = @config['jira']['states']['done']
  end

  def jira_resource(path)
    @jira_url + path
  end
end