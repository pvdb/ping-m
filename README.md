# PingMonitor

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/ping-m`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ping-m'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ping-m

## Usage

Run `ping-m` against well-known public DNS servers

    exe/ping-m --cloudflare
    exe/ping-m --google
    exe/ping-m --opendns

Run `ping-m` against a local server, e.g. your router

    exe/ping-m 192.168.0.1

Process `ping` output with `ping-m`

    ping -c 16 8.8.8.8 | exe/ping-m

Process captured `ping` output with `ping-m`

    ping -c 16 8.8.8.8 > google_dns.ping
    exe/ping-m < google_dns.ping

Capture and simulaneously process `ping` output

    ping -c 16 8.8.8.8 | tee google_dns.ping | exe/ping-m

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pvdb/ping-m
