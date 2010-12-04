NuGram Hosted Server client APIs
================================

This repository provides the Ruby client API to the NuGram Hosted Server in various languages. It is based on the Ruby library available at https://github.com/nuecho/nugramserver-clients.

NuGram Hosted Server (www.grammarserver.com) is a free hosted service for the management of static and dynamic grammars, courtesy of Nu Echo Inc. It can be used to generate dynamic grammars, and interpret textual sentences.

Installation
------------

	gem install nugramserver-ruby

Example
-------

Say you want to create a dynamically-generated grammar for a simple voice-dialing application. The grammar template, hosted on www.grammarserver.com, could look like the following:

### voicedialing.abnf (ABNF template grammar)
    #ABNF 1.0;
    
    language en-US;
    mode voice;
    root $voicedialing;

    public $voicedialog = 
      [$politeness]
      @for (entry : entries) 
        ( [@word entry.firstname] @word entry.lastname 
          @tag "out.id = '" entry.id "'" @end )
      @end
      [please]
    ;
    
    $politeness = 
        (I would | I'd) like to (speak with| talk to) 
      | give me
    ;

And the code to instantiate the grammar would look like:

### app.rb (Ruby)

	require 'nugramserver-ruby'
    server = GrammarServer.new()
    session = server.create_session("username", "password")
    grammar = session.instantiate("voicedialing.abnf", 
                                  {'entries' => 
                                    [{'firstname' => "John", 'lastname' => 'Doe', 'id' => '1234'},
                                     {'firstname' => "Bill", 'lastname' => 'Smith', 'id' => '4321'}]})
    puts "grammar url = ", grammar.get_url('grxml')
    # ....
    # When you are done with the grammar...
    session.disconnect

Supported languages
-------------------

The supported languages are currently:

- Ruby/JRuby

Contact Info
------------

For any question or request, contact the NuGram team at nugram-support@nuecho.com. The NuGram Platform website is http://nugram.nuecho.com

The Nu Echo team

