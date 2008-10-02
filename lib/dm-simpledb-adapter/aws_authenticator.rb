require 'md5'
require 'base64'
class AwsAuthenticator

  def initialize(access_key, secret_key, bucket)
    @access_key, @secret_key, @bucket = access_key, secret_key, bucket
  end

  def valid_for?(challenge_response)
    #probably not, because AWS never offers challenges
  end

  def can_handle?(request)
    true
  end

  def add_credentials_to(request)
    signed_string = signed_string_from_request(request)
    
    request.header['Authorization'] = "AWS #{@access_key}:#{signed_string}"
  end

  ## UTILITY METHODS

  def bucket_from_request(request)
    uri = Addressable::URI.parse(request.uri)
    if !request.header.has_key?('host') || request.header['Host'] == 's3.amazonaws.com'
      bucket = uri.path.split('/')[1]
    elsif request.header['Host'] =~ /\.s3\.amazonaws\.com$/
      bucket = request.header['Host'].gsub('.s3.amazonaws.com', '')
    else
      bucket = request.header['Host'].downcase
    end

    bucket || ''
  end

  def signed_string_from_request(request)
    sign(string_to_sign_from_request(request))
  end

  def string_to_sign_from_request(request)
    string_to_sign = ""
    string_to_sign << request.method.to_s.upcase + "\n"
    string_to_sign << request.header['Content-MD5'].to_s + "\n"
    string_to_sign << request.header['Content-Type'].to_s + "\n"
    string_to_sign << request.header['Date'].to_s + "\n"
    string_to_sign << amazon_canonicalized_headers(request)
    string_to_sign << amazon_canonicalized_resource(request)

    string_to_sign
  end

  def amazon_canonicalized_headers(request)
    header_keys = request.header.keys.select do |name|
      name.to_s =~ /^x-amz/i
    end.map { |k| k.to_s.downcase }.sort

    header_keys.map do |key|
      key + ":" + request.header[key].to_s + "\n"
    end.join
  end

  def amazon_canonicalized_resource(request)
    uri = Addressable::URI.parse(request.uri)
    bucket = bucket_from_request(request)
    res = ""
    res << "/#{bucket}" if bucket
    res << uri.path.gsub("/#{bucket}", '')
    if %w[acl location logging torrent].include?(uri.query)
      res << "?" + uri.query
    end

    res
  end

  def digest
    @digest ||= OpenSSL::Digest::Digest.new('sha1')
  end

  def sign(string)
    Base64.encode64(
      OpenSSL::HMAC.digest(digest, @secret_key, string)
    ).strip
  end

end


