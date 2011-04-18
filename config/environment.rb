# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
App::Application.initialize!

require 'flickraw'

FlickRaw.api_key = ""
FlickRaw.shared_secret = ""

require 'factual'
FACTUAL_API_KEY = ""
FACTUAL_TABLE = ""
