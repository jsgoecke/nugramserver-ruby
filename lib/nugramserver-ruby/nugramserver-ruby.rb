# NuGram Hosted Server client API in Ruby
#
# This code relies on the 'json' Ruby gem.
#
# Copyright (C) 2009, 2010 Nu Echo Inc.
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
require 'uri'


DEFAULT_SERVER_HOST = "www.grammarserver.com"
DEFAULT_SERVER_PORT = 8082

## An object of this class acts as a proxy to NuGram Hosted Server.
class GrammarServer

  attr_reader :host, :port

  def initialize(host=DEFAULT_SERVER_HOST, port=DEFAULT_SERVER_PORT)
    @host = host
    @port = port
  end
  
  def get_url
    "http://#{@host}:#{@port}"
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
  
  def connect
    Net::HTTP.start(@server.host, @server.port) {|http|
      req = Net::HTTP::Post.new('/session')
      req.body= "responseFormat=json"
      req.basic_auth @username, @password
      response = http.request(req)
      case response
        when Net::HTTPSuccess then
           result = JSON.parse(response.body)
           result['session']['id']
        else
          response.error!
        end
    }
  end
  
  ## Terminates the session with NuGram Hosted Server
  def disconnect
    Net::HTTP.start(@server.host, @server.port) {|http|
      req = Net::HTTP::Delete.new("/session/#{@sessionid}")
      req.basic_auth @username, @password
      response = http.request(req)
    }
  end
  
  ## This method uploads a source grammar to NuGram Hosted Server.
  def upload(grammarPath, content)
    Net::HTTP.start(@server.host, @server.port) {|http|
      req = Net::HTTP::Put.new("/grammar/#{grammarPath}")
      req.body= content
      req.basic_auth @username, @password
      response = http.request(req)
      case response
        when Net::HTTPSuccess then
          true
        else
          response.error!
        end
    }    
  end
  
  ## This method requests NuGram Hosted Server to load a static grammar.
  def load(grammarPath)
    instantiate(grammarPath, {})
  end

  ## This method instantiates a dynamic grammar and loads it.
  ## The 'context' argument is expected to be a hash (dictionary) that
  ## maps strings to values. Each value must be convertible to standard JSON.
  ## Each key in the context must correspond to the name of a variable in the
  ## ABNF template.
  def instantiate(grammarPath, context)
    Net::HTTP.start(@server.host, @server.port) {|http|
      req = Net::HTTP::Post.new("/grammar/#{@sessionid}/#{grammarPath}")
      body = URI.escape(context.to_json)
      req.body= "responseFormat=json&context=#{context.to_json}"
      req.basic_auth @username, @password
      response = http.request(req)
      case response
        when Net::HTTPSuccess then
           result = JSON.parse(response.body)
           InstantiatedGrammar.new(self, result['grammar'])
        else
          response.error!
        end
    }    
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
    url = URI.parse(self.get_url(extension))
    Net::HTTP.start(url.host, url.port) {|http|
      req = Net::HTTP::Get.new(url.path)
      response = http.request(req)
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
    url = URI.parse(@data['interpreterUrl'])
    sentence = URI.escape(sentence)
    Net::HTTP.start(url.host, url.port) {|http|
      req = Net::HTTP::Post.new(url.path)
      req.body= "responseFormat=json&sentence=#{sentence}"
      req.basic_auth @session.username, @session.password
      response = http.request(req)
      case response
        when Net::HTTPSuccess then
           JSON.parse(response.body)['interpretation']
        else
          response.error!
        end
    }        
  end

end

