require 'delayed/recipes'

before "deploy:restart", "delayed_job:stop"
after "deploy:restart", "delayed_job:start"
