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

  def get_sprint_meta
    response = HTTParty.get(sprint_meta_url, { basic_auth: @sprint.jira_auth })

    views = JSON.parse(response.body)['views']
    views.each do |view|
      if view['id'] == @sprint.view_id
        return view
      end
    end
  end

  def sprint_meta_url
    "#{@sprint.jira_url}/rest/greenhopper/1.0/rapidviews/list"
  end
  
  def get_active_sprint_for_view(view_id)
    response = HTTParty.get(sprint_query_url(view_id), { basic_auth: @sprint.jira_auth })
    
    sprints = JSON.parse(response.body)['sprints']
    sprints.each do |sprint|
      if sprint['state'] == 'ACTIVE'
        return sprint
      end
    end
  end

  def sprint_query_url(view_id)
    "#{@sprint.jira_url}/rest/greenhopper/1.0/sprintquery/#{view_id}"
  end
  
  def get_remaining_days(view_id, sprint_id)
    response = HTTParty.get(remaining_days_url(view_id, sprint_id), { basic_auth: @sprint.jira_auth })
    JSON.parse(response.body)
  end

  def remaining_days_url(view_id, sprint_id)
    "#{@sprint.jira_url}/rest/greenhopper/1.0/gadgets/sprints/remainingdays?rapidViewId=#{view_id}&sprintId=#{sprint_id}"
  end
end

remaining_sprint_days = RemainingDays.new JIRA_SPRINT

SCHEDULER.every '20s', first_in: 0 do |id|
  
  remaining = remaining_sprint_days.remaining_days

  send_event('view1', {
    sprintName: remaining[:sprint_name],
    daysRemaining: remaining[:formatted_days]
  })
end
