# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

module RecurringMeetings
  class ShowPageHeaderComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include ApplicationHelper

    def initialize(meeting: nil)
      super

      @meeting = meeting
      @project = meeting.project
    end

    def render_create_button?
      if @project
        User.current.allowed_in_project?(:create_meetings, @project)
      else
        User.current.allowed_in_any_project?(:create_meetings)
      end
    end

    def dynamic_path
      polymorphic_path([:new, @project, :recurring_meeting])
    end

    def id
      "add-recurring-meeting-button"
    end

    def accessibility_label_text
      I18n.t(:label_recurring_meeting_new)
    end

    def label_text
      I18n.t(:label_recurring_meeting)
    end

    def page_title(breadcrumb = nil)
      @meeting.present? ? meeting_series_title(breadcrumb).to_s : I18n.t(:label_recurring_meeting_plural)
    end

    def meeting_series_title(breadcrumb)
      concat @meeting.title
      if breadcrumb
        concat render(Primer::Beta::Text.new) { " (#{I18n.t(:label_meeting_series)})" }
      else
        concat render(Primer::Beta::Text.new(color: :muted)) { " (#{I18n.t(:label_meeting_series)})" }
      end
    end

    def page_description
      @meeting.full_schedule_in_words
    end

    def breadcrumb_items
      [parent_element,
       { href: @project.present? ? project_meetings_path(@project.id) : meetings_path,
         text: I18n.t(:label_meeting_plural) },
       page_title(true)]
    end

    def parent_element
      if @project.present?
        { href: project_overview_path(@project.id), text: @project.name }
      else
        { href: home_path, text: I18n.t(:label_home) }
      end
    end
  end
end
