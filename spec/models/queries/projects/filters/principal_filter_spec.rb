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

RSpec.describe Queries::Projects::Filters::PrincipalFilter do
  let(:group1) { build_stubbed(:group) }
  let(:group2) { build_stubbed(:group) }
  let(:user1) { build_stubbed(:user) }
  let(:user2) { build_stubbed(:user) }

  before do
    allow(Principal)
      .to receive(:pluck)
      .with(:id)
      .and_return([group1.id,
                   group2.id,
                   user1.id,
                   user2.id])
  end

  it_behaves_like "basic query filter" do
    let(:class_key) { :principal }
    let(:type) { :list_optional }
    let(:name) { Principal.model_name.human }

    describe "#allowed_values" do
      it "is a list of the possible values" do
        expected = [[group1.id, group1.id.to_s],
                    [group2.id, group2.id.to_s],
                    [user1.id, user1.id.to_s],
                    [user2.id, user2.id.to_s]]

        expect(instance.allowed_values).to match_array(expected)
      end
    end
  end
end
