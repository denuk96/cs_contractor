require "active_record/fixtures"

fixtures_dir = Rails.root.join("spec/fixtures/inferno_2018")
ActiveRecord::FixtureSet.create_fixtures(fixtures_dir, "skin_items")
