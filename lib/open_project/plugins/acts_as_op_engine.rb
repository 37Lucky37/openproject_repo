#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "open_project/ui/extensible_tabs"
require_relative "../../../config/constants/api_patch_registry"
require_relative "../../../config/constants/open_project/activity"
require_relative "../../../config/constants/views"
require_relative "../../../config/constants/settings/definition"

module OpenProject::Plugins
  module ActsAsOpEngine
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        config.eager_load_paths += Dir["#{config.root}/lib"]

        config.before_configuration do |app|
          # This is required for the routes to be loaded first
          # as the routes should be prepended so they take precedence over the core.
          app.config.paths["config/routes.rb"].unshift File.join(config.root, "config", "routes.rb")
        end

        initializer "#{engine_name}.remove_duplicate_routes", after: "add_routing_paths" do |app|
          # removes duplicate entry from app.routes_reloader
          # As we prepend the plugin's routes to the load_path up front and rails
          # adds all engines' config/routes.rb later, we have double loaded the routes
          # This is not harmful as such but leads to duplicate routes which decreases performance
          app.routes_reloader.paths.uniq!
        end

        initializer "#{engine_name}.register_test_paths" do |app|
          app.config.plugins_to_test_paths << root
        end

        initializer "#{engine_name}.i18n_load_paths" do |app|
          app.config.i18n.load_path += Dir[config.root.join("config", "locales", "crowdin", "*.{rb,yml}").to_s]
        end

        # adds our factories to factory girl's load path
        initializer "#{engine_name}.register_factories", after: "factory_bot.set_factory_paths" do |_app|
          FactoryBot.definition_file_paths << File.expand_path("#{root}/spec/factories") if defined?(FactoryBot)
        end

        initializer "#{engine_name}.append_migrations" do |app|
          unless app.root.to_s.match root.to_s
            config.paths["db/migrate"].expanded.each do |expanded_path|
              app.config.paths["db/migrate"] << expanded_path
            end

            ##
            # Manually inject these paths into various places
            # in order to re-enable chained rake tasks
            # finding all migrations.
            # http://blog.pivotal.io/pivotal-labs/labs/leave-your-migrations-in-your-rails-engines
            paths = app.config.paths["db/migrate"].to_a
            ActiveRecord::Tasks::DatabaseTasks.migrations_paths = paths
            ActiveRecord::Migrator.migrations_paths = paths
          end
        end
      end
    end

    module InstanceMethods
      def name
        ActiveSupport::Inflector.demodulize(self.class).downcase
      end

      # Patch classes
      #
      # Looks for patches via autoloading in
      # <plugin root>/lib/openproject/<plugin name>/patches/<patched_class>_patch.rb
      # Make sure the patch module has the name the Rails autoloading expects.
      #
      # Example:
      #  patches [:IssuesController]
      # This looks for OpenProject::XlsExport::Patches::IssuesControllerPatch
      #  in openproject/xls_export/patches/issues_controller_patch.rb
      def patches(patched_classes)
        plugin_module = self.class.to_s.deconstantize
        self.class.config.to_prepare do
          patched_classes.each do |klass_name|
            patch = "#{plugin_module}::Patches::#{klass_name}Patch".constantize
            klass = klass_name.to_s.constantize
            klass.send(:include, patch) unless klass.included_modules.include?(patch)
          end
        end
      end

      def patch_with_namespace(*args)
        plugin_module = self.class.to_s.deconstantize
        self.class.config.to_prepare do
          klass_name = args.last
          patch = begin
            "#{plugin_module}::Patches::#{args[0..-2].join('::')}::#{klass_name}Patch".constantize
          rescue NameError
            "#{plugin_module}::Patches::#{klass_name}Patch".constantize
          end

          qualified_class_name = args.map(&:to_s).join("::")
          klass = qualified_class_name.to_s.constantize
          klass.send(:include, patch) unless klass.included_modules.include?(patch)
        end
      end

      # Define assets provided by the plugin
      def assets(assets)
        self.class.initializer "#{engine_name}.precompile_assets" do |app|
          app.config.assets.precompile += assets.to_a
        end
      end

      # Prepend view paths of this engine
      # Note: YOU WILL override views of the core with this functionality
      def override_core_views!
        config.after_initialize do
          paths = ActionController::Base.view_paths.map(&:to_s)
          my_view_path = "#{config.root}/app/views"

          # Move item to the front
          paths.delete(my_view_path)
          paths.insert(0, my_view_path)

          ActionController::Base.view_paths = paths
        end
      end

      # Add permitted attributes (strong_parameters)
      #
      # Useful when adding a field to an OpenProject core model. We discourage adding
      # a field to a core model, but at the moment there's no API to do this in a better way
      # and a lot of existing plugins already do it.
      #
      # See PermittedParams in OpenProject for available models
      #
      # Example:
      #  additional_permitted_attributes user: [:registration_reason]
      def additional_permitted_attributes(attributes)
        config.to_prepare do
          ::PermittedParams.send(:add_permitted_attributes, attributes)
        end
      end

      # Register a plugin with OpenProject
      #
      # Uses Gem specification for plugin name, author etc.
      #
      # gem_name:      The gem name, used for querying the gem for metadata like author
      # options:       An options Hash, at least :requires_openproject is recommended to
      #                define the minimal version of OpenProject the plugin is compatible with
      #                Another common option is :author_url.
      # block:         Pass a block to the plugin (for defining permissions, menu items and the like)
      def register(gem_name, options, &block)
        self.class.initializer "#{engine_name}.register_plugin" do
          spec = Gem.loaded_specs[gem_name]

          p = Redmine::Plugin.register engine_name.to_sym do
            gem_name spec.name
            author spec.authors.is_a?(Array) ? spec.authors[0] : spec.authors
            version spec.version
            url spec.homepage

            options.each do |name, value|
              send(name, value)
            end
          end
          p.instance_eval(&block) if p && block
        end
      end

      ##
      # Add a tab entry to an extensible tab
      def add_tab_entry(key, name:, partial:, path:, label:, only_if: nil)
        ::OpenProject::Ui::ExtensibleTabs.add(key, name:, partial:, path:, label:, only_if:)
      end

      def add_view(type, contract_strategy: nil)
        Constants::Views.add(type, contract_strategy:)
      end

      def add_api_path(path_name, &)
        config.to_prepare do
          ::API::V3::Utilities::PathHelper::ApiV3Path.class_eval do
            singleton_class.instance_eval do
              define_method(path_name, &)
            end
          end
        end
      end

      def add_api_endpoint(base_endpoint, path = nil, &)
        # we are expecting the base_endpoint as string for two reasons:
        # 1. it does not seem possible to pass it as constant (auto loader not ready yet)
        # 2. we can't constantize it here, because that would evaluate
        #    the API before it can be patched
        ::Constants::APIPatchRegistry.add_patch(base_endpoint, path, &)
      end

      def extend_api_response(*args, &)
        config.to_prepare do
          representer_namespace = args.map { |arg| arg.to_s.camelize }.join("::")
          representer_class     = "::API::#{representer_namespace}Representer".constantize
          representer_class.instance_eval(&)
        end
      end

      def add_api_attribute(on:,
                            ar_name:,
                            writable_for: %i[create update],
                            writable: true,
                            &block)
        config.to_prepare do
          model_name = on.to_s.camelize
          namespace = model_name.pluralize
          Array(writable_for).each do |action|
            # attribute is generally writable
            # overrides might be defined in the more specific contract implementations
            contract_class = "::#{namespace}::#{action.to_s.camelize}Contract".constantize
            contract_class.attribute ar_name, { writable: }, &block
          end
        end
      end

      # Register a block to return results when an api representer's cache key is asked for.
      #
      # This is important for cache invalidation e.g. when another schema needs
      # to be returned depending on whether a module is active or not.
      #
      # path:          The fully namespaced representer name, excluding 'API' at the
      #                beginning and 'Representer' at the end.
      # keys:          The block to be executed when the cache key is queried for. The block's
      #                results will be appended to the original cache key if a cache key is already
      #                defined. If no cache key was defined before, the block's result makes up
      #                the whole cache key.
      def add_api_representer_cache_key(*path,
                                        &)
        mod = Module.new
        mod.send :define_method, :json_cache_key do
          if defined?(super)
            existing = super()

            existing + instance_eval(&)
          else
            instance_eval(&)
          end
        end

        config.to_prepare do
          representer_namespace = path.map { |arg| arg.to_s.camelize }.join("::")
          representer_class     = "::API::#{representer_namespace}Representer".constantize
          representer_class.prepend mod
        end
      end

      # Registers an activity provider.
      #
      # @param event_type [Symbol]
      #
      # Options:
      # * <tt>:class_name</tt> - one or more model(s) that provide these events, those need to inherit
      #                          from Activities::BaseActivityProvider
      # * <tt>:default</tt> - setting this option to false will make the events not displayed by default
      #
      # Example
      #   activity_provider :meetings, class_name: 'Activities::MeetingActivityProvider', default: false
      #
      def activity_provider(event_type, options = {})
        OpenProject::Activity.register(event_type, options)
      end

      def add_cron_jobs
        config.to_prepare do
          Rails.application.config.good_job.cron.merge!(yield)
        end
      end

      # Add custom inflection for file name to class name mapping. Otherwise, the default zeitwerk
      # #camelize method will be utilized.
      #
      #   class_inflection_override('asap' => 'ASAP')
      #
      #   inflector.camelize("asap", abspath)      # => "ASAP"
      #
      # @param overrides [{String => String}]
      # @return [void]
      def class_inflection_override(overrides)
        self.class.initializer "#{engine_name}.class_inflection_override" do
          OpenProject::Inflector.inflection(overrides)
        end
      end

      # Adds a replacement rule for a principal reference. When the module allows adding a
      # principal (e.g. a user) reference to a model, a replacement rule should be added so
      # that the user can be deleted, by making sure references to that user are replaced
      # on that model as well.
      def replace_principal_reference(class_name, attribute)
        config.to_prepare do
          Principals::ReplaceReferencesService.add_replacement(class_name, attribute)
        end
      end

      # Like #replace_principal_reference, but allows to add multiple classes and attributes at once.
      def replace_principal_references(attributes_by_class_name)
        config.to_prepare do
          Principals::ReplaceReferencesService.add_replacements(attributes_by_class_name)
        end
      end
    end
  end
end
