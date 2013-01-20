require "spec_helper"

describe "HttpResponse" do

  it "should hold correct status, headers, contents" do
    nf = HttpResponse.not_found
    nf.status.should == 404
    nf.headers.should == {"Content-Type" => "text/html"}
    nf.content.should == 'Not Found'
    nf.not_found?.should be_true
    ok = HttpResponse.new 200, {'Content-Type' => 'text/html'}, 'This is html.'
    [ok.status, ok.headers, ok.content].should == [
        200, {'Content-Type' => 'text/html'}, 'This is html.'
    ]
    ok.ok?.should be_true
  end
end
