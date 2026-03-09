require 'grape-swagger'

module Mapi
  Dir[Pathname.new(File.dirname(__FILE__)).join("../../controller/*.rb")].each { |f| require f }

  class Root < Grape::API
    version 'v1', using: :path
    format :json
    rescue_from :all

    mount ::Mapi::Mapi_utils
    
    add_swagger_documentation base_path: "/api",
                              schemes: ["https","http"],
                              api_version: 'v1',
                              hide_documentation_path: true,
                              info: {
                                  title: "BMTU - Docs"
                              }

  end
end
