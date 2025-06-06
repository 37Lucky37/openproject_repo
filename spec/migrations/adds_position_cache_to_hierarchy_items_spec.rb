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

require "spec_helper"
require Rails.root.join("db/migrate/20250102161733_adds_position_cache_to_hierarchy_items.rb")

RSpec.describe AddsPositionCacheToHierarchyItems, type: :model do
  let(:custom_field) { create(:hierarchy_wp_custom_field, hierarchy_root: nil) }
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }

  it "backfills the position_cache value on already existing hierarchy items" do
    ActiveRecord::Migration.suppress_messages { described_class.new.down }

    root = service.generate_root(custom_field).value!
    anakin = service.insert_item(label: "luke", parent: root).value!
    chewie = service.insert_item(label: "chewbacca", parent: root).value!
    luke = service.insert_item(label: "luke", parent: anakin).value!
    leia = service.insert_item(label: "leia", parent: anakin).value!

    expect(root.self_and_descendants_preordered).to eq([root, anakin, luke, leia, chewie])

    ActiveRecord::Migration.suppress_messages { described_class.new.up }

    expect(root.reload.position_cache).to eq(125)
    expect(anakin.reload.position_cache).to eq(150)
    expect(luke.reload.position_cache).to eq(155)
    expect(leia.reload.position_cache).to eq(160)
    expect(chewie.reload.position_cache).to eq(175)
  end
end
