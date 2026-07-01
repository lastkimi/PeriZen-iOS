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

  # 1. Primary Category
  puts "Updating Primary Category..."
  app_info = app.fetch_edit_app_info

  # Find 'Productivity' category
  prod_id = "PRODUCTIVITY"
  
  begin
    app_info.update(primary_category_id: prod_id)
    puts "✅ Primary Category updated to #{prod_id}."
  rescue => e
    puts "Error updating category: #{e.message}"
  end

  # 2. App Review Contact Information
  puts "Updating App Review Contact Information..."
  version = app.get_edit_app_store_version

  begin
    # Try to fetch, if it throws 'No data', we rescue and create it.
    review_detail = nil
    begin
      review_detail = version.fetch_app_store_review_detail
    rescue => fetch_e
      if fetch_e.message.include?("No data")
        puts "No existing App Review Detail found (No data error). Proceeding to create one..."
      else
        raise fetch_e
      end
    end

    if review_detail.nil?
      puts "Creating new App Store Review Detail..."
      review_detail = Spaceship::ConnectAPI.post_app_store_review_detail(
        app_store_version_id: version.id,
        attributes: {
          contactFirstName: "Peng",
          contactLastName: "Liu",
          contactEmail: "brucelieu@slmcamp.com",
          contactPhone: "+8613800138000",
          demoAccountName: "",
          demoAccountPassword: "",
          demoAccountRequired: false,
          notes: "This app relies on ambient light and haptics for focus. No external hardware is required."
        }
      )
      puts "✅ Created and populated App Review Information."
    else
      puts "Updating existing App Store Review Detail..."
      review_detail.update(attributes: {
        contactFirstName: "Peng",
        contactLastName: "Liu",
        contactEmail: "brucelieu@slmcamp.com",
        contactPhone: "+8613800138000",
        demoAccountRequired: false,
        notes: "This app relies on ambient light and haptics for focus. No external hardware is required."
      })
      puts "✅ Updated App Review Information."
    end
  rescue => e
    puts "Error updating App Review Detail: #{e.message}"
  end

  puts "Done."
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
  exit 1
end
