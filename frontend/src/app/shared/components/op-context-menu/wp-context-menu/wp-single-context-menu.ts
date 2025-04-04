import { AfterViewInit, Directive, ElementRef, Injector, Input, OnDestroy } from '@angular/core';
import { StateService } from '@uirouter/core';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HookService } from 'core-app/features/plugins/hook-service';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { PERMITTED_CONTEXT_MENU_ACTIONS } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-static-context-menu-actions';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import { WorkPackageAction } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { WpDestroyModalComponent } from 'core-app/shared/components/modals/wp-destroy-modal/wp-destroy.modal';
import { WorkPackageAuthorization } from 'core-app/features/work-packages/services/work-package-authorization.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

@Directive({
  selector: '[wpSingleContextMenu]',
})
export class WorkPackageSingleContextMenuDirective extends OpContextMenuTrigger implements AfterViewInit, OnDestroy {
  @Input('wpSingleContextMenu-workPackage') public workPackage:WorkPackageResource;

  constructor(
    readonly HookService:HookService,
    readonly $state:StateService,
    readonly injector:Injector,
    readonly PathHelper:PathHelperService,
    readonly elementRef:ElementRef,
    readonly opModalService:OpModalService,
    readonly turboRequests:TurboRequestsService,
    readonly apiV3Service:ApiV3Service,
    readonly opContextMenuService:OPContextMenuService,
    readonly authorisationService:AuthorisationService,
    protected copyToClipboardService:CopyToClipboardService,
  ) {
    super(elementRef, opContextMenuService);
  }

  private closeDialogHandler:EventListener = this.handleTimeEntryDialogClose.bind(this);

  ngAfterViewInit():void {
    super.ngAfterViewInit();
    document.addEventListener('dialog:close', this.closeDialogHandler);
  }

  ngOnDestroy():void {
    document.removeEventListener('dialog:close', this.closeDialogHandler);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.workPackage.project.$load().then(() => {
      this.authorisationService.initModelAuth('work_package', this.workPackage.$links);

      const authorization = new WorkPackageAuthorization(this.workPackage, this.PathHelper, this.$state);
      const permittedActions = this.getPermittedActions(authorization);

      this.buildItems(permittedActions);
      this.opContextMenu.show(this, evt);
    });
  }

  public triggerContextMenuAction(action:WorkPackageAction, key:string) {
    const { link } = action;

    switch (key) {
      case 'copy_to_other_project':
        window.location.href = `${this.PathHelper.staticBase}/work_packages/move/new?copy=true&ids[]=${this.workPackage.id as string}`;
        break;

      case 'copy':
        this.$state.go('work-packages.copy', { copiedFromWorkPackageId: this.workPackage.id });
        break;
      case 'delete':
        this.opModalService.show(WpDestroyModalComponent, this.injector, { workPackages: [this.workPackage] });
        break;
      case 'log_time':
        void this.turboRequests.request(this.PathHelper.timeEntryWorkPackageDialog(this.workPackage.id as string), { method: 'GET' });
        break;
      case 'generate_pdf':
        void this.turboRequests.requestStream(link as string);
        break;
      case 'copy_link_to_clipboard': {
        const url = new URL(String(link), window.location.origin);
        this.copyToClipboardService.copy(url.toString());
        break;
      }
      default:
        window.location.href = link!;
        break;
    }
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(evt:JQuery.TriggeredEvent) {
    const additionalPositionArgs = {
      my: 'right top',
      at: 'right bottom',
    };

    const position = super.positionArgs(evt);
    _.assign(position, additionalPositionArgs);

    return position;
  }

  private getPermittedActions(authorization:WorkPackageAuthorization) {
    const actions:WorkPackageAction[] = authorization.permittedActionsWithLinks(PERMITTED_CONTEXT_MENU_ACTIONS);

    // Splice plugin actions onto the core actions
    _.each(this.getPermittedPluginActions(authorization), (action:WorkPackageAction) => {
      const index = action.indexBy ? action.indexBy(actions) : actions.length;
      actions.splice(index, 0, action);
    });

    return actions;
  }

  private getPermittedPluginActions(authorization:WorkPackageAuthorization) {
    const actions:WorkPackageAction[] = this.HookService.call('workPackageSingleContextMenu');
    return authorization.permittedActionsWithLinks(actions);
  }

  protected buildItems(permittedActions:WorkPackageAction[]):OpContextMenuItem[] {
    const configureFormLink = this.workPackage.configureForm;

    this.items = permittedActions.map((action:WorkPackageAction) => {
      const { key } = action;
      return {
        disabled: false,
        linkText: I18n.t(`js.button_${key}`),
        href: action.link,
        icon: action.icon || `icon-${key}`,
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (action.link && isClickedWithModifier($event)) {
            return false;
          }

          this.triggerContextMenuAction(action, key);
          return true;
        },
      };
    });

    if (configureFormLink) {
      this.items.push(
        {
          href: configureFormLink.href,
          icon: 'icon-settings3',
          linkText: I18n.t('js.button_configure-form'),
          onClick: () => false,
        },
      );
    }

    return this.items;
  }

  private handleTimeEntryDialogClose(event:CustomEvent):void {
    const { detail: { dialog, submitted } } = event as { detail:{ dialog:HTMLDialogElement, submitted:boolean } };

    if (dialog.id === 'time-entry-dialog' && submitted) {
      void this.apiV3Service
        .work_packages
        .id(this.workPackage.id!)
        .refresh();
    }
  }
}
