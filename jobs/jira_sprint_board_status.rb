require 'net/http'
require 'json'
require 'time'

class BoardStatus

  def initialize(sprint)
    @sprint = sprint
  end

  def retrieve_sprint_status
    sprint_name = ''
    sprint_info = Hash.new(0)
    backlog = Hash.new(0)
    in_progress = Hash.new(0)
    in_review = Hash.new(0)
    in_test = Hash.new(0)
    done = Hash.new(0)

    view_json = get_view_for_viewid(@sprint.view_id)
    if (view_json)
      sprint_meta = get_active_sprint_for_view(view_json['id'])
      if (sprint_meta)
        sprint_issues = get_sprint_issues(view_json['id'], sprint_meta['id'])
        sprint_name = sprint_meta['name']

        backlog = retrieve_state_infos sprint_issues, @sprint.backlog_state_id
        in_progress = retrieve_state_infos sprint_issues, @sprint.in_progress_state_id
        in_review = retrieve_state_infos sprint_issues, @sprint.in_review_state_id
        in_test = retrieve_state_infos sprint_issues, @sprint.in_test_state_id
        done = retrieve_state_infos sprint_issues, @sprint.done_state_id

        sprint_info = accumulate_sprint backlog, in_progress, in_review, in_test, done
      end
    end

    return {
      sprint: sprint_info,
      backlog: backlog,
      in_progress: in_progress,
      in_review: in_review,
      in_test: in_test,
      done: done
    }
  end


  private

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

  def get_sprint_issues(view_id, sprint_id)
    offset = 0
    issues = Array.new(0)
    begin
      response = get_response("/rest/agile/1.0/board/#{view_id}/sprint/#{sprint_id}/issue?startAt=#{offset}")
      page_result = JSON.parse(response.body)
      issues.concat page_result['issues']
      offset = offset + page_result['maxResults']
    end while offset < page_result['total']
    issues
  end
  
  def create_http
    http = Net::HTTP.new(@sprint.jira_url.host, @sprint.jira_url.port)
    if ('https' == @sprint.jira_url.scheme)
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    return http
  end

  def create_request(path)
    request = Net::HTTP::Get.new(@sprint.jira_url.path + path)
    if
      request.basic_auth(@sprint.jira_auth['username'], @sprint.jira_auth['password'])
    end
    return request
  end

  def get_response(path)
    http = create_http
    request = create_request(path)
    response = http.request(request)

    return response
  end

  def retrieve_state_infos(sprint_issues, state_id)
    state = empty_state

    sprint_issues.each do |issue|
      if is_state?(issue, state_id) && !is_subtask?(issue)
        state[:tickets] = state[:tickets] + 1
        state[:story_points] = state[:story_points] + story_points(issue)
        state[:task_force] = state[:task_force] + (is_taskforce?(issue) ? 1 : 0)
        state[:kleikram] = state[:kleinkram] + (is_kleinkram?(issue) ? 1 : 0)
      end
    end

    state
  end

  def is_subtask?(issue)
    issue['fields']['issuetype']['subtask']
  end

  def is_state?(issue, expected_state_id)
    issue['fields']['status']['id'] == expected_state_id
  end

  def story_points(issue)
    !issue['fields'][@sprint.story_points_field_name].nil? ? issue['fields'][@sprint.story_points_field_name] : 0
  end

  def is_kleinkram?(issue)
    issue['fields']['labels'].include?('Kleinkram')
  end

  def is_taskforce?(issue)
    issue['fields']['labels'].include?('TaskForce')
  end

  def accumulate_sprint(*states)
    sum = empty_state
    states.each do |state|
      sum[:tickets] = sum[:tickets] + state[:tickets]
      sum[:story_points] = sum[:story_points] + state[:story_points]
      sum[:task_force] = sum[:task_force] + state[:task_force]
      sum[:kleinkram] = sum[:kleinkram] + state[:kleinkram]
    end
    sum
  end

  def empty_state
    {
      tickets: 0,
      story_points: 0,
      task_force: 0,
      kleinkram: 0
    }
  end

end

board_status = BoardStatus.new JIRA_SPRINT

SCHEDULER.every '20s', first_in: 0 do
  state = board_status.retrieve_sprint_status

  sprint_info = state[:sprint]
  backlog = state[:backlog]
  in_progress = state[:in_progress]
  in_review = state[:in_review]
  in_test = state[:in_test]
  done = state[:done]

  send_event('boardStatus', {
      sprintName: sprint_name,
      sprintTickets: sprint_info[:tickets],
      sprintSP: sprint_info[:story_points],
      sprintTaskForce: sprint_info[:task_force],
      sprintKleinkram: sprint_info[:kleinkram],

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

