#!/usr/bin/ruby

require 'rubygems'
require 'resourceful'
require 'dm-core'
require 'dm-types'

require 'lib/dm-simpledb-adapter'

DataMapper.setup(:default, :adapter => 'simpledb',
                           :aws_access_key => '1A5GTKXEHKEDBM7E5K82',
                           :aws_secret_key => 'ZHSoQ74FdkM/FS1w1+gfRbAYorYo/vshDetjQmY3',
                           :aws_domain     => 'DataMapperAdapterTest')

class Person
  include DataMapper::Resource

  property :id,       UUID,   :key => true
  property :name,     String
end

p = Person.new(:name => 'Paul')
p.save

puts p.inspect
