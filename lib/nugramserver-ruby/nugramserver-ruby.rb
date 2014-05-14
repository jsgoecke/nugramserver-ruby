# NuGram Hosted Server client API in Ruby
#
# This code relies on the 'json' Ruby gem.
#
# Copyright (C) 2009,2010,2011 Nu Echo Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions.

require 'rubygems' 
require 'json'
require 'net/http'
require 'net/https'
require 'uri'


DEFAULT_SERVER_HOST = "www.grammarserver.com"
DEFAULT_SERVER_PORT = 443

## An object of this class acts as a proxy to NuGram Hosted Server.
class GrammarServer

  attr_reader :host, :port

  def initialize(host=DEFAULT_SERVER_HOST, port=DEFAULT_SERVER_PORT)
    @host = host
    @port = port
  end
  
  def get_url
    "https://#{@host}:#{@port}"
  end
  
  def create_session(username, password)
    GrammarServerSession.new(self, username, password)
  end
  
  def session(username, password, sessionid)
    GrammarServerSession.new(self, username, password, sessionid)
  end

end

## This class represents a session with NuGram Hosted Server.

class GrammarServerSession

  attr_reader :server, :username, :password

  def initialize(server, username, password, sessionid = nil)
    @server = server
    @username = username
    @password = password
    @sessionid = if sessionid == nil then
                   self.connect
                 else
                   sessionid
                 end
  end
  
  ## Returns the session ID
  def get_id
    @sessionid
  end

  def basic_auth
    'Basic ' + ["#{@username}:#{@password}"].pack('m').delete("\r\n")
  end
  private :basic_auth

  def create_http 
    http = Net::HTTP.new(@server.host, @server.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    headers = {
      'Authorization' => basic_auth()
    }
    [http, headers]
  end
  
  def connect
    http, headers = create_http
    response, data = http.post('/api/session', "responseFormat=json", headers)

    case response
    when Net::HTTPSuccess then
      result = JSON.parse(response.body)
      result['session']['id']
    else
      response.error!
    end
  end
  
  ## Terminates the session with NuGram Hosted Server
  def disconnect
    http, headers = create_http
    http.delete("/api/session/#{@sessionid}", headers)
  end
  
  ## This method uploads a source grammar to NuGram Hosted Server.
  def upload(grammarPath, content)
    http, headers = create_http
    
    response = http.request_put("/api/grammar/#{grammarPath}", content, headers)
    case response
    when Net::HTTPSuccess then
      true
    else
      response.error!
    end
  end
  
  ## This method requests NuGram Hosted Server to load a static grammar.
  def load(grammarPath)
    instantiate(grammarPath, {})
  end

  ## This method instantiates a dynamic grammar and loads it.
  def instantiate(grammarPath, context)
    http, headers = create_http

    response = http.request_post("/api/grammar/#{@sessionid}/#{grammarPath}",
                                 "responseFormat=json&context=#{context.to_json}",
                                 headers)
    case response
    when Net::HTTPSuccess then
      result = JSON.parse(response.body)
      InstantiatedGrammar.new(self, result['grammar'])
    else
      response.error!
    end
  end
  
end


## Objects of this class act as proxy for instantiated grammars on NuGram Hosted Server.

class InstantiatedGrammar

  def initialize(session, data)
    @session = session
    @data = data
  end
  
  ## Returns the URL of the grammar
  def get_url (extension = 'abnf')
    grammarUrl = @data['grammarUrl']
    "#{grammarUrl}.#{extension}"
  end
  
  ## Retrieves the source representation of the grammar in the 
  ## requested format ('abnf', 'grxml', or 'gsl')
  def get_content (extension = 'abnf')
    http, headers = @session.create_http
    
    url = URI.parse(self.get_url(extension))
    http.request_get(url.path, headers) {|response|
      case response
      when Net::HTTPSuccess then
        response.body
      else
        response.error!
      end
    }
  end

  ## Computes the semantic interpretation of the given sentence
  ## (which must a string). Returns a Python object of 'False' if
  ## the sentence cannot be parsed by the grammar.
  def interpret(sentence)
    http, headers = @session.create_http

    url = URI.parse(@data['interpreterUrl'])
    sentence = URI.escape(sentence)

    http.request_post(url.path, "responseFormat=json&sentence=#{sentence}", headers) {|response|
      case response
      when Net::HTTPSuccess then
        return JSON.parse(response.body)['interpretation']
      else
        response.error!
      end
    }
  end

end
