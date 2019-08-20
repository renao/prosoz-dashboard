require 'httparty'
require 'json'
require 'time'

class RemainingDays

  def initialize(jira_sprint)
    @sprint = jira_sprint
  end

  def remaining_days
    sprint_name = ""
    formatted_days = ""
    view_json = get_sprint_meta
    if (view_json)
      sprint_json = get_active_sprint_for_view(view_json['id'])
      if (sprint_json)
        sprint_name = sprint_json['name']
        days_json = get_remaining_days(view_json['id'], sprint_json['id'])
        days = days_json['days']
        formatted_days = (days == 1) ? '1 Tag' : "#{days} Tage"
      end
    end

    return {
      sprint_name: sprint_name,
      days: formatted_days
    }
  end

  private

  def get_response_for(resource)
    HTTParty.get(resource, basic_auth: @sprint.jira_auth)
  end

  def get_sprint_meta
    response = get_response_for(sprint_meta_url)
    views = JSON.parse(response.body)['views']
    views.find { |view| view['id'] == @sprint.view_id}
  end
  
  def get_active_sprint_for_view(view_id)
    response = get_response_for(sprint_query_url(view_id))
    sprints = JSON.parse(response.body)['sprints']
    sprints.find { |sprint| sprint['state'] == 'ACTIVE'}
  end
  
  def get_remaining_days(view_id, sprint_id)
    response = get_response_for(remaining_days_url(view_id, sprint_id))
    JSON.parse(response.body)
  end

  def sprint_meta_url
    @sprint.jira_resource "rest/greenhopper/1.0/rapidviews/list"
  end

  def sprint_query_url(view_id)
    @sprint.jira_resource "rest/greenhopper/1.0/sprintquery/#{view_id}"
  end

  def remaining_days_url(view_id, sprint_id)
    @sprint.jira_resource "rest/greenhopper/1.0/gadgets/sprints/remainingdays?rapidViewId=#{view_id}&sprintId=#{sprint_id}"
  end
end
