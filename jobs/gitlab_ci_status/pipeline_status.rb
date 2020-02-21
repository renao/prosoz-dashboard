class PipelineStatus
    attr_accessor :project, :branch, :status, :updated_at

    def initialize(project_name, branch, status, updated_at)
        @project = project_name
        @branch = branch
        @status = status
        @updated_at = updated_at
    end
end