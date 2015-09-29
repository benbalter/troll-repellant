require 'sinatra'
require 'json'
require 'octokit'
require 'dotenv'
require 'logger'

class TrollRepellant < Sinatra::Base

  def client
    @client ||= Octokit::Client.new access_token: ENV["GITHUB_TOKEN"]
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def repo
    ENV["GITHUB_REPO"]
  end

  def comment_body
    @comment_body ||= begin
      gist = client.gist ENV["GITHUB_COMMENT_GIST_ID"]
      gist[:files].first[1][:content]
    end
  end

  def payload
    request.body.rewind
    JSON.parse(request.body.read)
  end

  def issue
    payload["issue"] || payload["pull_request"]
  end

  def signature_valid?
    return false unless request.body && request.env['HTTP_X_HUB_SIGNATURE']
    digest = OpenSSL::Digest.new('sha1')
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(digest, ENV['GITHUB_HOOK_SECRET'], request.body.read)
    Rack::Utils.secure_compare signature, request.env['HTTP_X_HUB_SIGNATURE']
  end

  def sender
    payload["sender"]["login"].downcase
  end

  def issue_number
    issue["number"]
  end

  def blacklist
    ENV["GITHUB_BLACKLIST"].split(",").map { |u| u.downcase }
  end

  def blacklisted?
    blacklist.include? sender
  end

  def comment_and_close
    client.add_comment repo, issue_number, comment_body
    client.close_issue repo, issue_number
    bail "Closing Issue ##{issue_number} opened by @#{sender}"
  end

  def bail(reason, status_code=200)
    logger.info reason
    halt status_code
  end

  before do
    Dotenv.load if settings.development?
    bail "Invalid siganture", 500 unless signature_valid?
  end

  post "/payload" do
    bail "Not an issue or pull request" unless issue
    bail "Not an `opened` action"       unless payload["action"] == "opened"
    bail "User is not blacklisted"      unless blacklisted?

    comment_and_close
  end
end
