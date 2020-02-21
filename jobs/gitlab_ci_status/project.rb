class Project
    require_relative 'pipeline_status'
    require_relative 'pipeline_status_fetcher'

    attr_reader :name, :id, :pipeline_states

    def initialize(project_hash, config)
        @id = project_hash['project_id']
        @name = project_hash['name']
        @branches = project_hash['branches']

        init_pipelines config
    end

    def refresh
        @pipeline_states = []
        @pipelines.each { |branch, pipeline|
            @pipeline_states << pipeline.retrieve_status
        }
    end

    private
    def init_pipelines(config)
        @pipelines = {}
        @pipeline_states = []
        @branches.each do |branch|
            @pipelines[branch] = PipelineStatusFetcher.new config, @id, @name, branch
            refresh
        end
    end
end