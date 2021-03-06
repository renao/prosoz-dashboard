require 'json'
require 'httparty'

class SprintIssues

  def initialize(sprint)
    @sprint = sprint
  end

  def retrieve_issues
    sprint_issues = nil

    view_json = get_view_for_viewid(@sprint.view_id)
    if (view_json)
      sprint_ids = get_active_sprints_for_view(view_json['id'])
      if (sprint_ids)
        sprint_issues = get_sprint_issues(view_json['id'], sprint_ids)
      end
    end
    sprint_issues
  end

  private

  def get_response_for(resource)
    HTTParty.get(resource, basic_auth: @sprint.jira_auth, :verify => false)
  end

  def get_view_for_viewid(view_id)
    response = get_response_for(views_url)
    views = JSON.parse(response.body)['views']
    views.each do |view|
      if view['id'] == view_id
        return view
      end
    end
  end

  def views_url
    @sprint.jira_resource "rest/greenhopper/1.0/rapidviews/list"
  end

  def get_active_sprints_for_view(view_id)
    activeSprintIds = []
    response = get_response_for(sprint_query_url(view_id))
    sprints = JSON.parse(response.body)['sprints']
    sprints.each do |sprint|
      if sprint['state'] == 'ACTIVE'
        activeSprintIds << sprint['id']
      end
    end
    return activeSprintIds
  end

  def sprint_query_url(view_id)
    @sprint.jira_resource "rest/greenhopper/1.0/sprintquery/#{view_id}"
  end

  def get_sprint_issues(view_id, sprint_ids)
    issues = Array.new(0)
    sprint_ids.each do |sprint|
      offset = 0
      begin
        response = get_response_for(sprint_issues_url(view_id, sprint, offset))
        page_result = JSON.parse(response.body)
        issues.concat page_result['issues']
        offset = offset + page_result['maxResults']
      end while offset < page_result['total']
    end
    issues
  end

  def sprint_issues_url(view_id, sprint_id, offset)
    @sprint.jira_resource "rest/agile/1.0/board/#{view_id}/sprint/#{sprint_id}/issue?startAt=#{offset}"
  end

end
