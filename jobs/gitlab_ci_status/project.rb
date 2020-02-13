class Project
    require_relative 'gitlab_pipeline_status'

    def initialize(project_hash, config)
        @id = project_hash['project_id']
        @name = project_hash['name']
        @branches = project_hash['branches']

        init_pipelines config
    end

    def update_pipeline_status(pipeline_update_callback)
        @pipelines.each { |branch, pipeline|
            current_status = pipeline.retrieve_status
            pipeline_update_callback.call current_status
        }
    end

    private
    def init_pipelines(config)
        @pipelines = {}
        @branches.each do |branch|
            @pipelines[branch] = GitlabPipelineStatus.new config, @id, branch
        end
    end

    attr_reader :id, :name, :branches
end