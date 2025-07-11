# frozen_string_literal: true

$LOAD_PATH.unshift(__dir__)

require 'httpx'
require 'yonder/version'

module Yonder
  class << self
    BASE_URL = "https://bsky.social"

    attr_accessor :access_token
    attr_accessor :refresh_token

    def create_record(user_did:, record:, collection: 'app.bsky.feed.post')
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
    end

    def http_client
      client = HTTPX.with(
        origin: BASE_URL,
        headers: api_headers,
        base_path: '/xrpc'
      ).plugin(:auth)

      return client if @access_token.nil?

      client.bearer_auth(@access_token)
    end

    def api_headers
      {
        "user-agent": @user_agent || "yonder v#{Yonder::VERSION}"
      }
    end
  end
end
