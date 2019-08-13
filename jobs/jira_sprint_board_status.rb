# Displays the status of the current open sprint

require 'net/http'
require 'json'
require 'time'

# Loads configuration file
config = YAML.load_file('config.yml')
USERNAME = config['jira']['username']
PASSWORD = config['jira']['password']
JIRA_URI = URI.parse(config['jira']['url'])
STORY_POINTS_CUSTOMFIELD_CODE = config['jira']['customfield']['storypoints']
VIEW_ID = config['jira']['view']

BACKLOG_STATE_ID = config['jira']['states']['backlog']
IN_PROGRESS_STATE_ID = config['jira']['states']['in_progress']
IN_REVIEW_STATE_ID = config['jira']['states']['in_review']
IN_TEST_STATE_ID = config['jira']['states']['in_test']
DONE_STATE_ID = config['jira']['states']['done']

# gets the view for a given view id
def get_view_for_viewid(view_id)
  http = create_http
  request = create_request("/rest/greenhopper/1.0/rapidviews/list")
  response = http.request(request)
  views = JSON.parse(response.body)['views']
  views.each do |view|
    if view['id'] == view_id
      return view
    end
  end
end

# gets the active sprint for the view
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

# def get_issues_per_status(view_id, sprint_id, issue_count_array, issue_sp_count_array)
#   current_start_at = 0 # offset for pagination
# 
#   begin
#     response = get_response("/rest/agile/1.0/board/#{view_id}/sprint/#{sprint_id}/issue?startAt=#{current_start_at}")
#     page_result = JSON.parse(response.body)
#     issue_array = page_result['issues']
# 
#     issue_array.each do |issue|
#       accumulate_issue_information(issue, issue_count_array, issue_sp_count_array)
#     end
# 
#     current_start_at = current_start_at + page_result['maxResults']
#   end while current_start_at < page_result['total']
# end

def get_sprint_issues(view_id, sprint_id)
  offset = 0
  issues = Hash.new(0)
  begin
    response = get_response("/rest/agile/1.0/board/#{view_id}/sprint/#{sprint_id}/issue?startAt=#{offset}")
    page_result = JSON.parse(response.body)
    issues.merge page_result['issues']
    offset = offset + page_result['maxResults']
  end while offset < page_result['total']
  issues
end

# def accumulate_issue_information(issue, issue_count_array, issue_sp_count_array)
#   case issue['fields']['status']['id']
#     when "1", "2", "10103" # Backlog
#       if !issue['fields']['issuetype']['subtask']
#         issue_count_array[0] = issue_count_array[0] + 1
#       end
#       if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
#         issue_sp_count_array[0] = issue_sp_count_array[0] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
#       end
#     when "3", "4" # In Bearbeitung
#       if !issue['fields']['issuetype']['subtask']
#         issue_count_array[1] = issue_count_array[1] + 1
#       end
#       if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
#         issue_sp_count_array[1] = issue_sp_count_array[1] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
#       end
#     when "10105" # In Akzeptanztest
#       if !issue['fields']['issuetype']['subtask']
#         issue_count_array[2] = issue_count_array[2] + 1
#       end
#       if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
#         issue_sp_count_array[2] = issue_sp_count_array[2] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
#       end
#     when "5", "6", "10001", "10102" # Done
#       if !issue['fields']['issuetype']['subtask']
#         issue_count_array[3] = issue_count_array[3] + 1
#       end
#       if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
#         issue_sp_count_array[3] = issue_sp_count_array[3] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
#       end
#     else
#       puts "ERROR: wrong issue status #{issue['fields']['status']['id']}" 
#   end
# 
#   issue_count_array[4] = issue_count_array[4] + 1
#   if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
#     issue_sp_count_array[4] = issue_sp_count_array[4] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
#   end
# end
 
def create_http
  http = Net::HTTP.new(JIRA_URI.host, JIRA_URI.port)
  if ('https' == JIRA_URI.scheme)
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  return http
end

def create_request(path)
  request = Net::HTTP::Get.new(JIRA_URI.path + path)
  if USERNAME
    request.basic_auth(USERNAME, PASSWORD)
  end
  return request
end

def get_response(path)
  http = create_http
  request = create_request(path)
  response = http.request(request)

  return response
