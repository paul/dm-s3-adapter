
require 'resourceful'
require File.dirname(__FILE__) + '/../../lib/dm-simpledb-adapter/aws_authenticator'

describe AwsAuthenticator do

  before do
    @http = Resourceful::HttpAccessor.new

    # the keys from http://docs.amazonwebservices.com/AmazonS3/2006-03-01/
    @access_key = "0PN5J17HBGZHT7JJ3X82"
    @secret_key = "uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o"
    @bucket = "johnsmith"

    @aws_auth = AwsAuthenticator.new(@access_key,
                                     @secret_key,
                                     @bucket)
  end

  describe 'bucket figuring' do
    
    it 'should use the first part of the path if the Host header is ommitted' do
      @resource = @http.resource('http://s3.amazonaws.com/johnsmith.net/foo/bar')
      @request = Resourceful::Request.new(:get, 
                                          @resource,
                                          nil
                                         )
      bucket = @aws_auth.bucket_from_request(@request)
      bucket.should == 'johnsmith.net'
    end
    
    it 'should use the first part of the path if the Host header is exactly "s3.amazonaws.com"' do
      @resource = @http.resource('http://s3.amazonaws.com/johnsmith.net/foo/bar')
      @request = Resourceful::Request.new(:get, 
                                          @resource,
                                          nil,
                                          "Host" => 's3.amazonaws.com'
                                         )
      bucket = @aws_auth.bucket_from_request(@request)
      bucket.should == 'johnsmith.net'
    end

    it 'should have a bucket even it its the only thing in the path' do
      @resource = @http.resource('http://s3.amazonaws.com/johnsmith.net')
      @request = Resourceful::Request.new(:get, 
                                          @resource,
                                          nil
                                         )
      bucket = @aws_auth.bucket_from_request(@request)
      bucket.should == 'johnsmith.net'
    end

    it 'should use the first part of the host header if the header ends with ".s3.amazonaws.com"' do
      @resource = @http.resource('http://s3.amazonaws.com/foo/bar')
      @request = Resourceful::Request.new(:get, 
                                          @resource,
                                          nil,
                                          "Host" => 'johnsmith.net.s3.amazonaws.com'
                                         )
      bucket = @aws_auth.bucket_from_request(@request)
      bucket.should == 'johnsmith.net'
    end
    
    it 'should use the bucket specified in the host header' do
      @resource = @http.resource('http://s3.amazonaws.com/')
      @request = Resourceful::Request.new(:get, 
                                          @resource,
                                          nil,
                                          'Host' => 'johnsmith.net'
                                         )
      bucket = @aws_auth.bucket_from_request(@request)
      bucket.should == 'johnsmith.net'
    end

    it 'should have an empty string if no bucket was specified' do
      @resource = @http.resource('http://s3.amazonaws.com/')
      @request = Resourceful::Request.new(:get, 
                                          @resource,
                                          nil,
                                          'Host' => 's3.amazonaws.com'
                                         )
      bucket = @aws_auth.bucket_from_request(@request)
      bucket.should == ''
    end

  end

  # These are taken directly from Amazon's S3 Dev Guide: Rest API - Authenticating
  describe 'example object get' do
    before do
      @resource = @http.resource('http://johnsmith.s3.amazonaws.com/photos/puppy.jpg')
      @request = Resourceful::Request.new(:get, 
                                          @resource,
                                          nil,
                                          :date => "Tue, 27 Mar 2007 19:36:42 +0000"
                                         )
    end

    it 'should build the string to sign correctly' do
      string = @aws_auth.string_to_sign_from_request(@request)
      string.should == "GET\n\n\nTue, 27 Mar 2007 19:36:42 +0000\n/johnsmith/photos/puppy.jpg"
    end

    it 'should have the correct signed string' do
      signed_string = @aws_auth.signed_string_from_request(@request)
      signed_string.should == "xXjDGYUmKxnwqr5KXNPGldn5LbA="
    end

    it 'should have the correct Authorization header' do
      @aws_auth.add_credentials_to(@request)
      @request.header['Authorization'].should == "AWS 0PN5J17HBGZHT7JJ3X82:xXjDGYUmKxnwqr5KXNPGldn5LbA="
    end

  end

  describe 'example object put' do
    before do
      @resource = @http.resource('http://johnsmith.s3.amazonaws.com/photos/puppy.jpg')
      @request = Resourceful::Request.new(:put, 
                                          @resource,
                                          "A" * 94328,
                                          :date => "Tue, 27 Mar 2007 21:15:45 +0000",
                                          :content_type => 'image/jpeg'
                                         )
    end

    it 'should build the string to sign correctly' do
      string = @aws_auth.string_to_sign_from_request(@request)
      string.should == "PUT\n\nimage/jpeg\nTue, 27 Mar 2007 21:15:45 +0000\n/johnsmith/photos/puppy.jpg"
    end

    it 'should have the correct signed string' do
      signed_string = @aws_auth.signed_string_from_request(@request)
      signed_string.should == "hcicpDDvL9SsO6AkvxqmIWkmOuQ="
    end

    it 'should have the correct Authorization header' do
      @aws_auth.add_credentials_to(@request)
      @request.header['Authorization'].should == "AWS 0PN5J17HBGZHT7JJ3X82:hcicpDDvL9SsO6AkvxqmIWkmOuQ="
    end

  end

  describe 'example list' do
    before do
      @resource = @http.resource('http://johnsmith.s3.amazonaws.com/?prefix=photos&max-keys=50&marker=puppy')
      @request = Resourceful::Request.new(:get, 
                                          @resource,
                                          nil,
                                          :date => "Tue, 27 Mar 2007 19:42:41 +0000"
                                         )
    end

    it 'should build the string to sign correctly' do
      string = @aws_auth.string_to_sign_from_request(@request)
      string.should == "GET\n\n\nTue, 27 Mar 2007 19:42:41 +0000\n/johnsmith/"
    end

    it 'should have the correct signed string' do
      signed_string = @aws_auth.signed_string_from_request(@request)
      signed_string.should == "jsRt/rhG+Vtp88HrYL706QhE4w4="
    end

    it 'should have the correct Authorization header' do
      @aws_auth.add_credentials_to(@request)
      @request.header['Authorization'].should == "AWS 0PN5J17HBGZHT7JJ3X82:jsRt/rhG+Vtp88HrYL706QhE4w4="
    end

  end

  describe 'example fetch' do
    before do
      @resource = @http.resource('http://johnsmith.s3.amazonaws.com/?acl')
      @request = Resourceful::Request.new(:get, 
                                          @resource,
                                          nil,
                                          :date => "Tue, 27 Mar 2007 19:44:46 +0000"
                                         )
    end

    it 'should build the string to sign correctly' do
      string = @aws_auth.string_to_sign_from_request(@request)
      string.should == "GET\n\n\nTue, 27 Mar 2007 19:44:46 +0000\n/johnsmith/?acl"
    end

    it 'should have the correct signed string' do
      signed_string = @aws_auth.signed_string_from_request(@request)
      signed_string.should == "thdUi9VAkzhkniLj96JIrOPGi0g="
    end

    it 'should have the correct Authorization header' do
      @aws_auth.add_credentials_to(@request)
      @request.header['Authorization'].should == "AWS 0PN5J17HBGZHT7JJ3X82:thdUi9VAkzhkniLj96JIrOPGi0g="
    end

  end

  describe 'example delete (using path-style bucket and x-amz-date' do
    before do
      @resource = @http.resource('http://s3.amazonaws.com/johnsmith/photos/puppy.jpg')
      @request = Resourceful::Request.new(:delete, 
                                          @resource,
                                          nil,
                                          :'x-amz-date' => "Tue, 27 Mar 2007 21:20:26 +0000"
                                         )
    end

    it 'should build the string to sign correctly' do
      string = @aws_auth.string_to_sign_from_request(@request)
      string.should == "DELETE\n\n\n\nx-amz-date:Tue, 27 Mar 2007 21:20:26 +0000\n/johnsmith/photos/puppy.jpg"
    end

    it 'should have the correct signed string' do
      signed_string = @aws_auth.signed_string_from_request(@request)
      signed_string.should == "k3nL7gH3+PadhTEVn5Ip83xlYzk="
    end

    it 'should have the correct Authorization header' do
      @aws_auth.add_credentials_to(@request)
      @request.header['Authorization'].should == "AWS 0PN5J17HBGZHT7JJ3X82:k3nL7gH3+PadhTEVn5Ip83xlYzk="
    end

  end

  describe 'example upload (using CNAME-style vhost bucket with additional metadata' do
    before do
      @resource = @http.resource('http://static.johnsmith.net/db-backup.dat.gz')
      @request = Resourceful::Request.new(:put, 
                                          @resource,
                                          "A" * 5913339,
                                          "Date" => 'Tue, 27 Mar 2007 21:06:08 +0000',
                                          'x-amz-acl' => "public-read",
                                          'content_type' => 'application/x-download',
                                          'Content-MD5' => '4gJE4saaMU4BqNR0kLY+lw==',
                                          'X-Amz-Meta-ReviewedBy' => 'joe@johnsmith.net,jane@johnsmith.net',
                                          'X-Amz-Meta-FileChecksum' => '0x02661779',
                                          'X-Amz-Meta-ChecksumAlgorithm' => 'crc32',
                                          'Content-Disposition' => 'attachment; filename=database.dat',
                                          'Content-Encoding' => 'gzip'
                                         )
    end

    it 'should build the string to sign correctly' do
      pending "Virtual host not supported yet"
      string = @aws_auth.string_to_sign_from_request(@request)
      string.should == "PUT\n4gJE4saaMU4BqNR0kLY+lw==\napplication/x-download\nTue, 27 Mar 2007 21:06:08 +0000\nx-amz-acl:public-read\nx-amz-meta-checksumalgorithm:crc32\nx-amz-meta-filechecksum:0x02661779\nx-amz-meta-reviewedby:joe@johnsmith.net,jane@johnsmith.net\n/static.johnsmith.net/db-backup.dat.gz"
    end

    it 'should have the correct signed string' do
      pending
      signed_string = @aws_auth.signed_string_from_request(@request)
      signed_string.should == "k3nL7gH3+PadhTEVn5Ip83xlYzk="
    end

    it 'should have the correct Authorization header' do
      pending
      @aws_auth.add_credentials_to(@request)
      @request.header['Authorization'].should == "AWS 0PN5J17HBGZHT7JJ3X82:k3nL7gH3+PadhTEVn5Ip83xlYzk="
    end

  end

  describe 'example list all buckets' do
    before do
      @resource = @http.resource('http://s3.amazonaws.com/')
      @request = Resourceful::Request.new(:get,
                                          @resource,
                                          nil,
                                          'Date' => "Wed, 28 Mar 2007 01:29:59 +0000"
                                         )
    end

    it 'should build the string to sign correctly' do
      string = @aws_auth.string_to_sign_from_request(@request)
      string.should == "GET\n\n\nWed, 28 Mar 2007 01:29:59 +0000\n/"
    end

    it 'should have the correct signed string' do
      signed_string = @aws_auth.signed_string_from_request(@request)
      signed_string.should == "Db+gepJSUbZKwpx1FR0DLtEYoZA="
    end

    it 'should have the correct Authorization header' do
      @aws_auth.add_credentials_to(@request)
      @request.header['Authorization'].should == "AWS 0PN5J17HBGZHT7JJ3X82:Db+gepJSUbZKwpx1FR0DLtEYoZA="
    end

  end
end
