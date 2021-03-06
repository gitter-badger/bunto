module Bunto
  module Commands
    class Build < Command

      class << self

        # Create the Mercenary command for the Bunto CLI for this Command
        def init_with_program(prog)
          prog.command(:build) do |c|
            c.syntax      'build [options]'
            c.description 'Build your site'
            c.alias :b

            add_build_options(c)

            c.action do |args, options|
              options["serving"] = false
              Bunto::Commands::Build.process(options)
            end
          end
        end

        # Build your Bunto site
        # Continuously watch if `watch` is set to true in the config.
        def process(options)
          Bunto.logger.log_level = :error if options['quiet']

          options = configuration_from_options(options)
          site = Bunto::Site.new(options)

          if options.fetch('skip_initial_build', false)
            Bunto.logger.warn "Build Warning:", "Skipping the initial build. This may result in an out-of-date site."
          else
            build(site, options)
          end

          if options.fetch('watch', false)
            watch(site, options)
          else
            Bunto.logger.info "Auto-regeneration:", "disabled. Use --watch to enable."
          end
        end

        # Build your Bunto site.
        #
        # site - the Bunto::Site instance to build
        # options - A Hash of options passed to the command
        #
        # Returns nothing.
        def build(site, options)
          t = Time.now
          source      = options['source']
          destination = options['destination']
          full_build  = options['full_rebuild']
          Bunto.logger.info "Source:", source
          Bunto.logger.info "Destination:", destination
          Bunto.logger.info "Incremental build:", (full_build ? "disabled" : "enabled")
          Bunto.logger.info "Generating..."
          process_site(site)
          Bunto.logger.info "", "done in #{(Time.now - t).round(3)} seconds."
        end

        # Private: Watch for file changes and rebuild the site.
        #
        # site - A Bunto::Site instance
        # options - A Hash of options passed to the command
        #
        # Returns nothing.
        def watch(site, options)
          External.require_with_graceful_fail 'bunto-watch'
          Bunto::Watcher.watch(options)
        end

      end # end of class << self

    end
  end
end
