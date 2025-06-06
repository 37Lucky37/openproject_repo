# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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

module WorkPackages
  module Types
    class PatternInput < Primer::Forms::BaseComponent
      delegate :name, to: :@input

      def initialize(input:, value:, suggestions:)
        super()
        @input = input
        @value = value
        @suggestions = suggestions
      end

      def suggestions_for_stimulus
        @suggestions_for_stimulus ||= @suggestions
          .transform_keys { |key| key.to_s.humanize }
          .to_json
      end

      def suggestions_list_component
        @suggestions_list_component ||= Primer::Alpha::ActionList.new(
          role: :list,
          "data-pattern-input-target": "suggestions"
        )
      end
    end
  end
end
