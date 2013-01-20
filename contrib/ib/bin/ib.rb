#!/usr/bin/env ruby -Ku

require 'net/http'
require 'digest/sha1'
require 'cgi'

require 'rubygems'
require 'json'

class IncuBoxSession
  ENTRY_HOST = 'incubox.lo'
  def initialize(login, api_public_token, api_secret_token)
    @login = login
    @api_public_token = api_public_token
    @api_secret_token = api_secret_token
    @debug = true
    # @debug = false
  end

  def start
    result = nil
    Net::HTTP.start(ENTRY_HOST, 80) do |http|
      response = http.post('/api/start', hash_to_param({ 'login' => @login, 'api_public_token' => @api_public_token }))
      dp response.body
      result = JSON.parse(response.body)
    end
    unless result['status'] == 0
      raise "Fail to start(#{result['status']}): #{result['message']}"
    end
    @session_token = result['response']['session_token']
    @signature = hexdigest(@session_token, @api_secret_token)
  end

  def get(method, params = {})
    call(:get, method, params)
  end
  def post(method, params = {})
    call(:post, method, params)
  end
  def put(method, params = {})
    call(:put, method, params)
  end
  def delete(method, params = {})
    call(:delete, method, params)
  end

  def call(verb, method, params = {})
    result = nil
    response = nil
    Net::HTTP.start(ENTRY_HOST, 80) do |http|
      params = params.merge 'login' => @login, 'signature' => @signature
      dp "method:#{method}, params:#{params.inspect}"
      if verb == :get
        response = http.send(verb, "/api/#{method}?#{hash_to_param(params)}")
      else
        response = http.send(verb, "/api/#{method}", hash_to_param(params))
      end
      result = JSON.parse(response.body)
    end
    unless result['status'] == 0
      raise "Fail to start(#{result['status']}): #{result['message']}"
    end
    response.body
    # result['response']
  end

  private
  def hexdigest(*strings)
    dig = Digest::SHA1.new
    strings.flatten!
    strings.each do |string|
      dig.update string
    end
    dig.hexdigest
  end
  def hash_to_param(hash)
    hash.map do |key, value|
      CGI.escape(key) + '=' + CGI.escape(value)
    end.join('&')
  end
  def dp(msg)
    puts msg if @debug
  end
end

session = IncuBoxSession.new('chsh',
                             "n15a2tejjsegunta9phnczkdzcyn85eba4i7i1ia",
                             "ZYU7^+!5ND4xdX$kXwUWH@g88n5^VCsz$6+yQ5Cu")
session.start

cmd = ARGV.shift
svs = ARGV.map { |arg| arg.split(/:/) }
hsvs = Hash[*svs.flatten]
puts session.get(cmd, hsvs).inspect

