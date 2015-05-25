require 'rufus-scheduler'
s = Rufus::Scheduler.singleton
s.every '30m' do
  #Parser.locationScraping
  #Parser.jsonParsing
end