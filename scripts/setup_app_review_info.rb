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

  # 1. Update Age Rating
  puts "Fetching App Info..."
  app_infos = [app.fetch_edit_app_info].compact
  app_infos.each do |app_info|
    puts "Fetching age rating declaration for app info..."
    age_rating = app_info.fetch_age_rating_declaration
    if age_rating
      puts "Updating age rating to 4+ defaults..."
      age_rating.update(attributes: {
        violenceCartoonOrFantasy: "NONE",
        violenceRealisticProlongedGraphicOrSadistic: "NONE",
        violenceRealistic: "NONE",
        profanityOrCrudeHumor: "NONE",
        matureOrSuggestiveThemes: "NONE",
        horrorOrFearThemes: "NONE",
        medicalOrTreatmentInformation: "NONE",
        alcoholTobaccoOrDrugUseOrReferences: "NONE",
        gambling: false,
        sexualContentGraphicAndNudity: "NONE",
        sexualContentOrNudity: "NONE",
        gamblingSimulated: "NONE",
        contests: "NONE",
        unrestrictedWebAccess: false,
        parentalControls: false,
        healthOrWellnessTopics: false,
        messagingAndChat: false,
        advertising: false,
        ageAssurance: false,
        gunsOrOtherWeapons: "NONE",
        lootBox: false,
        userGeneratedContent: false
      })
      puts "✅ Age rating updated successfully to 4+."
    end
  end

  # 2. Update Content Rights (Third-party content)
  puts "Fetching App Info for Content Rights..."
  app_infos = [app.fetch_edit_app_info].compact
  app_infos.each do |app_info|
    begin
      app_info.update(attributes: {
        usesNonExemptEncryption: false,
        hasAppStoreContentRight: false
      })
      puts "✅ App info (Encryption/Content Rights) updated to: No third-party content."
    rescue => e
      puts "Could not update content rights directly via this model: #{e.message}"
    end
  end

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
  exit 1
end
