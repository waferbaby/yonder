module Yonder
  class Session
    attr_accessor :user_did
    attr_accessor :access_token
    attr_accessor :refresh_token

    def self.from_json(payload)
      Session.new(
        user_did: payload["did"],
        access_token: payload["accessJwt"],
        refresh_token: payload["refreshJwt"]
      )
    end

    def initialize(user_did:, access_token:, refresh_token:)
      @user_did = user_did
      @access_token = access_token
      @refresh_token = refresh_token
    end
  end
end
