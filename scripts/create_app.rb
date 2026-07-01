require 'spaceship'
require 'dotenv'
Dotenv.load('.env')

begin
  token = Spaceship::ConnectAPI::Token.create(
    key_id: ENV['ASC_KEY_ID'],
    issuer_id: ENV['ASC_ISSUER_ID'],
    filepath: File.absolute_path(ENV['ASC_KEY_FILEPATH'])
  )
  Spaceship::ConnectAPI.token = token
  
  bundle_id = "com.slmcamp.PeriZen"
  
  app = Spaceship::ConnectAPI::App.find(bundle_id)
  if app.nil?
    puts "App not found. Attempting to create it via ConnectAPI..."
    # Create the app
    app = Spaceship::ConnectAPI::App.create(
      name: "PeriZen",
      version_string: "1.0",
      sku: bundle_id,
      primary_locale: "en-US",
      bundle_id: bundle_id
    )
    puts "✅ App successfully created: #{app.name}"
  else
    puts "✅ App already exists: #{app.name}"
  end
rescue => e
  puts "❌ Error: #{e.message}"
  exit 1
end
