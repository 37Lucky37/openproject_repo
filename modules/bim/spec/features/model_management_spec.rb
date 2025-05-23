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

require_relative "../support/pages/ifc_models/index"

RSpec.describe "model management", :js, :selenium, with_config: { edition: "bim" } do
  let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }
  let(:index_page) { Pages::IfcModels::Index.new(project) }
  let(:role) { create(:project_role, permissions: %i[view_ifc_models manage_bcf manage_ifc_models view_work_packages]) }

  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  let!(:model) do
    create(:ifc_model_minimal_converted,
           project:,
           uploader: user,
           is_default: true)
  end

  let!(:model2) do
    create(:ifc_model_minimal_converted,
           project:,
           uploader: user)
  end

  context "with all permissions" do
    before do
      login_as(user)
      model
      model2
      index_page.visit!
    end

    it "I can perform all actions on the models" do
      index_page.model_listed true, model.title
      index_page.add_model_allowed true
      index_page.edit_model_allowed model.title, true
      index_page.delete_model_allowed model.title, true

      index_page.edit_model model.title, "My super cool new name"
      index_page.delete_model "My super cool new name"
    end

    it "I can see single models and the defaults" do
      index_page.model_listed true, model.title
      index_page.show_model model
      index_page.bcf_buttons true

      index_page.visit!
      index_page.model_listed true, model.title
      index_page.show_defaults([model, model2])
      index_page.bcf_buttons true
    end
  end

  context "with only viewing permissions" do
    let(:view_role) { create(:project_role, permissions: %i[view_ifc_models view_work_packages]) }
    let(:view_user) do
      create(:user,
             member_with_roles: { project => view_role })
    end

    before do
      login_as(view_user)
      model
      model2
      index_page.visit!
    end

    it "I can see, but not edit models" do
      index_page.model_listed true, model.title
      index_page.add_model_allowed false
      index_page.edit_model_allowed model.title, false
      index_page.delete_model_allowed model.title, false
    end

    it "I can see single models and the defaults" do
      index_page.model_listed true, model.title
      index_page.show_model model

      index_page.visit!
      index_page.bcf_buttons false
      index_page.model_listed true, model.title
      index_page.show_defaults([model, model2])
    end
  end

  context "without any permissions" do
    let(:no_permissions_role) { create(:project_role, permissions: %i[]) }
    let(:user_without_permissions) do
      create(:user,
             member_with_roles: { project => no_permissions_role })
    end

    before do
      login_as(user_without_permissions)
      model
      index_page.visit!
    end

    it "I can't see any models and perform no actions" do
      expected = "[Error 403] You are not authorized to access this page."
      expect_flash(type: :error, message: expected)

      index_page.add_model_allowed false
    end
  end
end
