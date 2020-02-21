class Dashing.GitlabCIStatus extends Dashing.Widget

  ready: ->

  onData: (data) ->
    console.log data

  Batman.Filters.classByPipelineStatus = (status) ->
    if status == 'success'
      'pipeline-status--success'
    else if status == 'failed'
      'pipeline-status--failed'
    else
      'pipeline-status--running'
