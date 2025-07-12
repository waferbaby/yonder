# frozen_string_literal: true

$LOAD_PATH.unshift(__dir__)

require 'httpx'
require 'yonder/session'
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
    attr_accessor :session
    attr_accessor :user_agent

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
      post(
        endpoint: "/com.atproto.repo.createRecord",
        params: {
          repo: user_did,
          collection: collection,
          record: record
        }
      )
    end

    def create_session(username:, password:)
      response = post(
        endpoint: "/com.atproto.server.createSession",
        params: {
          identifier: username,
          password: password
        }
      )

      @session = Session.from_json(response)
      true
    end

    def refresh_session
      response = post(
        endpoint: "/com.atproto.server.refreshSession",
        access_token: @session&.refresh_token
      )

      @session = Session.from_json(response)
      true
    end

    def get(endpoint:)
      make_api_request(endpoint: endpoint, method: :get)
    end

    def post(endpoint:, params: {}, access_token: nil)
      make_api_request(endpoint: endpoint, method: :post, params: params, access_token: access_token)
    end

    private

    def make_api_request(endpoint:, method: :get, params: {}, access_token: nil)
      access_token ||= @session&.access_token

      client = http_client
      client = client.bearer_auth(access_token) unless access_token.nil?

      response = client.request(method, endpoint, json: params)

      response.raise_for_status
      response.json
    rescue HTTPX::TimeoutError, HTTPX::ResolveError => e
      raise Yonder::RequestError.new(e.message)
    rescue HTTPX::HTTPError => e
      klass = ERROR_MAPPING.dig(e.response.json['error']) || NetworkError
      raise klass.new(e.response.json['message'])
    end

    def http_client
      HTTPX.with(
        origin: @api_host || BASE_URL,
        headers: { "user-agent": @user_agent || "yonder v#{Yonder::VERSION}" },
        base_path: '/xrpc'
      ).plugin(:auth)
    end
  end
end
