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
      @redis = Redis.new
    end

    def perform
      notion_dates = notion.db_calendar_dates_with_title
      current_events = google.list_events
      r_keys = redis.keys('*')
      r_keys.each do |key|
        event_id = redis.get(key)
        google.delete_event({ 'id' => event_id }) unless current_events.map(&:summary).include?(key) &&
                                                         notion_dates.map { |date| date['summary'] }.include?(key)
      end
      notion_dates.each do |date|
        next if current_events.any? { |ev| ev.summary == date['summary'] }

        event = google.insert_event(date)
        redis.set(event.value!.summary, event.value!.id, ex: 62.minutes)
      end
    end
  end
end
