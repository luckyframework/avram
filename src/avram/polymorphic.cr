# Helpers for defining polymorphic associations
module Avram::Polymorphic
  # Sets up helper methods for validating and loading polymorphic associatiions
  #
  # This will generate methods for validating, preloading, and lazy loading
  # polymorphic associations.

  # > *Important note:* the `belongs_to` associations must be nilable since only
  # > one polymorphic can be set at a time. Remember to also make the association
  # > nilable in the migration, for example: `add_belongs_to photo : Photo?`
  #
  # Let's start with this example:
  #
  # ```
  # class Comment < BaseModel
  #   table do
  #     belongs_to photo : Photo?
  #     belongs_to video : Video?
  #     polymorphic :commentable, associations: [:photo, :video]
  #   end
  # end
  #
  # class Photo < BaseModel
  #   table do
  #     has_many comments : Comment
  #   end
  # end
  #
  # class Video < BaseModel
  #   table do
  #     has_many comments : Comment
  #   end
  # end
  # ```
  #
  # `has_many` (and `belongs_to`) work just like normal.
  #
  # `polymorphic` just set up methods for validation, preloading, and getting
  # the polymorphic association more easily.
  #
  # ## Validations
  #
  # `polymorphic` will add a validation so that exactly one of the associations
  # is present. In this case either `photo_id` or `video_id`, but not both.
  #
  # If `optional` is set to true, it will allow the associations to be `nil`, but
  # will still not allow more than one association to be set at a time.
  #
  # ## Preloading
  #
  # `polymorphic` defines a `preload_{polymorphic_name}` on the query.
  #
  # In this example it would define `preload_commentable` on `Comment::BaseQuery`.
  # Under the hood this is preloading each belongs_to. In this example
  # `Comment::BaseQuery.preload_commentable` is like calling
  # `Comment::BaseQuery.preload_photo.preload_video`.
  #
  # ## Model getter
  #
  # Adds `{polymorphic_name}` and `{polymorphic_name}!` getters to the model.
  #
  # In this example `commentable` and `commentable!`. Calling these will return
  # either the `video` or the `photo`. The `!` version will allow lazy loading.
  # The non `!` version requires preloading with `preload_{polymorphic_name}.
  #
  # If `optional` is set to true these methods will return `nil` if nothing
  # is associated.
  #
  # ```
  # Comment::BaseQuery.new.preload_commentable.each do |comment|
  #   comment.commentable # Returns the photo or video
  # end
  # ```
  #
  # If you know which association you want you can just call it directly like
  # you would with any other `belongs_to`:
  #
  # ```
  # # Preload the comments and each comment's photo
  # photo = Photo::BaseQuery.new.preload_comments(Comment::BaseQuery.new.preload_photo)
  # photo.comments.each do |comment|
  #   # We know it is for a photo, so we can call it directly
  #   # Note that Crystal will think this might be `nil` since the `belongs_to`
  #   # is nilable. So you'll need to call `not_nil!` or handle the `nil` case
  #   # with an `if`
  #   comment.photo.not_nil!
  # end
  # ```
  #
  # # Saving/updating polymorphic associations
  #
  # Polymorphic associations are saved just like your normally would with a
  # `belongs_to` association:
  #
  # ```
  # # Save a comment for this photo
  # photo = PhotoQuery.first
  # Comment::SaveOperation.create!(photo_id: photo.id)

  # # Save a comment for this video
  # video = VideoQuery.first
  # Comment::SaveOperation.create!(video_id: video.id)
  # ```
  macro polymorphic(polymorphic_name, associations, optional = false)
    {% polymorphic_name = polymorphic_name.id %}
    def {{ polymorphic_name }}
      ensure_{{ polymorphic_name }}_belongs_to_are_nilable!

      # Generates something like: post || video
      {{ associations.map(&.id).join(" || ").id }}{% if !optional %} || Avram::Polymorphic.raise_missing_polymorphic(:{{ polymorphic_name }}, self){% end %}
    end

    def {{ polymorphic_name }}!
      ensure_{{ polymorphic_name }}_belongs_to_are_nilable!

      # Generates something like: post! || video!
      {% associations_with_a_bang = associations.map(&.id).map { |assoc| "#{assoc}!" } %}
      {{ associations_with_a_bang.join(" || ").id }}{% if !optional %} || Avram::Polymorphic.raise_missing_polymorphic(:{{ polymorphic_name }}, self){% end %}
    end

    private def ensure_{{ polymorphic_name }}_belongs_to_are_nilable! : Nil
      if should_check_polymorphism_at_runtime?
        {% associations_to_check = associations.map(&.id).map { |assoc| "#{assoc}.as(Nil)" } %}
        {{ associations_to_check.join(" || ").id }} # Ensure polymorphic associations are nilable
      end
    end

    # This is a bit of a hack to get around Crystal's smart compiler :)
    # In the ensure_{assoc}_belongs_to_are_nilable! we need to check that the
    # compiler *can* cast to nil, but we don't want to *actually* check it at
    # runtime. The problem is that we can't do `if false` because Crystal realizes
    # That will never match and so doesn't even check the `as(Nil)`
    # We have to trick it by extracting the false to a method. That way
    # Crystal doesn't realize it is always 'false' and will still check
    # That the types can be cast to Nil at compile, without actually casting it
    # at runtime.
    private def should_check_polymorphism_at_runtime? : Bool
      false
    end

    macro finished
      class SaveOperation
        # These validations must be run after all of the `before_save`
        # in case anyone sets their polymorphic association in a callback.
        # These are ran in the SaveOperation#valid? method
        default_validations do
          {% list_of_foreign_keys = associations.map(&.id).map { |assoc| "#{assoc.id}_id".id } %}

          # TODO: Needs to actually get the foreign key from the ASSOCIATIONS constant
          {% if optional %}
            validate_at_most_one_filled {{ list_of_foreign_keys.map(&.id).join(", ").id }}
          {% else %}
            validate_exactly_one_filled {{ list_of_foreign_keys.map(&.id).join(", ").id }},
              message: "at least one '{{ polymorphic_name.id }}' must be filled"
          {% end %}
        end
      end

      class BaseQuery
        def preload_{{ polymorphic_name.id }}
          {% for association in associations %}
             preload_{{ association.id }}
          {% end %}
        end
      end
    end
  end

  # :nodoc:
  def self.raise_missing_polymorphic(polymorphic_name : Symbol, model : Avram::Model)
    raise <<-TEXT
    Missing '#{polymorphic_name}' for #{model}.

    If you meant for '#{polymorphic_name}' to be optional, add 'optional: true' to 'polymorphic :#{polymorphic_name}' in the model.
    TEXT
  end
end
