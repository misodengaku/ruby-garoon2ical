#!/usr/bin/env ruby
#coding: utf-8

require 'rubygems'
require 'mechanize'
require 'csv'
require 'icalendar'
require 'kconv'
require 'yaml'


#設定の読み込み
conf = YAML.load_file("config.yaml")

agent = Mechanize.new
page = agent.get conf["cybozu_url"]
form = page.forms.first
form.field_with(:name => "_account").value = conf["username"]
form.field_with(:name => "_password").value = conf["password"]
result = form.submit

#ここまでで、ログインできてる
# Todo: なおす
form = result.forms[2]


#現在日付から 90日とってみよう
today = Date.today
endday = today + conf["date_range"]
p form
p form.field_with(:name => "start_year")
form.field_with(:name => "start_year").value = today.year
form.field_with(:name => "start_month").value = today.month
form.field_with(:name => "start_day").value = "1"
form.field_with(:name => "end_year").value = endday.year
form.field_with(:name => "end_month").value = endday.month
form.field_with(:name => "end_day").value = endday.day
form.field_with(:name => "charset").value = "UTF-8"
form.radiobutton_with(:name => "item_name",:value => "0").check
result2 = form.submit

#open(conf["calname"]+".csv","w") do |f|
#  f.print result2.body
#end

csv = CSV.parse(result2.body.toutf8)
# iCalオブジェクトの生成
cal = Icalendar::Calendar.new

cal.timezone do |t|
  t.tzid = 'Asia/Tokyo'
  t.standard do |s|
    s.tzoffsetfrom = '+0900'
    s.tzoffsetto   = '+0900'
    s.tzname       = 'JST'
    s.dtstart      = '19700101T000000'
  end
end

cal.append_custom_property('X-WR-CALNAME;VALUE=TEXT', "#{conf['calname']}")

csv.each do |sc|
  cal.event do |e|
    e.summary     = sc[5]+"("+sc[4]+")"
    e.description = sc[6].sub(/\n/,"")
    e.dtstart     = Icalendar::Values::DateTime.new(DateTime.parse(sc[0]+" "+sc[1]), {'TZID' => 'Asia/Tokyo'})
    e.dtend       = Icalendar::Values::DateTime.new(DateTime.parse(sc[2]+" "+sc[3]), {'TZID' => 'Asia/Tokyo'})
  end
end

cal.publish

# iCalファイル生成
File.open(conf["calname"]+".ics", "w+b") { |f|
    f.write(cal.to_ical.toutf8)
}
