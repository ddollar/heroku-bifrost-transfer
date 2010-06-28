require "heroku/command/bifrost"

Heroku::Command::Help.group 'Bifrost' do |group|
  group.command 'bifrost:transfer', 'transfer data to a new bifrost instance'
end
