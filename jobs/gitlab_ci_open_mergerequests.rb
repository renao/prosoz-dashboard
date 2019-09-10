require 'httparty'
require 'json'
require 'date'

class GitlabOpenMergeRequests

  def initialize(config, project_id)
    @config = config
    @project_id = project_id
    @mergerequest_endpoint = "#{@config['gitlab']['api_endpoint']}/projects/#{@project_id}/merge_requests?state=opened"
  end

  def retrieve_open_mergerequests
    response = HTTParty.get(@mergerequest_endpoint, {
      :headers => {
        'Private-Token' => @config['gitlab']['access_token']
      }
    })

    mergerequestlist = JSON.parse(response.body)

    return {
      mergerequests: mergerequestlist,
      hasNoIssues: mergerequestlist.empty?,
      updated_at: DateTime.now.strftime('%H:%M Uhr, %d.%m.%Y')
    }
  end
end

config = YAML.load_file('config.yml')
openMergeRequestsProsozBau = GitlabOpenMergeRequests.new config, 10

SCHEDULER.every '30s', :first_in => 0 do
  openMergeRequestsProsozBau_data = openMergeRequestsProsozBau.retrieve_open_mergerequests
  send_event('openMergeRequestsProsozBau', openMergeRequestsProsozBau_data)
end