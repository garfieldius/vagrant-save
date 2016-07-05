#                                                                       #
# This is free software; you can redistribute it and/or modify it under #
# the terms of the MIT- / X11 - License                                 #
#                                                                       #

require 'httpclient'
require 'net/http/uploadprogress'
require 'uri'

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

        @env.ui.info('Uploading', new_line: false)

        File.open(file) do |f|

          uri       = URI.parse(post_url)
          full_size = f.size
          full      = format_bytes(full_size.to_f)

          http = Net::HTTP.new(uri.host, uri.port)

          http.open_timeout = 10000
          http.read_timeout = 10000

          req = Net::HTTP::Post.new(uri.path)
          req.set_form({"box" => f}, 'multipart/form-data')

          previous_info = ""
          previous_out  = 0.0

          Net::HTTP::UploadProgress.new(req) do |progress|
             if progress.upload_size.to_f >= full_size.to_f
              info = "Upload complete, commiting new box"
            else
              frac    = progress.upload_size.to_f / full_size.to_f
              percent = (frac * 100).round.to_s + "%"
              part    = format_bytes(progress.upload_size.to_f)
              info = "#{percent} (#{part} / #{full})"
            end

            t = Time.now.to_f

            if info != previous_info && t - previous_out > 0.7
              previous_out = t
              previous_info = info

              @env.ui.clear_line
              @env.ui.info(info, new_line: false)
            end
          end
          res = http.request(req)
        end

        @env.ui.clear_line

        raise VagrantPlugins::Save::Errors::UploadFailed unless res.code == '200'

        machine.ui.info('Upload successful')

        provider
      end

      def format_bytes(num)
        units = ["Byte", "KB", "MB", "GB", "TB"]
        index = (Math.log(num) / Math.log(2)).to_i / 10
        bytes = num / ( 1024 ** index )
        bytes = bytes.round(2).to_s.gsub(/\.0+$/, "")

        "#{bytes} #{units[index]}"
      end

      # @param [Vagrant::Machine] machine
      # @param [int] keep
      # @return int
      def clean(machine, keep)

        client = HTTPClient.new

        client.connect_timeout = 10000
        client.send_timeout    = 10000
        client.receive_timeout = 10000

        data_url = make_url(machine)

        @logger.debug("Load versions from #{data_url}")

        res = client.get(data_url)

        @logger.debug("Got response #{res.inspect}")

        data = JSON.parse(res.body)

        @logger.debug("Traverse versions in #{data.inspect}")

        saved_versions = data['versions'].map{ |v|
          @logger.debug("Received version #{v.inspect}")
          v['version']
        }

        @logger.debug("Got #{saved_versions.length} versions: #{saved_versions.inspect}")

        if saved_versions.length > keep
          machine.ui.info('Cleaning up old versions')

          saved_versions.sort.reverse.slice(keep, saved_versions.length).each { |v|
            delete_url = data_url + '/' + v

            machine.ui.info("Deleting version #{v}")
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
