//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectionStrategy, Component, Input, TemplateRef, ViewChild } from '@angular/core';
import {
  IAutocompleterTemplateComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';
import { hrefFromPrincipal, typeFromHref } from 'core-app/shared/components/principal/principal-helper';

@Component({
  templateUrl: './user-autocompleter-template.component.html',
  styleUrls: ['./user-autocompleter-template.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UserAutocompleterTemplateComponent implements IAutocompleterTemplateComponent {
  @Input() public inviteUserToProject:string|undefined;
  @Input() public isOpenedInModal:boolean = false;
  @Input() public hoverCards:boolean = true;

  constructor(private readonly pathHelperService:PathHelperService) {}

  @ViewChild('optionTemplate') optionTemplate:TemplateRef<Element>;
  @ViewChild('footerTemplate') footerTemplate?:TemplateRef<Element>;

  public getHoverCardUrl(principal:PrincipalLike) {
    if (!this.hoverCards || !principal.id) { return ''; }

    const type = typeFromHref(hrefFromPrincipal(principal));
    if (!type || type !== 'user') {
      return '';
    }

    return this.pathHelperService.userHoverCardPath(principal.id);
  }
}
