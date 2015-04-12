#                                                                       #
# This is free software; you can redistribute it and/or modify it under #
# the terms of the MIT- / X11 - License                                 #
#                                                                       #

require 'httpclient'

module VagrantPlugins
  module Save
    class Uploader

      # @param [Vagrant::Environment] env
      # @param [Log4r::Logger] logger
      def initialize(env, logger)
        @env = env
        @logger = logger
      end

      # @param [Vagrant::Machine] machine
      # @param [string] file
      # @param [string] version
      # @return int
      def send(machine, file, version)

        machine.ui.info('Uploading now')

        @logger.debug("Preparing to send file #{file}")

        provider = machine.provider_name.to_s

        if provider =~ /vmware/
          provider = 'vmware_desktop'
        end

        ping_url = make_url(machine)
        post_url = ping_url + '/' + version + '/' + provider

        @logger.debug("Pinging #{ping_url}")

        client = HTTPClient.new

        client.connect_timeout = 10000
        client.send_timeout    = 10000
        client.receive_timeout = 10000

        res = client.options(ping_url)

        raise VagrantPlugins::Save::Errors::CannotContactBoxServer unless res.http_header.status_code == 200

        @logger.debug("Sending file to #{post_url}")

        File.open(file) do |f|
          body = {:box => f}
          connection = client.post_async(post_url, body)
          i = 0

          while true
            break if connection.finished?

            @env.ui.info('.', new_line: false)
            i++

            if i > 40
              @env.ui.clear_line
              i = 0
            end

            sleep 1
          end

          if i > 0
            @env.ui.clear_line
          end

          res = connection.pop
        end

        raise VagrantPlugins::Save::Errors::UploadFailed unless res.http_header.status_code == 200

        machine.ui.info('Upload successful')

        provider
      end

      # @param [Vagrant::Machine] machine
      # @param [int] keep
      # @return int
      def clean(machine, keep)
        machine.ui.info('Cleaning up old versions')

        data_url = make_url(machine)

        @logger.debug("Load versions from #{data_url}")

        res = client.get(data_url)
        data = JSON.parse(res.http_body)

        client = HTTPClient.new
        saved_versions = data['versions'].map{ |v| v.version}

        @logger.debug("Received #{saved_versions.length} versions")

        if saved_versions.length > keep
          saved_versions = saved_versions.sort.reverse
          saved_versions.slice(keep, saved_versions.length).each { |v|
            delete_url = data_url + '/' + v

            @logger.debug("Sending delete #{delete_url}")

            client.delete(delete_url)
          }
        end

        0
      end

      # @param [Vagrant::Machine] machine
      # @return string
      def make_url(machine)
        name = machine.box.name.gsub(/_+/, '/')
        base_url = Vagrant.server_url(machine.config.vm.box_server_url).to_s

        raise Vagrant::Errors::BoxServerNotSet unless base_url

        base_url + '/' + name
      end

    end
  end
end
