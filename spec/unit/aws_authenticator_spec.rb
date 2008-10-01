
require 'resourceful'
require File.dirname(__FILE__) + '/../../lib/dm-simpledb-adapter/aws_authenticator'

describe AwsAuthenticator do

  before do
    @http = Resourceful::HttpAccessor.new
    @resource = @http.resource('http://johnsmith.s3.amazonaws.com/photos/puppy.jpg')
    @request = Resourceful::Request.new(:get, 
                                        @resource,
                                        nil,
                                        :date => "Tue, 27 Mar 2007 19:36:42 +0000"
                                       )

    # the keys from http://docs.amazonwebservices.com/AmazonS3/2006-03-01/
    @access_key = "0PN5J17HBGZHT7JJ3X82"
    @secret_key = "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    @bucket = "johnsmith"

    @aws_auth = AwsAuthenticator.new(@access_key,
                                     @secret_key,
                                     @bucket)
  end

  it 'should add some credentials' do
    @aws_auth.add_credentials_to(@request)

    @request.header['Authorization'].should == "AWS 0PN5J17HBGZHT7JJ3X82:xXjDGYUmKxnwqr5KXNPGldn5LbA="
  end

  it 'should build the string to sign correctly' do
    string = @aws_auth.string_to_sign_from_request(@request)

    string.should == "GET\n\n\nTue, 27 Mar 2007 19:36:42 +0000\n/johnsmith/photos/puppy.jpg"
  end

end
