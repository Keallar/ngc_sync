# frozen_string_literal: true

module NgcSync
  # Sync
  class Synchronization
    attr_reader :google, :notion

    def self.perform
      new.perform
    end

    def initialize
      @notion = NgcSync::Adapters::NotionClient.new
      @google = NgcSync::Adapters::GoogleClient.new
    end

    def perform
      @notion_dates = notion.db_calendar_dates_with_title
      @current_events = google.list_ngc_events
      delete_old_events
      create_new_events
    rescue Signet::AuthorizationError
      url = authorizer.get_authorization_url(base_url: config['oob_uri'])
      NgcSync.logger.error "Update creds on #{url}!!!"
    end

    private

    def delete_old_events
      @current_events.each do |ev|
        next if @notion_dates.any? { |date| date['summary'] == ev.summary }

        options = {
          'id' => ev.id
        }
        google.delete_event(options)
      end
    end

    def create_new_events
      @notion_dates.each do |date|
        ev = @current_events.find { |e| e.summary == date['summary'] }
        next google.update_event(date.merge('id' => ev.id)) if ev

        google.insert_event(date)
      end
    end
  end
end
