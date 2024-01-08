# frozen_string_literal: true

module NgcSync
  module Adapters
    # Adapter for google-api-client
    class GoogleClient
      # include Dry::Monads[:result]

      Calendar = Google::Apis::CalendarV3 # Alias the module
      OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

      attr_reader :service, :config

      def initialize
        @config = CONFIG['google']
        @service = init_client
      end

      def insert_event(options)
        event = build_event(options)
        resp = service.insert_event(config['calendar_id'], event, send_notifications: true)
        NgcSync.logger.info "Created event '#{resp.summary}' (#{resp.id}) #{resp.html_link}"
      rescue Google::Apis::ClientError, Google::Apis::ServerError => e
        NgcSync.logger.error 'Error while inserting event...'
        NgcSync.logger.error e.message
        NgcSync.logger.error e.backtrace&.join("\n")
      end

      private

      def build_event(options)
        puts "options: #{options}"
        event_hash = {
          summary: options['summary'],
          attendees: config['attendee'].map { |at| Calendar::EventAttendee.new(email: at) },
          start: Calendar::EventDateTime.new(
            date_time: DateTime.parse(options['start'])
          )
        }
        unless options['end'].nil?
          event_hash[:end] = Calendar::EventDateTime.new(
            date_time: DateTime.parse(options['end'])
          )
        end
        puts "event_hash: #{event_hash}"
        Calendar::Event.new(**event_hash)
      end

      def init_client
        Google::Apis::ClientOptions.default.application_name = 'NGCSync'
        Google::Apis::ClientOptions.default.application_version = NgcSync::VERSION
        Google::Apis::RequestOptions.default.retries = 3
        NgcSync.logger.info 'Start google authorization...'
        calendar_api = Calendar::CalendarService.new
        calendar_api.authorization = creds
        NgcSync.logger.info 'Completed google authorization!'
        calendar_api
      end

      def creds
        result = authorizer.get_credentials('default')
        if result.nil?
          url = authorizer.get_authorization_url(base_url: OOB_URI)
          result = authorizer.get_and_store_credentials_from_code(user_id: 'default',
                                                                  code: GOOGLE_USER_ID, base_url: OOB_URI)
          return NgcSync.logger.error "Update creds on #{url}!!!" unless result
        end
        result
      end

      def authorizer
        Google::Auth::UserAuthorizer.new(client_id, Calendar::AUTH_CALENDAR, token_store)
      end

      def client_id
        Google::Auth::ClientId.new(GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET)
      end

      def token_store
        # Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new)
        Google::Auth::Stores::FileTokenStore.new(file: 'credentials.json')
      end
    end
  end
end
