require 'open-uri'
require 'sinatra'
require "sinatra/reloader" if development?

get '/' do
  text = get_text("https://scrapbox.io/api/pages/ongaeshi/extensive_reading/text")
  readings = parse_text(text)
  total = readings.reduce(0) {|r, i| r + i.word_count}

  unfinished = readings.find_all {|e| e.unfinish? }
  sort_by_date = readings.find_all {|e| e.finish_date != nil }.sort_by {|e| e.finish_date }
  start_date = sort_by_date.first.finish_date.strftime("%Y/%m/%d")
  end_date = sort_by_date.last.finish_date.strftime("%Y/%m/%d")

  days = (sort_by_date.last.finish_date - sort_by_date.first.finish_date) / 60 / 60 / 24
  words_per_day = (total / days).to_i

<<EOS
#{total} words<br>
#{readings.count} readings (#{unfinished.count} unfinished)<br>
#{start_date}-#{end_date} (#{words_per_day} words/day) <br> 
EOS
end

def get_text(url)
  URI.open(url) do |f|
    return f.read
  end
end

class Reading
  attr_reader :name, :word_count, :finish_date

  def initialize(line)
    data = line.split(" ")
    @name = data[0..-3].join(" ")
    @finish_date = Time.parse(data[-1]) rescue nil
    @word_count = unfinish? ? 0 : data[-2].to_i
  end

  def unfinish?
    @finish_date.nil?
  end
end

def parse_text(src)
  src = src.split("\n")[1..-1]
  src.delete_if {|e| e =~ /^#/}
  src.map {|e| Reading.new(e) }
end