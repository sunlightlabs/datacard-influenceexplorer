module InfluenceExplorerMapping
  module ValueSetters
    def lookup_entity_id(str)
      api_key = persisted_settings.settings['apikey']
      data = JSON.parse(HTTParty.get("https://inbox.influenceexplorer.com/contextualize?apikey=#{api_key}&text=#{CGI.escape str}").body) rescue str
      id = data['entities'][0]['entity_data']['id'] rescue str
      id
    end
  end
end