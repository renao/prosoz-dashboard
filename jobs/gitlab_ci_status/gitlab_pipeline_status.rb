class GitlabPipelineStatus

    def initialize(config, project_id, branch)
      @config = config
      @project_id = project_id
      @branch = branch
      @pipelines_endpoint = "#{@config['gitlab']['api_endpoint']}/projects/#{@project_id}/pipelines?ref=#{@branch}"
      puts @pipelines_endpoint
    end
  
    def retrieve_status
      response = HTTParty.get(@pipelines_endpoint, {
        headers: {
          'Private-Token' => @config['gitlab']['access_token']
        }
      })

      json_body = JSON.parse(response.body)
      pipeline = latest_completed_pipeline_for_branch json_body
      {
          branch: pipeline['ref'],
          status: pipeline['status'],
          updated_at: DateTime.now.strftime('%H:%M Uhr, %d.%m.%Y')
      }
    end
  
    private
  
    def latest_completed_pipeline_for_branch(pipelines_json)
      pipeline = pipelines_json.find do |p|
        has_relevant_status?(p)
      end
    end
  
    def has_relevant_status?(pipeline)
      ['success', 'failed'].include?(pipeline['status'])
    end
  end