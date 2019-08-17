require 'net/http'
require 'json'
require 'time'

view_mapping = {
  'view1' => { :view_id => JIRA_SPRINT.view_id },
}

class RemainingDays

  def initialize(jira_sprint)
    @sprint = jira_sprint
  end

  def remaining_days
    view_name = ""
    sprint_name = ""
    days = ""
    view_json = get_sprint_meta
    if (view_json)
      view_name = view_json['name']
      sprint_json = get_active_sprint_for_view(view_json['id'])
      if (sprint_json)
        sprint_name = sprint_json['name']
        days_json = get_remaining_days(view_json['id'], sprint_json['id'])
        days = days_json['days']

        formatted_days = (days == 1) ? '1 Tag' : "#{days} Tage"
      end
    end
  end


  private

  def get_sprint_meta
    http = create_http
    request = create_request("/rest/greenhopper/1.0/rapidviews/list")
    response = http.request(request)
    views = JSON.parse(response.body)['views']
    views.each do |view|
      if view['id'] == @sprint.view_id
        return view
      end
    end
  end
  
  def get_active_sprint_for_view(view_id)
    http = create_http
    request = create_request("/rest/greenhopper/1.0/sprintquery/#{view_id}")
    response = http.request(request)
    sprints = JSON.parse(response.body)['sprints']
    sprints.each do |sprint|
      if sprint['state'] == 'ACTIVE'
        return sprint
      end
    end
  end
  
  def get_remaining_days(view_id, sprint_id)
  
    http = create_http
    request = create_request("/rest/greenhopper/1.0/gadgets/sprints/remainingdays?rapidViewId=#{view_id}&sprintId=#{sprint_id}")
    response = http.request(request)
    JSON.parse(response.body)
  end
  
  def create_http
    http = Net::HTTP.new(@sprint.jira_url.host, @sprint.jira_url.port)
    if ('https' == @sprint.jira_url.scheme)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    return http
  end
  
  def create_request(path)
    request = Net::HTTP::Get.new(@sprint.jira_url.path + path)
    if @sprint.jira_auth['username']
      request.basic_auth(@sprint.jira_auth['username'], @sprint.jira_auth['password'])
    end
    return request
  end
end

remaining_sprint_days = RemainingDays.new JIRA_SPRINT

SCHEDULER.every '20s', :first_in => 0 do |id|
  
  data = remaining_sprint_days.remaining_days

  send_event('view1', {
    viewName: view_name,
    sprintName: sprint_name,
    daysRemaining: formatted_days
  })
end
