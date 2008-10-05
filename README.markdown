
= DM-S3-Adapter

This is (or will be) a DataMapper Adapter for use with Amazon's Simple Storage Service (S3).

What works: 

 * Authenticating (most) requests
 * Saving a model
 * Getting a single model

 Example:

    DataMapper.setup(:default, :adapter => 's3'
                               :aws_access_key => YOUR_KEY,
                               :aws_secret_key => YOUR_SECRET_KEY,
                               :aws_bucket     => 'dm-s3-bucket')

    class Article 
      include DataMapper::Resource

      property :id, UUID, :key => true, :default => lambda { ::UUID.random_create }
      property :title, String
      property :text,  Text
    end

    a = Article.new(:title => "test", :text => "test")
    a.save

    a = Article.get(a.id)