end

def collect_sprint_info(sprint_json)
  {
    :sprint_tickets => "-",
    :sprint_sp => "-",
    :sprint_task_force => "-",
    :sprint_kleinkram => "-"
  }
end

def dummy_state_info
  {
    :tickets => "-",
    :story_points => "-",
    :task_force => "-",
    :kleinkram => "-"
  }
end

def retrieve_backlog_infos(sprint_issues)
  backlog_state = {
    :tickets => 0,
    :story_points => 0,
    :task_force => 0,
    :kleinkram => 0
  }

  sprint_issues.each |issue|
    if is_state?(issue, BACKLOG_STATE_ID) && !is_subtask?(issue)
      backlog_state[:tickets] += 1
      backlog_state[:story_points] += story_points(issue)
      backlog_state[:task_force] += is_taskforce?(issue) ? 1 : 0
      backlog_state[:kleikram] += is_kleinkram?(issue) ? 1 : 0
    end

  backlog_state
end


def retrieve_in_progress_infos(sprint_issues)
  dummy_state_info
end

def retrieve_in_review_infos(sprint_issues)
  dummy_state_info
end

def retrieve_in_test_infos(sprint_issues)
  dummy_state_info
end

def retrieve_done_infos(sprint_issues)
  dummy_state_info
end

def is_subtask?(issue)
  issue['fields']['issuetype']['subtask']
end

def is_state?(issue, expected_state_id)
  issue['fields']['status']['id'] == expected_state_id
end

def story_points(issue)
  !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil? ? issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE] : 0
end

def is_kleinkram?(issue)
  issue['fields']['labels'].include?('Kleinkram')
end

def is_taskforce?(issue)
  issue['fields']['labels'].include?('TaskForce')
end

SCHEDULER.every '8s', :first_in => 0 do

  sprint_name = ''
  sprint_info = Hash.new(0)
  backlog = Hash.new(0)
  in_progress = Hash.new(0)
  in_review = Hash.new(0)
  in_test = Hash.new(0)
  done = Hash.new(0)

  view_json = get_view_for_viewid(VIEW_ID)
  if (view_json)
    sprint_meta = get_active_sprint_for_view(view_json['id'])
    if (sprint_meta)
      sprint_issues = get_sprint_issues(view_json['id'], sprint_json['id'])
      sprint_name = sprint_meta['name']

      backlog = retrieve_backlog_infos sprint_issues
      in_progress = retrieve_in_progress_infos sprint_issues #todo
      in_review = retrieve_in_review_infos sprint_issues #todo
      in_test = retrieve_in_test_infos sprint_issues #todo
      done = retrieve_done_infos sprint_issues #todo

      sprint_info = collect_sprint_info sprint_issues #todo - sum everything else?

      # get_issues_per_status(view_json['id'], sprint_json['id'], issue_count_array, issue_sp_count_array)
    end
  end
  send_event('boardStatus', {
      sprintName: sprint_name,
      sprintTickets: sprint_info[:sprint_tickets],
      sprintSP: sprint_info[:sprint_sp],
      sprintTaskForce: sprint_info[:sprint_task_force],
      sprintKleinkram: sprint_info[:sprint_kleinkram],

      backlogTickets: backlog[:tickets],
      backlogSP: backlog[:story_points],
      backlogTaskForce: backlog[:task_force],
      backlogKleinkram: backlog[:kleinkram],

      inProgressTickets: in_progress[:tickets],
      inProgressSP: in_progress[:story_points],
      inProgressTaskForce: in_progress[:task_force],
      inProgressKleinkram: in_progress[:kleinkram],

      inReviewTickets: in_review[:tickets],
      inReviewSP: in_review[:story_points],
      inReviewTaskForce: in_review[:task_force],
      inReviewKleinkram: in_review[:kleinkram],

      inTestTickets: in_test[:tickets],
      inTestSP: in_test[:story_points],
      inTestTaskForce: in_test[:task_force],
      inTestKleinkram: in_test[:kleinkram],

      doneTickets: done[:tickets],
      doneSP: done[:story_points],
      doneTaskForce: done[:task_force],
      doneKleinkram: done[:kleinkram]
  })
end

