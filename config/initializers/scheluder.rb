require 'rufus-scheduler'
s = Rufus::Scheduler.singleton
s.every '30m' do
  #Parser.locationScraping
  #comment out above line if you want to scape the location and postcode again
  Parser.jsonParsing  # used to scrape weatehr data from BOM website
end