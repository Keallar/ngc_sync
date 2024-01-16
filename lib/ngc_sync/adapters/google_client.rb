# frozen_string_literal: true

module NgcSync
  module Adapters
    # Adapter for google-api-client
    class GoogleClient
      Calendar = Google::Apis::CalendarV3 # Alias the module

      attr_reader :service, :config

      def initialize
        @config = CONFIG['google']
        @service = init_client
        @calendar_id = config['calendar_id']
      end

      # List of google calendar events filtered by Ngc (app) mark in description field
      def list_ngc_events(options = {})
        @list_ngc_events ||= list_events(options).select { |ev| ev&.description&.include?(EVENT_MARK) }
      end

      def list_events(options = {})
        @list_events ||= service.list_events(@calendar_id, **options).items
      end

      def insert_event(options)
        event = build_event(options)
        resp = service.insert_event(@calendar_id, event, send_notifications: true)
        NgcSync.logger.info "Created event '#{resp.summary}' (#{resp.id}) #{resp.html_link}"
      rescue Google::Apis::ClientError, Google::Apis::ServerError => e
        NgcSync.logger.error "Error while inserting event #{event.inspect} with options: #{options}"
        NgcSync.logger.error e.message
        NgcSync.logger.error e.backtrace&.join("\n")
      end

      def update_event(options)
        event = build_event(options)
        event_id = options['id']
        resp = service.update_event(@calendar_id, event_id, event)
        NgcSync.logger.info "Updated event '#{resp.summary}' (#{resp.id}) #{resp.html_link}"
      rescue Google::Apis::ClientError, Google::Apis::ServerError => e
        NgcSync.logger.error "Error while updating event #{event.inspect} with options: #{options}"
        NgcSync.logger.error e.message
        NgcSync.logger.error e.backtrace&.join("\n")
      end

      def delete_event(options)
        service.delete_event(@calendar_id, options['id'])
      rescue Google::Apis::ClientError, Google::Apis::ServerError => e
        NgcSync.logger.error "Error while deleting event with id #{options['id']}"
        NgcSync.logger.error e.message
        NgcSync.logger.error e.backtrace&.join("\n")
      end

      private

      def build_event(options)
        start = DateTime.parse(options['start'])
        event_hash = {
          summary: options['summary'],
          attendees: config['attendee'].map { |at| Calendar::EventAttendee.new(email: at) },
          description: EVENT_MARK,
          start: Calendar::EventDateTime.new(
            date_time: DateTime.parse(options['start'])
          ),
          end: Calendar::EventDateTime.new(
            date_time: options['end'].nil? ? start + (1.0 / 24.0) : DateTime.parse(options['end'])
          )
        }
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
          url = authorizer.get_authorization_url(base_url: config['oob_uri'])
          begin
            result = authorizer.get_and_store_credentials_from_code(user_id: 'default',
                                                                    code: GOOGLE_USER_ID,
                                                                    base_url: config['oob_uri'])
          rescue Signet::AuthorizationError
            NgcSync.logger.error "Update creds on #{url}!!!"
          end
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
        Google::Auth::Stores::FileTokenStore.new(file: 'credentials.json')
      end
    end
  end
end
