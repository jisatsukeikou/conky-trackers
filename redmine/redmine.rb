#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'psych'

API_PATH = "redmine_api.yml" 
TZ_OFFSET = "+03:00"

module RedmineClient
    @@api = Psych.load File.read(API_PATH), symbolize_names: true
    @@config = @@api[:config]
    @@tracker = @@api[:tracker]

    @@headers = {"X-Redmine-API-Key": @@config[:api_key]}
    @@site = RestClient::Resource.new(@@config[:base_url])

    def self.issues()
        query_tracker :issues
    end

    def self.time()
        query_tracker :time
    end

    private

    def self.query_tracker(key)
        tracker_config = @@tracker[key]
        result = get_path tracker_config[:path], tracker_config[:params]
        result[tracker_config[:out_model].to_sym]
    end

    def self.get_path(path, params = {})
        json = @@site["#{path}.#{@@config[:content_type]}"].get @@headers.merge({params: params})
        JSON.parse json, symbolize_names: true
    end

    module Formatter
        @@date_format = lambda do |time_string| 
            time = Time.parse(time_string).localtime(TZ_OFFSET).to_datetime
            time.strftime "%d.%m.%y %k:%M"
        end

        def self.issue_short(issue)
            id = issue[:id]
            project_name = issue[:project][:name]
            subject = issue[:subject]
            updated = issue[:updated_on]

            "Issue: (#{@@date_format.call updated}) [#{project_name}] ##{id} #{subject}"
        end

        def self.time_short(time)
            project_name = time[:project][:name]
            comments = time[:comments]
            hours = time[:hours]
            updated = time[:updated_on]

            "Time:  (#{@@date_format.call updated}) [#{project_name}] -> #{comments} (#{hours}h)"
        end
    end
end

last_issues = RedmineClient.issues.to_h { |i| 
    [DateTime.parse(i[:updated_on]), RedmineClient::Formatter.issue_short(i)]
}
last_time = RedmineClient.time.to_h { |t| 
    [DateTime.parse(t[:updated_on]), RedmineClient::Formatter.time_short(t)]
}

last_issues.merge(last_time)
    .sort_by { |k, v| k }
    .reverse
    .each { |k, v| puts v }