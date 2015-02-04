# vagrant-save

This is a simple plugin to export boxes into .box files using [vagrant-export](https://github.com/trenker/vagrant-export) and pushes that file to a  [boxserver](https://github.com/trenker/boxserver) instance.

## Installation

Like with any other vagrant plugin:

```bash
vagrant plugin install vagrant-save
```

## Usage

Have a [boxserver](https://github.com/trenker/boxserver) instance running and set the property `config.vm.box_server_url` to its address in your vagrant file. So your `Vagrantfile` contains the following statements:

```ruby
Vagrant.configure("2") do |config|
  # This must be set
  config.vm.box_server_url = "http://localhost:8001"
end
```

Then just run

```bash
vagrant save
```

to release a new version of your box.

By default, it increases the bugfix version number by one. So an installed 1.0.0 becomes 1.0.1. You can specify the version yourself using the parameter `-v|--version`, like this:

```bash
vagrant save -v 1.2.0
```

The parameter must always have all three digits and must be greater than the installed version.

You may want to clean up the boxserver by deleting old versions. The `-k|--keep` parameter sets how many versions to keep. The versions are sorted in descending order, older than the newest X will be deleted:

```bash
# Keeping the last six versions
vagrant save -k 6

# Keeping all versions
# Does not need to be written, as it is the default setting
vagrant save -k 0
```

## License

The MIT License (MIT)

Copyright (c) 2014 Georg Großberger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
