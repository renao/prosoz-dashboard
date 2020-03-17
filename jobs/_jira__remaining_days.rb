require 'httparty'
require 'json'
require 'business_time'

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
        endDate = get_active_sprint_endDate(sprint_json['id'])
        days = get_business_days_until(endDate)
        formatted_days = (days == 1) ? '1 Tag' : "#{days} Tage"
      end
    end

    return {
      sprint_name: sprint_name,
      days: formatted_days
    }
  end

  private

  def get_business_days_until(endDate)
    return DateTime.now.business_days_until(Date.parse(endDate))
  end

  def get_response_for(resource)
    HTTParty.get(resource, basic_auth: @sprint.jira_auth, :verify => false)
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
  
  def get_active_sprint_endDate(sprint_id)
    response = get_response_for(sprint_url(sprint_id))
    sprint = JSON.parse(response.body)
    sprint['endDate']
  end

  def sprint_meta_url
    @sprint.jira_resource "rest/greenhopper/1.0/rapidviews/list"
  end

  def sprint_query_url(view_id)
    @sprint.jira_resource "rest/greenhopper/1.0/sprintquery/#{view_id}"
  end

  def sprint_url(sprint_id)
    @sprint.jira_resource "rest/agile/1.0/sprint/#{sprint_id}"
  end
end
