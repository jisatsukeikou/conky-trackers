#!/usr/bin/env ruby

require 'gitlab'
require 'psych'

API_PATH = "gitlab_api.yml"
TZ_OFFSET = "+03:00"

class SimpleGitlabClient
    attr_reader :projects

    def initialize(api_path)
        @api = Psych.load File.read(api_path), symbolize_names: true 
        @api_config = @api[:config]
        @projects = @api[:projects]

        Gitlab.configure do |config|
            config.endpoint = @api_config[:base_url]
            config.private_token = @api_config[:api_token]
            config.sudo = nil
        end
    end

    def commits(project_name)
        Gitlab.commits project_name, per_page: 10
    end

    module Formatter
        @@date_format = lambda do |time_string| 
            time = Time.parse(time_string).localtime(TZ_OFFSET).to_datetime
            time.strftime "%d.%m.%y %k:%M"
        end

        def self.format_commit(project, commit)
            "(#{@@date_format.call commit.created_at}) [#{project}] #{commit.author_name} => #{commit.title}"
        end
    end
end

client = SimpleGitlabClient.new API_PATH
client.projects.each do |project|
    client.commits(project).each do |commit|
        puts SimpleGitlabClient::Formatter.format_commit project, commit 
    end
end