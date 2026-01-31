require "ecr"
require "lucky_task"
require "lucky_template"
require "wordsmith"
require "../../../../avram"
require "../mixins/migration_with_columns"
require "lucky/route_inferrer"

class Gen::Resource::Browser < LuckyTask::Task
  include Gen::Mixins::MigrationWithColumns

  summary "Generate a resource (model, operation, query, actions, and pages)"
  help_message <<-TEXT
  #{task_summary}

  Requires the name of the resource and list of database columns. Columns
  are passed as column_name:ColumnType. Where ColumnType are one of the
  supported Avram datatypes.

  Example:

    lucky gen.resource.browser Project title:String description:String? completed:Bool priority:Int32
  TEXT

  class InvalidOption < Exception
    def initialize(message : String)
      super message
    end
  end

  def call
    validate!
    generate_resource
    output.puts "\nYou will need to run the #{"lucky db.migrate".colorize.green} task next"
    display_path_to_resource
  rescue e : InvalidOption
    output.puts e.message.colorize.red
  end

  private def generate_resource
    Lucky::ResourceTemplate.new(resource_name, columns).render(Path["./src/"])
    create_migration
    display_success_messages
  end

  private def display_path_to_resource
    output.puts "\nView list of #{pluralized_name} in your browser at: #{path_to_resource.colorize.green}"
  end

  private def path_to_resource
    "/#{pluralized_name.underscore}"
  end

  private def validate! : Nil
    validate_name_is_present!
    validate_not_namespaced!
    validate_name_is_singular!
    validate_name_is_camelcase!
    validate_has_supported_columns!
  end

  private def validate_name_is_present!
    if resource_name?.nil? || resource_name?.try &.empty?
      error "Resource name is required. Example: lucky gen.resource.browser User"
    end
  end

  private def validate_not_namespaced!
    if resource_name.includes?("::")
      error "Namespaced resources are not supported"
    end
  end

  private def validate_name_is_singular!
    singularized_name = Wordsmith::Inflector.singularize(resource_name)
    if singularized_name != resource_name
      error "Resource must be singular. Example: lucky gen.resource.browser #{singularized_name}"
    end
  end

  private def validate_name_is_camelcase!
    if resource_name.camelcase != resource_name
      error "Resource name should be camel case. Example: lucky gen.resource.browser #{resource_name.camelcase}"
    end
  end

  private def validate_has_supported_columns!
    if column_definitions.empty?
      error "Resource requires at least one column definition. Example lucky gen.resource.browser #{resource_name} column_name:String"
    end
    if !columns_are_valid?
      error unsupported_columns_error(resource_name, "resource.browser")
    end
  end

  private def error(message : String)
    raise InvalidOption.new(message)
  end

  private def display_success_messages
    success_message(resource_name, Path["./src/models/#{underscored_resource}.cr"].to_s)
    success_message("Save#{resource_name}", Path["./src/operations/save_#{underscored_resource}.cr"].to_s)
    success_message("Delete#{resource_name}", Path["./src/operations/delete_#{underscored_resource}.cr"].to_s)
    success_message("#{resource_name}Query", Path["./src/queries/#{underscored_resource}_query.cr"].to_s)

    %w(index show new create edit update delete).each do |action|
      success_message(
        "#{pluralized_name}::#{action.capitalize}",
        Path["./src/actions/#{folder_name}/#{action}.cr"].to_s
      )
    end

    %w(index show new edit).each do |action|
      success_message(
        "#{pluralized_name}::#{action.capitalize}Page",
        Path["./src/pages/#{folder_name}/#{action}_page.cr"].to_s
      )
    end

    success_message("#{pluralized_name}::FormFields", Path["./src/components/#{folder_name}/form_fields.cr"].to_s)
  end

  private def underscored_resource
    resource_name.underscore
  end

  private def folder_name
    Wordsmith::Inflector.pluralize underscored_resource
  end

  private def pluralized_name
    Wordsmith::Inflector.pluralize resource_name
  end

  private def success_message(class_name : String, filename : String) : Nil
    output.puts "Generated #{class_name.colorize.bold} in #{filename.colorize.bold}"
  end

  private def resource_name : String
    resource_name?.to_s
  end

  private def resource_name? : String?
    ARGV.first?
  end
end

class Lucky::ResourceTemplate
  getter resource, columns
  getter query_filename : String,
    underscored_resource : String,
    folder_name : String

  def initialize(@resource : String, @columns : Array(Lucky::GeneratedColumn))
    @query_filename = query_class.underscore
    @underscored_resource = @resource.underscore
    @folder_name = pluralized_name.underscore
  end

  def render(path : Path)
    LuckyTemplate.write!(path, template_folder)
  end

  def template_folder
    LuckyTemplate.create_folder do |root_dir|
      root_dir.add_folder(Path["actions/#{folder_name}"]) do |actions_folder|
        actions_folder.add_file(Path["create.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/actions/create.cr.ecr", io)
        end
        actions_folder.add_file(Path["delete.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/actions/delete.cr.ecr", io)
        end
        actions_folder.add_file(Path["edit.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/actions/edit.cr.ecr", io)
        end
        actions_folder.add_file(Path["index.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/actions/index.cr.ecr", io)
        end
        actions_folder.add_file(Path["new.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/actions/new.cr.ecr", io)
        end
        actions_folder.add_file(Path["show.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/actions/show.cr.ecr", io)
        end
        actions_folder.add_file(Path["update.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/actions/update.cr.ecr", io)
        end
      end
      root_dir.add_folder(Path["components/#{folder_name}"]) do |components_folder|
        components_folder.add_file(Path["form_fields.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/components/form_fields.cr.ecr", io)
        end
      end
      root_dir.add_file(Path["models/#{underscored_resource}.cr"]) do |io|
        ECR.embed("#{__DIR__}/../templates/resource/models/model.cr.ecr", io)
      end
      root_dir.add_file(Path["operations/delete_#{underscored_resource}.cr"]) do |io|
        ECR.embed("#{__DIR__}/../templates/resource/operations/delete_operation.cr.ecr", io)
      end
      root_dir.add_file(Path["operations/save_#{underscored_resource}.cr"]) do |io|
        ECR.embed("#{__DIR__}/../templates/resource/operations/save_operation.cr.ecr", io)
      end
      root_dir.add_folder(Path["pages/#{folder_name}"]) do |pages_folder|
        pages_folder.add_file(Path["edit_page.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/pages/edit_page.cr.ecr", io)
        end
        pages_folder.add_file(Path["index_page.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/pages/index_page.cr.ecr", io)
        end
        pages_folder.add_file(Path["new_page.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/pages/new_page.cr.ecr", io)
        end
        pages_folder.add_file(Path["show_page.cr"]) do |io|
          ECR.embed("#{__DIR__}/../templates/resource/pages/show_page.cr.ecr", io)
        end
      end
      root_dir.add_file(Path["queries/#{query_filename}.cr"]) do |io|
        ECR.embed("#{__DIR__}/../templates/resource/queries/query.cr.ecr", io)
      end
    end
  end

  private def pluralized_name
    Wordsmith::Inflector.pluralize(resource)
  end

  private def resource_id_method_name
    "#{underscored_resource}_id"
  end

  private def query_class
    "#{resource}Query"
  end

  private def route(action)
    Lucky::RouteInferrer.new(action_class_name: "#{pluralized_name}::#{action}").generate_inferred_route
  end
end
