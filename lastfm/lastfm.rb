#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'psych'
require_relative '../../terminal-formatters/terminal_formatter'

include TerminalFormatter::Conky

API_PATH = "lastfm_api.yml" 

CONKY_FONT="Noto Sans CJK JP"

api = Psych.load File.read(File.join(__dir__, API_PATH)), symbolize_names: true
config = api[:config]
url = "https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&limit=1&user=#{config[:user]}&api_key=#{config[:api_key]}&format=json"

URI.open(url) do |json_data|
  scrobbles = JSON.load(json_data)
  lasttrack = scrobbles["recenttracks"]["track"].first
  if lasttrack.key?("@attr") && lasttrack["@attr"]["nowplaying"] == "true"
    case ARGV[0]
      when "artist"
        puts lasttrack["artist"]["#text"]
        puts lasttrack["album"]["#text"]
      when "title"
        puts lasttrack["name"]
      else
        printf offset(65)
        name = font(CONKY_FONT, size: 12) { lasttrack["name"] }
        print name
        printf br

        artist_album = font(CONKY_FONT, size: 8) do |f|
          f << offset(65)
          f << lasttrack["artist"]["#text"].to_s
          unless lasttrack["album"]["#text"].empty?
            f << br
            f << offset(65)
            f << lasttrack["album"]["#text"].to_s 
          end
          f 
        end
        printf artist_album
        puts
    end
  else
    puts "#{offset 65}Not playing right now"
    puts
    puts
  end
end
