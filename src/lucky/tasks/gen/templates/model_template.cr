class Lucky::ModelTemplate
  @name : String
  @namespace : String
  @columns : Array(Lucky::GeneratedColumn)
  @underscored_name : String
  @underscored_namespace_path : String

  getter underscored_name
  getter underscored_namespace_path

  def initialize(full_name : String, @columns : Array(Lucky::GeneratedColumn))
    @namespace, _, @name = full_name.partition(/\b(?=\w+$)/)
    @underscored_name = @name.underscore
    @underscored_namespace_path = @namespace.underscore.gsub("::", "/")
  end

  def render(path : Path)
    LuckyTemplate.write!(path, template_folder)
  end

  def template_folder
    LuckyTemplate.create_folder do |root_dir|
      root_dir.add_file(Path["models/#{underscored_namespace_path}#{underscored_name}.cr"]) do |io|
        ECR.embed("#{__DIR__}/../templates/model/models/model.cr.ecr", io)
      end
      root_dir.add_file(Path["operations/#{underscored_namespace_path}delete_#{underscored_name}.cr"]) do |io|
        ECR.embed("#{__DIR__}/../templates/model/operations/delete_operation.cr.ecr", io)
      end
      root_dir.add_file(Path["operations/#{underscored_namespace_path}save_#{underscored_name}.cr"]) do |io|
        ECR.embed("#{__DIR__}/../templates/model/operations/save_operation.cr.ecr", io)
      end
      root_dir.add_file(Path["queries/#{underscored_namespace_path}#{underscored_name}_query.cr"]) do |io|
        ECR.embed("#{__DIR__}/../templates/model/queries/query.cr.ecr", io)
      end
    end
  end

  def columns_list
    (!@columns.empty? ? @columns : example_columns).map(&.name).join(", ")
  end

  private def example_columns
    [
      Lucky::GeneratedColumn.new("column_1", ""),
      Lucky::GeneratedColumn.new("column_2", ""),
    ]
  end
end
