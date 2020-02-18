class Project
    require_relative 'pipeline_status'
    require_relative 'pipeline_status_fetcher'

    attr_reader :name, :pipeline_states

    def initialize(project_hash, config)
        @id = project_hash['project_id']
        @name = project_hash['name']
        @branches = project_hash['branches']

        init_pipelines config
    end

    def refresh
        @pipelines.each { |branch, pipeline|
            current_status = pipeline.retrieve_status
            enriched_status = PipelineStatus.new(
                @name,
                current_status[:branch],
                current_status[:status],
                current_status[:updated_at])
        }
    end

    private
    def init_pipelines(config)
        @pipelines = {}
        @pipeline_states = []
        @branches.each do |branch|
            @pipelines[branch] = PipelineStatusFetcher.new config, @id, @name, branch
            @pipeline_states << @pipelines[branch].retrieve_status
        end
    end
end