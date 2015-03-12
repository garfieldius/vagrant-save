#                                                                       #
# This is free software; you can redistribute it and/or modify it under #
# the terms of the MIT- / X11 - License                                 #
#                                                                       #

require_relative 'errors'

module VagrantPlugins
  module Save
    class Command < Vagrant.plugin('2', :command)

      def self.synopsis
        'exports a box file with additional actions taken'
      end

      def execute
        options = {}
        options[:version] = nil
        options[:keep] = 0

        opts = OptionParser.new do |o|
          o.banner = 'Usage: vagrant save [-v|--version VERSION] [-k|--keep COUNT]'
          o.separator ''

          o.on('-v', '--version', 'Set the version of the uploaded box. Defaults to next bugfix version') do |v|
            options[:version] = v.to_s
          end

          o.on('-k', '--keep', 'Number of versions to keep, older will be removed. Must be >= 1. Defaults to 0.') do |v|
            options[:keep] = v.to_i
          end
        end

        argv = parse_options(opts)
        return 1 unless argv

        target_version = options[:version]

        unless target_version == nil
          unless /^[0-9]+\.[0-9]+\.[0-9]+$/ =~ target_version
            raise VagrantPlugins::Save::Errors::NoValidVersion
          end
        end

        require 'vagrant-export/exporter'
        require_relative 'uploader'

        ex = VagrantPlugins::Export::Exporter.new(@env, @logger)
        up = Uploader.new(@env, @logger)

        with_target_vms argv, reverse: true do |machine|

          if target_version
            version = target_version

            if Gem::Version.new(machine.box.version.to_s) <= Gem::Version.new(version)
              raise VagrantPlugins::Save::Errors::InvalidVersion
            end

          else
            version_parts = machine.box.version.to_s
            if /^[0-9]+\.[0-9]+\.[0-9]+$/ =~ version_parts
              version_parts = version_parts.split('.')
              version = version_parts[0] + '.' + version_parts[1] + '.' + (version_parts[2].to_i + 1).to_s
            else
              version = '1.0.0'
            end
          end

          file = ex.handle(machine, false, false)
          provider_name = up.send(machine, file, version)

          @env.boxes.add(
            file,
            machine.box.name,
            version,
            force: true,
            metadata_url: up.make_url(machine),
            providers: provider_name
          )

          FileUtils.remove(file)

          if options[:keep] && options[:keep] > 1
              up.clean(machine, options[:keep])
          end

        end
        0
      end
    end
  end
end
