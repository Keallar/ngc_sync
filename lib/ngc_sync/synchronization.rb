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
      notion_dates = notion.db_calendar_dates_with_title
      notion_dates.each { |date| google.insert_event(date) }
    end
  end
end
