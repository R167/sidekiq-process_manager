# Sidekiq::ProcessManager

[![Build Status](https://travis-ci.com/bdurand/sidekiq-process_manager.svg?branch=master)](https://travis-ci.com/bdurand/sidekiq-process_manager)
[![Maintainability](https://api.codeclimate.com/v1/badges/ed89164d480af0e1442e/maintainability)](https://codeclimate.com/github/bdurand/sidekiq-process_manager/maintainability)

This gem provides a command line script for managing [sidekiq](https://github.com/mperham/sidekiq) processes. It starts up a process that then forks multiple sidekiq processes and manages their life cycle. This is important for large sidekiq installations, since without it on MRI ruby, sidekiq will only use one CPU core. By starting multiple processes you make all cores available.

The sidekiq processes can all be managed by sending signals to the manager process. This process simply forwards the signals on to the child processes, allowing you to control the sidekiq processes as you normally would.

If one of the sidekiq processes dies unexpectedly, the process manager automatically starts a new sidekiq process to replace it.

## Pre-Forking

You can use pre-forking to improve memory utilization on the child sidekiq processes. This is similar to using pre-forking in a web server like puma or unicorn. You application will be pre-loaded by the master process and the child sidekiq processes will utilize the loaded code via copy-on-write memory. The overall effect is that you should be able to run more sidekiq processes in a lower memory footprint.

One issue with pre-forking is that any file descriptors (including network connections) your application has open when it forks will be shared between all the processes. This can lead to race conditions and other problems. To fix it, you must close and reopen all database connections, etc. after the child sidekiq processes have been forked.

To do this, your application will need to add an initializer with calls to `Sidekiq::ProcessManager.after_fork` and `Sidekiq::ProcessManager.before_fork`.

The `before_fork` hook is called on the master process right before it starts forking processes. You can use this to close connections on the master process that you don't need.

The `after_fork` hook is called after a forked sidekiq process has initialized the application. You can use this to re-establish connections so that each process gets it's own streams.

At a minimum, you'll probably want the following hooks to close and re-open the ActiveRecord database connection:

```ruby
Sidekiq::ProcessManager.before_fork do
  ActiveRecord::Base.connection.disconnect!
end

Sidekiq::ProcessManager.after_fork do
  ActiveRecord::Base.connection.reconnect!
end
```

If you're already using a pre-forking web server, you'll need to do most of the same things for sidekiq as well.

## Pre-Booting

If your application can't be pre-forked, you can at load the gem files and libraries your application depends on instead by specifying a preboot file. This file will be loaded by the master process and any code loaded will be copy-on-write shared with the child processes.

For a Rails application, you would normally want to preboot the `config/boot.rb` file.

## Usage

Install the gem in your sidekiq process and run it with `bundle exec sidekiq-process-manager` or, if you use [bundle binstubs](https://bundler.io/man/bundle-binstubs.1.html), `bin/sidekiq-process-manager`. All command line arguments are passed through to sidekiq.

```bash
bundle exec sidekiq-process-manager -C config/sidekiq.yml
```

You can specify the number for sidekiq processes to run with the `--processes` argument or with the `SIDEKIQ_PROCESSES` environment variable. The default number of processes is 1.

```bash
bundle exec sidekiq-process-manager --processes 4
```

or

```bash
SIDEKIQ_PROCESSES=4 bundle exec sidekiq-process-manager
```

You can turn pre-forking on or off with the --prefork or --no-prefork flag. You can also specify to turn on pre-forking with the `SIDEKIQ_PREFORK` environment variable.

```bash
bundle exec sidekiq-process-manager --processes 4 --prefork
```

or

```bash
SIDEKIQ_PREFORK=1 SIDEKIQ_PROCESSES=4 bundle exec sidekiq-process-manager
```

You can turn pre-booting on with the `--preboot` argument or with the `SIDEKIQ_PREBOOT` environment variable.

```bash
bundle exec sidekiq-process-manager --processes 4 --preboot config/boot.rb
```

or

```bash
SIDEKIQ_PREBOOT=config/boot.rb SIDEKIQ_PROCESSES=4 bundle exec sidekiq-process-manager
```

## Alternatives

Any process manager can be an alternative (service, update, systemd, monit, god, etc.).

The advantages this gem can provide are:

1. Pre-forking can be useful on systems with many cores but not enough memory to run enough sidekiq processes to use them all.

2. Running in the foreground with output going to standard out instead of as daemon can integrate better into containerized environments.

3. Built with sidekiq in mind so signal passing is consistent.
