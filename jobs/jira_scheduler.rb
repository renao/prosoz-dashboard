require_relative '_jira__current_version'
require_relative '_jira__remaining_days'
require_relative '_jira__sprint'

config = YAML.load_file 'config.yml'
rich_client_sprint = JiraSprint.new config

current_version = CurrentVersion.new rich_client_sprint
remaining_sprint_days = RemainingDays.new rich_client_sprint
board_status = BoardStatus.new rich_client_sprint

SCHEDULER.every '30s', first_in: 0 do
  version_event = current_version.retrieve_latest_version
  send_event('currentVersion', version_event)

  remaining = remaining_sprint_days.remaining_days

  send_event('view1', {
    sprintName: remaining[:sprint_name],
    daysRemaining: remaining[:days]
  })

  state = board_status.retrieve_sprint_status

  sprint_info = state[:sprint]
  backlog = state[:backlog]
  in_progress = state[:in_progress]
  in_review = state[:in_review]
  in_test = state[:in_test]
  done = state[:done]

  send_event('boardStatus', {
      sprintName: state[:sprint_name],
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