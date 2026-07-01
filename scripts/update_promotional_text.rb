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
  
  app = Spaceship::ConnectAPI::App.find("com.slmcamp.PeriZen")
  if app.nil?
    puts "App not found"
    exit 1
  end

  puts "Found app: #{app.name}"

  version = app.get_edit_app_store_version
  if version.nil?
    puts "Could not find an editable App Store Version."
    exit 1
  end

  puts "Updating Copyright..."
  begin
    version.update(attributes: {
      copyright: "2026 Hangzhou Inkblaze AI Technology Co., Ltd."
    })
    puts "✅ Copyright updated."
  rescue => e
    puts "Error updating copyright: #{e.message}"
  end

  puts "Fetching Version Localizations..."
  localizations = version.get_app_store_version_localizations

  localizations.each do |loc|
    puts "Updating localization for #{loc.locale}..."
    if loc.locale == "en-US"
      loc.update(attributes: {
        promotionalText: "Step into profound focus and escape digital noise.",
        supportUrl: "https://slmcamp.com",
        marketingUrl: "https://slmcamp.com"
      })
      puts "✅ Updated en-US promotional text and URLs."
    elsif loc.locale == "zh-Hans"
      loc.update(attributes: {
        promotionalText: "告别数字喧嚣，感受真正的无感陪伴与深度专注。",
        supportUrl: "https://slmcamp.com",
        marketingUrl: "https://slmcamp.com"
      })
      puts "✅ Updated zh-Hans promotional text and URLs."
    end
  end

  puts "Finished updating textual metadata directly via API."
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
  exit 1
end
