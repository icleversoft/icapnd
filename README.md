#icapnd
A simple gem for sending push notification messages to ios devices.
It makes use of redis so can be run asynchronously.

## Installation
Add this line to your application's Gemfile:

    gem 'icapnd', '0.0.3', git: 'git://github.com/icleversoft/icapnd.git'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install icapnd

## Usage

###Server
You can run server as a daemon by invoking the following command:

    icapndaemon --pem path_to_pem --log path_to_log  --daemon
    
###Client (Sending a notification message)
In order to send a notification message, you should initially set redis url. 
This can be done by using the following code:

    require 'redis'
    Icapnd::Config.redis  = Redis.new(:host=>'127.0.0.1', :port => 6379)

and then you can easily create and send immediately a notification message:

    notification = Icapnd::Notification.new
    notification.device_token = token
    notification.alert = 'Hello world'
    notification.badge = 1
    notification.sound = 'oups.aif'
    notification.push


## Contributing

1. Fork it ( http://github.com/<my-github-username>/icapnd/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

