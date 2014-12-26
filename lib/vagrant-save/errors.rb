#                                                                       #
# This is free software; you can redistribute it and/or modify it under #
# the terms of the MIT- / X11 - License                                 #
#                                                                       #

module VagrantPlugins
  module Save
    module Errors

      class CannotContactBoxServer < VagrantError
        error_message('Cannot contact the given box server. Please make sure the URL is correct and it is running')
      end

      class UploadFailed < VagrantError
        error_message('Cannot upload the box file to the boxserver')
      end

      class NoValidVersion < VagrantError
        error_message('The given version is not valid. Please pass a version number like 1.2.3, or leave it to automatically bump the bugfix/release number')
      end

      class InvalidVersion < VagrantError
        error_message('The given version number is lower or equal to the current version of the box')
      end

    end
  end
end
