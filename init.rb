require 'redmine'

Redmine::Plugin.register :redmine_rate_extender do
  name 'Rate Extender Plugin'
  author 'Ivan Astafyev'
  description 'A plugin for extending Eric Davis\' Rate Plugin'
  version '0.0.1'
  requires_redmine :version_or_higher => '0.8.0'
  Redmine::Plugin.find(:redmine_rate)
end
