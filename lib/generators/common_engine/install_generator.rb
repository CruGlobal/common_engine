module CommonEngine
  class InstallGenerator < Rails::Generators::Base

    class_option :migrate,  :type => :boolean,  :default => true, :banner => 'Run CommonEngine migrations'
    class_option :lib_name, :type => :string,   :default => 'qe'
    class_option :quite,    :type => :boolean,  :default => false

    # def self.source_paths
    #   paths << File.expand_path('../templates', "../../#{__FILE__}")
    #   paths << File.expand_path('../templates', "../#{__FILE__}")
    #   paths << File.expand_path('../templates', __FILE__)
    #   paths.flatten
    # end

    def prepare_options
      @run_migrations = options[:migrate]
      @lib_name = options[:lib_name]
    end

    # def config_questionnaire_yml
    # end

    # def additional_tweaks
    # end

    # def install_migrations
    #   say_status :copying, "migrations"
    #   silence_stream(STDOUT) do
    #     silence_warnings { rake 'common_engine:install:migrations' }
    #   end
    # end

    def create_database
      say_status :creating, "database"
      silence_stream(STDOUT) do
        silence_stream(STDERR) do
          silence_warnings { rake 'db:create' }
        end
      end
    end

    # def run_migrations
    #   if @run_migrations
    #     say_status :running, "migrations"
    #     quietly { rake 'db:migrate' }
    #   else
    #     say_status :skipping, "migrations (don't forget to run rake db:migrate)"
    #   end
    # end

    # def noify_about_javascripts
    #   insert_into_file File.join('app', 'assets', 'javascripts', 'application.js'), 
    #   :before => "//= require_tree ." do
    #     %Q{//= require common_engine/application \n} 
    #   end
    #   unless options[:quiet]
    #     puts "*" * 75
    #     puts "Added this to app's application.js file,"
    #     puts " "
    #     puts "  //= require common_engine/application"
    #     puts " "
    #   end
    # end
    
    # def notify_about_stylesheets
    #   insert_into_file File.join('app', 'assets', 'stylesheets', 'application.css'), 
    #   :before => "*= require_tree ." do
    #       %Q{*= require common_engine/application \n }
    #   end 
    #   unless options[:quiet]
    #     puts "*" * 75
    #     puts "Added this to app's stylesheets file,"
    #     puts " "
    #     puts "  *= require common_engine/application"
    #     puts " "
    #   end
    # end

    # TODO figure out image refernces
    # def notify_about_images
    #   insert_into_file File.join('app', 'assets', 'images', 'application.css')
    # end

    def complete
      unless options[:quiet]
        puts "*" * 75
        puts " "
        puts ">> CommonEngine successfully installed. You're all ready to go!"
        puts ">> Enjoy!"
      end
    end

  end
end

