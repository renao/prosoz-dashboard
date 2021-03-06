require 'httparty'
require 'json'
require 'date'

class GitlabOpenMergeRequests

  def initialize(config, project_id)
    @config = config
    @project_id = project_id
    @mergerequest_endpoint = "#{@config['gitlab']['api_endpoint']}/projects/#{@project_id}/merge_requests?state=opened&wip=no"
  end

  def retrieve_open_mergerequests
    response = HTTParty.get(@mergerequest_endpoint, {
      :headers => {
        'Private-Token' => @config['gitlab']['access_token']
      }
    })

    mergerequestlist = JSON.parse(response.body)

    redirect_resources(mergerequestlist)

    return {
      mergerequests: mergerequestlist,
      hasNoIssues: mergerequestlist.empty?,
      updated_at: DateTime.now.strftime('%H:%M Uhr, %d.%m.%Y')
    }
  end

  private

  def redirect_resources(merge_requests_list)
    if @config['gitlab']['redirect_resources'] == true
      merge_requests_list.each do |request|
        if valid_assignee?(request)
          if (valid_avatar_url?(request['assignee']))
            request['assignee']['avatar_url'].gsub!(@config['gitlab']['redirect']['from'], @config['gitlab']['redirect']['to'])
          else
            request['assignee']['avatar_url'] = fallback_avatar_url
          end
        end
      end
    end
  end

  def valid_assignee?(request)
    request.key?('assignee') && !request['assignee'].nil?
  end

  def valid_avatar_url?(assignee)
    assignee.key?('avatar_url') && !assignee['avatar_url'].nil?
  end

  def fallback_avatar_url
    @config['gitlab']['fallback_user_avatar_url']
  end
end

config = YAML.load_file('config.yml')
openMergeRequestsProsozBau = GitlabOpenMergeRequests.new config, 10

SCHEDULER.every '30s', :first_in => 0 do
  openMergeRequestsProsozBau_data = openMergeRequestsProsozBau.retrieve_open_mergerequests
  send_event('openMergeRequestsProsozBau', openMergeRequestsProsozBau_data)
end
