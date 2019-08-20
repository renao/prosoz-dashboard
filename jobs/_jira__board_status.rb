require 'json'
require 'httparty'

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
      sprint_name: sprint_name,
      sprint: sprint_info,
      backlog: backlog,
      in_progress: in_progress,
      in_review: in_review,
      in_test: in_test,
      done: done
    }
  end


  private

  def get_response_for(resource)
    HTTParty.get(resource, basic_auth: @sprint.jira_auth)
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

  def get_active_sprint_for_view(view_id)
    response = get_response_for(sprint_query_url(view_id))
    sprints = JSON.parse(response.body)['sprints']
    sprints.each do |sprint|
      if sprint['state'] == 'ACTIVE'
        return sprint
      end
    end
  end

  def sprint_query_url(view_id)
    @sprint.jira_resource "rest/greenhopper/1.0/sprintquery/#{view_id}"
  end

  def get_sprint_issues(view_id, sprint_id)
    offset = 0
    issues = Array.new(0)
    begin
      response = get_response_for(sprint_issues_url(view_id, sprint_id, offset))
      page_result = JSON.parse(response.body)
      issues.concat page_result['issues']
      offset = offset + page_result['maxResults']
    end while offset < page_result['total']
    issues
  end

  def sprint_issues_url(view_id, sprint_id, offset)
    @sprint.jira_resource "rest/agile/1.0/board/#{view_id}/sprint/#{sprint_id}/issue?startAt=#{offset}"
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
