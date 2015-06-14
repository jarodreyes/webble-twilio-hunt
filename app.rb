require "bundler/setup"
require "sinatra"
require "sinatra/multi_route"
require "data_mapper"
require "twilio-ruby"
require 'twilio-ruby/rest/messages'
require "sanitize"
require "erb"
require "rotp"
require "haml"
require "json"
include ERB::Util

set :static, true
set :root, File.dirname(__FILE__)

DataMapper::Logger.new(STDOUT, :debug)
DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://postgres:postgres@localhost/jreyes')

# User should have points, guesses, images, and a name.
class HuntPlayer
  include DataMapper::Resource

  property :id, Serial
  property :phone_number, String, :length => 30
  property :nickname, String
  property :status, Enum[ :new, :naming, :hunting], :default => :new
  property :points, Integer, :default => 0

  has n, :images
  has n, :guesses

end

class Image
  include DataMapper::Resource

  property :id, Serial
  property :url, Text
  property :accepted, Boolean

  belongs_to :hunt_player

end

class Guess
  include DataMapper::Resource

  property :id, Serial
  property :correct, Boolean

  belongs_to :hunt_player

end
DataMapper.finalize
DataMapper.auto_upgrade!

before do
  @hunt_number = ENV['BARISTA_NUMBER']
  @twilio_number = ENV['TWILIO_NUMBER']
  @client = Twilio::REST::Client.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN']
  
  if params[:error].nil?
    @error = false
  else
    @error = true
  end

end

get "/" do
  haml :index
end

def to_boolean(str)
  str == 'true'
end

def sendAdminMessage(error)
  message = @client.account.messages.create(
    :from => @twilio_number,
    :to => "+12066505813",
    :body => error
  )
  puts message.to
end

def sendMessage(to, body)
  message = @client.account.messages.create(
    :from => @hunt_number,
    :to => to,
    :body => body
  )
  puts message.to
end

get "/players" do
  @users = HuntPlayer.all
  haml :users
end

get "/images" do
  @images = Image.all
  haml :images
end

post "/update-player" do
  player_id = params[:player_id]
  image_id = params[:image_id]
  correct = to_boolean(params[:correct])

  @player = HuntPlayer.get(player_id)
  @player_phone = @player.phone_number

  @image = Image.get(image_id)
  @image.update(:accepted => correct)

  if correct
    # Score this point
    if not @player.nil?
      @points = @player.points + 1
      puts "******************* points: #{@points} **********************"
      @player.update(:points => @points)
    end

    if @player.points >= 20
      @output = "Congratulations! You found all of the clues!"
    else
      @output = "Well done! You found one of the beacons. Now go find some more!"
    end
  else
    @output = "Looks like that guess wasn't right. You're very close though!"
  end
  sendMessage(@player_phone, @output)
end

get "/api/images.json" do
  @tacos = Image.all
  @tacos.to_json
end

# Register a subscriber through the web and send verification code
route :get, :post, '/sms-register' do
  @phone_number = Sanitize.clean(params[:From])
  @body = params[:Body]
  puts @error

  if @error == false
    user = AnonUser.first_or_create(:phone_number => @phone_number)
    if not @body.nil?
      user.messages.create(:body => @body)
      user.save
    end
  end

  @msg = "Hi! I am the Twilio-powered candy machine. Please let me know what would you like to have in the candy machine next month?"
  message = @client.account.messages.create(
    :from => @cowork_number,
    :to => @phone_number,
    :body => @msg
  )
  puts message.to
  @msg2 = "This number was made intelligent using Twilio. See the code at: bit.ly/3rdCandy"
  message = @client.account.messages.create(
    :from => @cowork_number,
    :to => @phone_number,
    :body => @msg2
  )
  puts message.to

end

# Webble + Twilio webhook
# Phone Number: 6692382267
# Register a player nickname then receive their images
route :get, :post, '/hunt' do
  @phone_number = Sanitize.clean(params[:From])
  @bodyRaw = params[:Body]
  @body = params[:Body].downcase
  puts "******************* ERROR: #{@error} **********************"
  puts "******************* BODY: #{@body} **********************"

  @options = ""

  if @error == false
    @player = HuntPlayer.first_or_create(:phone_number => @phone_number)

    # Standard instructions
    helpMsg = "Ok #{@player.nickname}, time to go find your first clue! In order to find it you'll need to download the Webble app. iOS: https://itunes.apple.com/us/app/webble/id648500262?mt=8. Android: https://play.google.com/store/apps/details?id=com.webble.browser.

    Instructions: Open the Webble App. Locate any beacon labeled 'SDSW-Hunt'. Open the photos for that beacon. Take a picture of yourself next to the object in the photo. Text that photo to this number.

    Type 'Instructions' at anytime to repeat these instructions."

    # this is our main game trigger, depending on users status in the game, respond appropriately
    status = @player.status

    if @body == 'instructions'
      @output = helpMsg
    else
      # switch based on 'where' in the game the user is.
      case status

      # Setup the player details
      when :new
        @output = "Welcome to the StartupWeek Scavenger Hunt, brought to you by Webble and Twilio. To get started, what will your super awesome nickname be?"
        @player.update(:status => 'naming')

      # Get Player NickName
      when :naming
        if @player.nickname.nil?
          @player.nickname = @bodyRaw
          @player.save
          @output = "We have your nickname as #{@bodyRaw}. Is this correct? [yes] or [no]?"
        else
          if @body == 'yes'
            puts "Sending #{@player.nickname} a clue."
            @output = helpMsg

            @player.update(:status => 'hunting')
          else
            @output = "Okay I guess we've got that wrong. What is your nickname then?"
            @player.update(:nickname => nil)
          end
        end

      # When the user is hunting
      when :hunting
        @media = params[:MediaUrl0]
        puts "******************* Media: #{@media} **********************"
        puts "******************* params: #{params} **********************"

        # No picture was sent
        if @media.nil?
          @output = "Sorry, but to prove you found the clue, please send us a picture with the object in the beacons photo."

        # Okay we got a picture
        else
          @player.images.create(:url => @media)
          @player.save

          @output = "Okay we got your image. One of our judges will check to make sure it is correct. We'll text you when they have confirmed it! In the meantime keep hunting!"
        end

      end

    end

  # Error occurred
  else
    sendAdminMessage(@error)

  end

  Twilio::TwiML::Response.new do |r|
    r.Message @output
  end.text
end