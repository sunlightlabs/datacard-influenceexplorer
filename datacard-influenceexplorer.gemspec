require File.expand_path('../lib/influence_explorer_mapping/version.rb', __FILE__)

Gem::Specification.new do |s|
  s.name = "datacard-influenceexplorer"
  s.version = InfluenceExplorerMapping::VERSION
  s.date = File.mtime(File.expand_path('../lib/influence_explorer_mapping/version.rb', __FILE__))
  s.authors = ["Dan Drinkard", "Sunlight Foundation"]
  s.summary = "An API mapping to add Influence Explorer as a data source for Datacard visualizations"
  s.description = "IMPORTANT NOTE: This mapping does automatic name resolution of individuals, organizations and politicians. You MUST verify your results independently."
  s.email = "ddrinkard@sunlightfoundation.com"
  s.homepage = "http://github.com/sunlightlabs/datacard-influenceexplorer"
  s.files = Dir["lib/**/*.rb"] + ['README.md', 'LICENSE']
  s.require_paths = ["lib"]

  s.add_dependency 'hashie'
  s.add_dependency 'httparty', '~>0.10.0'
  s.add_dependency 'json'
  s.add_dependency 'faraday'
  s.add_dependency 'datajam-datacard'
end
