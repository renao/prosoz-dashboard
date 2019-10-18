require 'json'
require 'httparty'

class BoardStatus

  def initialize(sprint)
    @sprint = sprint
  end

  def sprint_infos_from(sprint_issues)
    backlog = retrieve_state_infos sprint_issues, @sprint.backlog_state_id
    in_progress = retrieve_state_infos sprint_issues, @sprint.in_progress_state_id
    in_review = retrieve_state_infos sprint_issues, @sprint.in_review_state_id
    in_test = retrieve_state_infos sprint_issues, @sprint.in_test_state_id
    done = retrieve_state_infos sprint_issues, @sprint.done_state_id

    sprint_info = accumulate_sprint backlog, in_progress, in_review, in_test, done

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

  def retrieve_state_infos(sprint_issues, state_id)
    state = empty_state

    sprint_issues.each do |issue|
      if is_state?(issue, state_id) && !is_subtask?(issue)
        state[:tickets] = state[:tickets] + 1
        state[:story_points] = state[:story_points] + story_points(issue)
        state[:task_force] = state[:task_force] + (is_taskforce?(issue) ? 1 : 0)  
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

  def is_taskforce?(issue)
    issue['fields']['labels'].include?('TaskForce')
  end

  def accumulate_sprint(*states)
    sum = empty_state
    states.each do |state|
      sum[:tickets] = sum[:tickets] + state[:tickets]
      sum[:story_points] = sum[:story_points] + state[:story_points]
      sum[:task_force] = sum[:task_force] + state[:task_force]
    end
    sum
  end

  def empty_state
    {
      tickets: 0,
      story_points: 0,
      task_force: 0
    }
  end

end
