class Dashing.JiraSprintBoardStatus extends Dashing.Widget

 ready: ->
  # This is fired when the widget is done being rendered
  $(@node).find('img[name="toDoImg"]').attr('src', '/assets/jira_sprint_board_status/todo.png')
  $(@node).find('img[name="progressImg"]').attr('src', '/assets/jira_sprint_board_status/progress.png')
  #$(@node).find('img[name="reviewImg"]').attr('src', '/assets/jira_sprint_board_status/review.png')
  $(@node).find('img[name="testImg"]').attr('src', '/assets/jira_sprint_board_status/test.png')
  $(@node).find('img[name="doneImg"]').attr('src', '/assets/jira_sprint_board_status/done.png')

 onData: (data) ->
   # Handle incoming data
   # You can access the html node of this widget with `@node`
   # Example: $(@node).fadeOut().fadeIn() will make the node flash each time data comes in.
