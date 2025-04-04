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

module Meetings
  class HeaderComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include Primer::FetchOrFallbackHelper
    include Redmine::I18n

    STATE_DEFAULT = :show
    STATE_EDIT = :edit
    STATE_OPTIONS = [STATE_DEFAULT, STATE_EDIT].freeze

    def initialize(meeting:, state: STATE_DEFAULT)
      super

      @meeting = meeting
      @series = meeting.recurring_meeting
      @project = meeting.project
      @state = fetch_or_fallback(STATE_OPTIONS, state)
    end

    # Define the interval so it can be overriden through tests
    def check_for_updates_interval
      10_000
    end

    def ics_download_path
      if @series
        download_ics_project_recurring_meeting_path(@series.project, @series, occurrence_id: @meeting.id)
      else
        download_ics_project_meeting_path(@meeting.project, @meeting)
      end
    end

    private

    def delete_enabled?
      !@meeting.template? && User.current.allowed_in_project?(:delete_meetings, @meeting.project)
    end

    def finish_setup_enabled?
      @meeting.template? &&
        User.current.allowed_in_project?(:create_meetings, @meeting.project) &&
        @series.scheduled_meetings.none?
    end

    def breadcrumb_items
      [
        parent_element,
        { href: @project.present? ? project_meetings_path(@project.id) : meetings_path,
          text: I18n.t(:label_meeting_plural) },
        meeting_series_element,
        meeting_element
      ].compact
    end

    def meeting_element
      if @meeting.templated?
        I18n.t(:label_template)
      elsif @series.present?
        format_date(@meeting.start_time)
      else
        @meeting.title
      end
    end

    def meeting_series_element
      if @series.present?
        { href: project_recurring_meeting_path(@series.project, @series), text: @series.title }
      end
    end

    def parent_element
      if @project.present?
        { href: project_overview_path(@project.id), text: @project.name }
      else
        { href: home_path, text: helpers.organization_name }
      end
    end

    def delete_label
      if @series.present?
        I18n.t("label_recurring_meeting_cancel")
      else
        I18n.t("label_meeting_delete")
      end
    end

    def copy_label
      if @series.present?
        I18n.t("label_recurring_meeting_copy")
      else
        I18n.t("button_copy")
      end
    end
  end
end
