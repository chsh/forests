require "spec_helper"

describe RandomString do

  it' should create random string within specified groups.' do
    RandomString.generate('a', :length => 5).should == 'aaaaa'
    RandomString::ASCII.include?(RandomString.generate(:ascii, :length => 1)).should == true
    ascii_large = ('A'..'Z').to_a - ['O', 'I']
    RandomString.generate(:ascii_large).should =~ /^[#{ascii_large.join('')}]{40}$/
    ascii_small = ('a'..'z').to_a - ['o', 'l']
    ascii = ascii_large + ascii_small
    RandomString.generate(:ascii, :length => '25').should =~ /^[#{ascii.join('')}]{25}$/
    numbers = ('1'..'9').to_a
    RandomString.generate(:numbers, :length => 10).should =~ /^[#{numbers.join('')}]{10}$/
    RandomString.generate(:number, :length => 100).should =~ /^[#{numbers.join('')}]{100}$/
    RandomString.generate(:number, :ascii_small, :length => 30).should =~ /^[#{numbers.join('') + ascii_small.join('')}]{30}$/
    symbols = '!#$%*+-./<=>@^_'
    RandomString.generate(:symbols, :length => 15).should =~ /^[#{symbols}]{15}$/
  end

  it 'should return character set' do
    ascii_large = ('A'..'Z').to_a - ['O', 'I']
    ascii_small = ('a'..'z').to_a - ['o', 'l']
    ascii = ascii_large + ascii_small
    numbers = ('1'..'9').to_a
    symbols = '!#$%*+-./<=>@^_'.split(//)
    RandomString.character_set(:ascii).should == ascii
    RandomString.character_set(:ascii, :numbers).should == (ascii + numbers).flatten.sort.uniq
    RandomString.character_set(:ascii_large, :symbols).should == (ascii_large + symbols).flatten.sort.uniq
  end

end
