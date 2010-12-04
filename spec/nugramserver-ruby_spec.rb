require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# These tests are all local unit tests
#FakeWeb.allow_net_connect = false

describe "NugramserverRuby" do
  before(:all) do
    # Define our Nu Echo Grammar Server credentials
    @username = 'rubygem'
    @password = 'nuechorox!'
    
    # Authentication resource
    FakeWeb.register_uri(:post, 
                         "http://#{@username}:#{@password}@www.grammarserver.com:8082/session", 
                         :content_type => 'application/json',
                         :status       => ["200", "Ok"],
                         :body         => "{\"session\": {\"id\":\"524DC3C5041FC48DD27E\"}}")

   # Create a new grammar
   # FakeWeb.register_uri(:post, 
   #                      "http://#{@username}:#{@password}@www.grammarserver.com:8082/grammar/524DC3C5041FC48DD27E/voicedialing.abnf",
   #                      :content_type => 'application/json',
   #                      :status       => ["200", "Ok"],
   #                      :body         => "{\"session\": {\"id\":\"524DC3C5041FC48DD27E\"}}")
                        
    @grammar_server = GrammarServer.new
  end
  
  it "should create a GrammarServer object" do
    @grammar_server.instance_of?(GrammarServer).should == true
  end
  
  it "should create a new Nugram Grammar Server session" do
    session = @grammar_server.create_session(@username, @password)
  end
  
  it "should create a grammar" do
    pending()
    session = @grammar_server.create_session(@username, @password)
    grammar = session.instantiate("voicedialing.abnf", 
                                    { 'entries' => 
                                      [{ 'firstname' => "John", 'lastname' => 'Doe', 'id' => '1234' },
                                       { 'firstname' => "Bill", 'lastname' => 'Smith', 'id' => '4321' }] })
    p grammar
  end
end
