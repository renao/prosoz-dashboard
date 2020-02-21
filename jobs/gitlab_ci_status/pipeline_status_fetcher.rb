class PipelineStatusFetcher

    def initialize(config, project_id, project_name, branch)
      @project_name = project_name
      @config = config
      @branch = branch
      @pipelines_endpoint = "#{@config['gitlab']['api_endpoint']}/projects/#{project_id}/pipelines?ref=#{@branch}"
    end
  
    def retrieve_status
      response = HTTParty.get(@pipelines_endpoint, request_headers)
      json_body = JSON.parse(response.body)

      pipeline = latest_completed_pipeline_for_branch json_body
      {
        name: @project_name,
        branch: @branch,
        pipeline: pipeline['status'],
        updated_at: DateTime.now.strftime('%H:%M Uhr, %d.%m.%Y')
      }
    end
  
    private

    def request_headers
      {
        headers: {
          'Private-Token' => @config['gitlab']['access_token']
        }
      }
    end
  
    def latest_completed_pipeline_for_branch(pipelines_json)
      pipeline = pipelines_json.find do |pipeline|
        has_relevant_status?(pipeline)
      end
    end
  
    def has_relevant_status?(pipeline)
      ['success', 'failed', 'running'].include?(pipeline['status'])
    end
  end