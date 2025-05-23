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
module Projects
  class LifeCycleTypeComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def text
      model.model_name.human
    end

    def icon
      case model
      when Project::StageDefinition
        :"git-commit"
      when Project::GateDefinition
        :diamond
      else
        raise NotImplementedError, "Unknown model #{model.class} to render a LifeCycleTypeComponent with"
      end
    end

    def icon_color_class
      helpers.hl_inline_class("life_cycle_step_definition", model)
    end

    def text_options
      # The tag: :div is is a hack to fix the line height difference
      # caused by font_size: :small. That line height difference
      # would otherwise lead to the text being not on the same height as the icon
      { color: :muted, font_size: :small, tag: :div }.merge(options)
    end
  end
end
