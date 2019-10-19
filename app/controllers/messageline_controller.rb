class MessagelineController < ApplicationController
     require 'line/bot'  # gem 'line-bot-api'#何でrequireしてるのかわからない
     require 'open-uri'
     require 'nokogiri'
  
 # @region = params["events"][0]["message"]["text"] postのパラミーターから取得したい
   # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]
  
  #nokogiriとopen-uriを利用して横須賀の今日の天気予報を取得する
def get_today_forecast_yokosuka #天気予報を取得するメソッド(横須賀)
  #スクレイピング対象のURL
  url = "https://tenki.jp/forecast/3/17/4610/14201/"
  #取得するhtml用charset
  charset = nil
 
  html = open(url) do |page|
    #charsetを自動で読み込み、取得
    charset = page.charset
    #中身を読む
    page.read
  end
  
  # Nokogiri で切り分け
  contents = Nokogiri::HTML.parse(html,nil,charset)
  #CSSセレクタで指定してデータを取得
  contents.css('#main-column > section > div.forecast-days-wrap.clearfix > section.today-weather > div.weather-wrap.clearfix > div.weather-icon > p').each do |link| 
  @today_forecast_yokosuka = "横須賀市\n今日の天気 #{link.content}" 
  end
  contents.css('#main-column > section > div.forecast-days-wrap.clearfix > section.today-weather > div.weather-wrap.clearfix > div.date-value-wrap > dl > dd.high-temp.temp > span.value').each do |link|
  @highest_temperature_yokosuka = "最高気温 #{link.content}度"
  end 
  contents.css('#main-column > section > div.forecast-days-wrap.clearfix > section.today-weather > div.weather-wrap.clearfix > div.date-value-wrap > dl > dd.low-temp.temp > span.value').each do |link|
  @lowest_temperature_yokosuka = "最低気温 #{link.content}度"
  end 
end 


def get_today_forecast_yokohama
  
  url = "https://tenki.jp/forecast/3/17/4610/14100/"
  
  charset = nil
  
  html = open(url) do |page|
    charset = page.charset
    page.read
  end 
  
  contents = Nokogiri::HTML.parse(html,nil,charset)
  contents.css('#main-column > section > div.forecast-days-wrap.clearfix > section.today-weather > div.weather-wrap.clearfix > div.weather-icon > p').each do |link|
  @today_forecast_yokohama = "横浜市\n今日の天気 #{link.content}"
  end 
  contents.css('#main-column > section > div.forecast-days-wrap.clearfix > section.today-weather > div.weather-wrap.clearfix > div.date-value-wrap > dl > dd.high-temp.temp > span.value').each do |link|
  @highest_temperature_yokohama = "最高気温 #{link.content}度"
  end 
  contents.css('#main-column > section > div.forecast-days-wrap.clearfix > section.today-weather > div.weather-wrap.clearfix > div.date-value-wrap > dl > dd.low-temp.temp > span.value').each do |link|
  @lowest_temperature_yokohama = "最低気温 #{link.content}度"
  end 
end 
  
  
  
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read #リクエストに入っているものを取得している？

    signature = request.env['HTTP_X_LINE_SIGNATURE']#リクエストがLINEプラットフォームから送られたものかどうかを検証する。
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)#parseだからなんかjsonデータをrubyの形式にしている？

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          if event.message['text'] == "横須賀"
            get_today_forecast_yokosuka
            message = {
              type: 'text',
              text: "#{@today_forecast_yokosuka} #{@highest_temperature_yokosuka} #{@lowest_temperature_yokosuka}" #event.message['text']
            }
          elsif event.message['text'] == "横浜"
            get_today_forecast_yokohama
            message = {
              type: 'text',
              text: "#{@today_forecast_yokohama} #{@highest_temperature_yokohama} #{@lowest_temperature_yokohama}"
            }
            
          else 
            message = {
              type: 'text',
              text: '横須賀か横浜と入力してください。'
            }
          end
          client.reply_message(event['replyToken'], message)
        end
      end
    }

    head :ok
  end
end
