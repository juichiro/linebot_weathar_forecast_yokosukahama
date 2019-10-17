class MessagelineController < ApplicationController
     require 'line/bot'  # gem 'line-bot-api'#何でrequireしてるのかわからない
     require 'open-uri'
     require 'nokogiri'
  
  
  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

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
          message = {
            type: 'text',
            text: 'うんち' #event.message['text']
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    }

    head :ok
  end
end
