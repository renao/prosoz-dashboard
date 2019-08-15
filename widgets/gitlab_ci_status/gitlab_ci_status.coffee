class Dashing.GitlabCIStatus extends Dashing.Widget

  onData: (data) ->

    if (data != null && data.status == "success")
        @node.className = "widget widget-gitlab-ci-status ci-status-success"
    else
        @node.className = "widget widget-gitlab-ci-status ci-status-failed"