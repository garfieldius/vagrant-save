#                                                                       #
# This is free software; you can redistribute it and/or modify it under #
# the terms of the MIT- / X11 - License                                 #
#                                                                       #

module VagrantPlugins
  module Save
    class Plugin < Vagrant.plugin('2')

      name('Vagrant Save')

      description <<-EOF
      Uses vagrant-export to create a.box file from the current machine and
      saves it to a boxserver using a HTTP POST request.
      EOF

      command 'save' do
        require_relative 'command'
        Command
      end
    end
  end
end
