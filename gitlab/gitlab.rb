#!/usr/bin/env ruby

require 'gitlab'
require 'psych'

API_PATH = "gitlab_api.yml"
TZ_OFFSET = "+03:00"

class SimpleGitlabClient
    attr_reader :projects
    attr_reader :limit

    def initialize(api_path)
        @api = Psych.load File.read(File.expand_path(API_PATH, File.dirname(__FILE__))), symbolize_names: true
        @api_config = @api[:config]
        @projects = @api[:projects]
        @limit = @api_config[:limit] || 10

        Gitlab.configure do |config|
            config.endpoint = @api_config[:base_url]
            config.private_token = @api_config[:api_token]
            config.sudo = nil
        end
    end

    def commits(project_name)
        Gitlab.commits project_name, per_page: @limit
    end

    module Formatter
        @@date_format = lambda do |time_string|
          time = Time.parse(time_string).localtime(TZ_OFFSET).to_datetime
          time.strftime "%d.%m.%y %k:%M"
        end

        def self.format_commit(commit)
          date =@@date_format.call commit.created_at
          project_name = commit.project_name.split(?/)[1]
          "(#{date}) [#{project_name}] #{commit.author_name} => #{commit.title}"
        end
    end
end


def get_all_commits()
  client = SimpleGitlabClient.new API_PATH
  client.projects
    .flat_map { |p|
      client.commits(p).map { |c|
        commit_merged = c.to_h.merge({project_name: p})
        Gitlab::ObjectifiedHash.new(commit_merged)
      }
    }
    .sort_by {|c| Time.parse(c.created_at).to_i}
    .reverse
    .slice(0, client.limit)
    .each {|c| puts SimpleGitlabClient::Formatter.format_commit c}
end

get_all_commits
