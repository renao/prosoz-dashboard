class OpenTaskForceIssues

  def filter_from(sprint_issues)
    tf_issues = sprint_issues.select { |issue| is_taskforce?(issue) && is_unassigned?(issue) }
    prepare! tf_issues
    tf_issues
  end

  private

  def prepare!(issues)
    issues.map { |issue| issue['formatted_date'] = format_date issue['fields']['created'] }
  end

  def format_date(str_date)
    # Keine Lust auf DateTime Gefrickel bisher... :-(
    year = str_date[0..3]
    month = str_date[5..6]
    day = str_date[8..9]

    "#{day}.#{month}.#{year}"
  end

  def is_taskforce?(issue)
    issue['fields']['labels'].include?('TaskForce')
  end

  def is_unassigned?(issue)
    issue['fields']['assignee'] == nil
  end
end
