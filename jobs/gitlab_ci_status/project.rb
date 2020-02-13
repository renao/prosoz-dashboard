class Project

    def initialize(project_hash)
        @id = project_hash[:project_id]
        @name = project_hash[:name]
        @branches = project_hash[:branches]
    end

    def update_pipelines
    end

    attr_reader :id, :name, :branches
end