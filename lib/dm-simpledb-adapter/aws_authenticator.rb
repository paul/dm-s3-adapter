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
    string_to_sign = string_to_sign_from_request(request)
    
    request.header['Authorization'] = "AWS #{@access_key}:#{sign(string_to_sign)}"
  end

  def string_to_sign_from_request(request)
    string_to_sign = ""
    string_to_sign << request.method.to_s.upcase + "\n"
    string_to_sign << request.header['Content-MD5'].to_s + "\n"
    string_to_sign << request.header['Content-Type'].to_s + "\n"
    string_to_sign << request.header['Date'].to_s + "\n"
    # + AmzHeaders
    string_to_sign << "/#{@bucket}#{Addressable::URI.parse(request.uri).path}"

    string_to_sign
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


