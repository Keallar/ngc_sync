# frozen_string_literal: true

module NgcSync
  # Sync
  class Synchronization
    attr_reader :google, :notion, :redis

    def self.perform
      new.perform
    end

    def initialize
      @notion = NgcSync::Adapters::NotionClient.new
      @google = NgcSync::Adapters::GoogleClient.new
    end

    def perform
      delete_old_events
      create_new_events
    end

    private

    def delete_old_events
      notion_dates = notion.db_calendar_dates_with_title
      current_events = google.list_ngc_events
      current_events.each do |ev|
        next if notion_dates.any? { |date| date['summary'] == ev.summary }

        options = {
          'id' => ev.id
        }
        google.delete_event(options)
      end
    end

    def create_new_events
      notion_dates = notion.db_calendar_dates_with_title
      current_events = google.list_ngc_events
      notion_dates.each do |date|
        next if current_events.any? { |ev| ev.summary == date['summary'] }

        google.insert_event(date)
      end
    end
  end
end
