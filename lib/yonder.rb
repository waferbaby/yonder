# frozen_string_literal: true

$LOAD_PATH.unshift(__dir__)

require 'httpx'
require 'yonder/version'
require 'yonder/errors'

module Yonder
  class << self
    BASE_URL = "https://bsky.social"
    COLLECTION_POST = 'app.bsky.feed.post'
    ERROR_MAPPING = {
      'AuthMissing' => AuthenticationError,
      'ExpiredToken' => TokenExpiredError,
      'InvalidToken' => TokenInvalidError
    }

    attr_accessor :api_host
    attr_accessor :access_token
    attr_accessor :refresh_token

    def create_post(user_did:, message:)
      create_record(
        user_did: user_did,
        record: {
          text: message,
          createdAt: Time.now.iso8601
        },
        collection: COLLECTION_POST
      )
    end

    def create_record(user_did:, record:, collection:)
      post("/com.atproto.repo.createRecord", params: {
        repo: user_did,
        collection: collection,
        record: record
      })
    end

    def create_session(username:, password:)
      post("/com.atproto.server.createSession", params: {
        identifier: username,
        password: password
      })
    end

    def renew_session(renewal_token)
      post("/com.atproto.server.refreshSession")
    end

    def get(endpoint)
      make_api_request(endpoint, method: :get)
    end

    def post(endpoint, params: {})
      make_api_request(endpoint, method: :post, params: params)
    end

    private

    def make_api_request(endpoint, method: :get, params: {})
      response = http_client.request(method, endpoint, json: params)

      response.raise_for_status
      response.json
    rescue HTTPX::TimeoutError, HTTPX::ResolveError => e
      raise Yonder::RequestError.new(e.message)
    rescue HTTPX::HTTPError => e
      klass = ERROR_MAPPING.dig(e.response.json['error']) || NetworkError
      raise klass.new(e.response.json['message'])
    end

    def http_client
      client = HTTPX.with(
        origin: @api_host || BASE_URL,
        headers: { "user-agent": @user_agent || "yonder v#{Yonder::VERSION}" },
        base_path: '/xrpc'
      ).plugin(:auth)

      return client if @access_token.nil?

      client.bearer_auth(@access_token)
    end
  end
end
