# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "support/flash/expectations"

module Components
  class CostReportsBaseTable
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers
    include Flash::Expectations
    include Redmine::I18n

    attr_reader :time_logging_modal

    def initialize
      @time_logging_modal = Components::TimeLoggingModal.new
    end

    def rows_count(count)
      expect(page).to have_css("#result-table tbody tr", count:)
    end

    def expect_action_icon(icon, row, present: true)
      if present
        expect(page).to have_css("#{row_selector(row)} .icon-#{icon}")
      else
        expect(page).to have_no_css("#{row_selector(row)} .icon-#{icon}")
      end
    end

    def expect_value(value, row)
      expect(page).to have_css("#{row_selector(row)} .units", text: value)
    end

    def expect_cell_text(value, row, column)
      expect(page).to have_css(cell_selector(row, column), text: value)
    end

    def expect_sort_header_column(text, present: true)
      if present
        expect(page).to have_css("#result-table .generic-table--sort-header", text:)
      else
        expect(page).to have_no_css("#result-table .generic-table--sort-header", text:)
      end
    end

    def edit_time_entry(row, hours:)
      SeleniumHubWaiter.wait
      page.find("#{row_selector(row)} .icon-edit").click

      time_logging_modal.is_visible true
      time_logging_modal.change_hours(hours)
      time_logging_modal.activity_input_disabled_because_work_package_missing? false

      time_logging_modal.submit

      if using_cuprite?
        wait_for_reload
      else
        sleep 1
      end

      expect_action_icon "edit", row
      expect_value l_hours(hours), row
    end

    def edit_cost_entry(new_value, row, cost_entry_id)
      SeleniumHubWaiter.wait
      page.find("#{row_selector(row)} .icon-edit").click

      expect(page).to have_current_path("/cost_entries/#{cost_entry_id}/edit")

      SeleniumHubWaiter.wait
      fill_in("cost_entry_units", with: new_value)
      click_button "Save"
      expect_flash(message: "Successful update.")
    end

    def delete_entry(row)
      SeleniumHubWaiter.wait

      if using_cuprite?
        accept_confirm { page.find("#{row_selector(row)} .icon-delete").click }
      else
        page.find("#{row_selector(row)} .icon-delete").click
        page.driver.browser.switch_to.alert.accept
      end
    end

    private

    def row_selector(row)
      "#result-table tbody tr:nth-of-type(#{row})"
    end

    def cell_selector(row, column)
      "#{row_selector(row)} td:nth-of-type(#{column})"
    end
  end
end
