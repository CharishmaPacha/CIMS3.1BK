/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/10/21  RIA     Added button for consolidate/scan each (BK-644)
  2021/08/27  TK      Do not validate scanned entity in JS as user may substitue different LPN to pick (BK-540)
  2021/02/17  TK      Changes to display 'DisplayToPickQty' and Cases to Pick (BK-213)
  2021/02/03  RIA     Added amf-nowrap class (BK-140)
  2020/10/16  RIA     Defined size/width for number input control (HA-1590)
  2020/09/27  AY/RIA  Show SKU image (CIMSV3-733)
  2020/05/19  RIA     Show LPN/Pallet and also show PickTo value as placeholder (HA-556)
  2020/05/15  RIA     Changes to show Warehouse in appropriate size along with last 5digits of picktolpn (HA-556)
  2020/05/15  TK      Display LPN in Pick List (HA-543)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/08/29  RIA     Changes to show Stop/Pause (OB2-940)
  2019/08/23  AY      Display LPN for Picking from Reserve/Bulk (OB2-Support)
  2019/08/21  RIA     Changes to consider the responsive design (OB2-916)
  2019/08/06  RIA     Closed the tag correctly to show form as per the design (CIMSV3-606)
  2019/07/26  NB      Changes to hide keyboard and enforce scanner only inputs (AMF-62)
  2019/06/17  SV      Included validation for the input CoO (CID-548)
  2019/06/09  AY      Changed validation for NumPicked to be less than or equal (CID-455)
  2019/06/07  SV      Made changes to confirm picking if there is a case sensitivity with scanned entity (CID-419)
  2019/05/30  RV/NB   Made changes to focus on to ToLPN instead of quantity after scan SKU (CID-495)
              AY      Change to show Pick UoM, User in info panel & remove Total Qty as that is in the grid already
  2019/05/30  RIA     Change to display LPN under Pick from (CID-453)
  2019/05/23  AY      Change DefaultPickToLPN to not show unless required (CID-421)
  2019/05/22  AY      Changed to Show PickZone under the Location (CID-408)
  2019/05/22  SV      Changes to show CoO as per the value of IsCoORequired (CID-135)
  2019/05/08  SPK/OK  Added UPC (CID-332)
  2019/04/22  --      Sync with RF3.0.1 - Removal of Semi-colon for Pick to caption (CID-284)
  2019/04/17  NB      Added data-rfsubmitform="true" for PickTo to auto submit form(CID-274)
  2019/04/10  NB      set tab index for picked units of tablet version (CID-263)
  2019/01/08  NB      changes for addressing renaming of tables for AMF and naming conventions (AMF-26)
  2018/11/06  NB      Initial Revision(CIMSV3-331)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'BatchPicking_ConfirmUnitPick';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Confirm Unit Pick', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Confirm Task Pick</span>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-menu-open"><i class="amfi-menu"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-operation-info-open"><i class="amfi-info"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfsubmitpreprocess="Picking_ConfirmUnitPick_ProcessInputs"  data-rfshowpreprocess="Picking_ConfirmUnitPick_OnShow">
  <div class="container">
    <input type="hidden" data-rfname="Operation"value="CustomerOrderPicking" />
    <input type="hidden" data-rfname="ShortPick" value="N" />
    <input type="hidden" data-rfname="SelectedPickMode" value="[FIELDVALUE_BATCHPICKINFOPickMode]">
    <div class="amf-form-menu">
      <a class="amf-form-menu-close" >&times;</a>
      <button type="button" class="btn btn-info" data-rfclickhandler="Picking_ConfirmUnitPick_ShortPick">Short Pick</button>
      <button type="button" class="btn btn-info js-confirmpick-selectpickmode" id="CurrentPickMode" data-rfclickhandler="Picking_ConfirmUnitPick_ScanEachOrConsolidate"
      data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_BATCHPICKINFOPickMode]">PickMode: Individual Pick</button>
    </div>
    <div class="amf-form-operation-info">
      <a  class="amf-form-operation-info-close">&times;</a>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_WaveNo]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOBatchNo]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_AMFPalletOrCart]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOPickToPallet]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_TaskId]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOTaskId]</span>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_PickTicket]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOPickTicket]</span>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_NumOrders]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOTaskNumOrders]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_TempLabel]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOTempLabel]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_User]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_BATCHPICKINFOUserNameDisplay]</span>
          </div>
        </div>
      </div>
    </div>
    <div class="amf-form-layout-container">
      <div class="row">
        <div class="col-md-6 col-xs-12">
          <div class="amf-data-layout-container amf-form-padding-responsive">
            <div class="row">
              <div class="form-group">
                <div class="col-md-9 col-xs-9 amf-data-layout-responsive" style="border-right:1px solid #ccc;">
                  <label class="col-form-label">[FIELDCAPTION_AMFPickFrom]</label>
                  <span class="amf-display-value-largebold">[FIELDVALUE_BATCHPICKINFOPickFromDisplay]</span>
                  <span class="amf-display-value-small">Zone [FIELDVALUE_BATCHPICKINFOPickZoneDesc]</span>
                  <span class="amf-display-value-medium" style="color:#b41700"
                  data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_BATCHPICKINFOLocationType]"
                  data-rfvisiblecomparewith="R,B">[FIELDVALUE_BATCHPICKINFODisplayLPN]</span>
                </div>
                <div class="col-md-3 col-xs-3 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCAPTION_AMFToPick]</label>
                  <span class="amf-display-value-extralargebold" style="color:#b41700" data-rfjsname="ToPickQty">[FIELDVALUE_BATCHPICKINFODisplayToPickQty]</span>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="form-group">
                <div class="col-md-6 col-xs-6 amf-data-layout-responsive">
                  <span class="amf-display-value-medium">[FIELDVALUE_BATCHPICKINFODisplaySKU]</span>
                  <span class="amf-display-value-small">[FIELDVALUE_BATCHPICKINFODisplaySKUDesc]</span>
                  <span class="amf-display-value-small">[FIELDVALUE_BATCHPICKINFODisplaySKUDesc2]</span>
                </div>
                <div class="col-md-3 col-xs-3 amf-data-layout-responsive" style="border-right:1px solid #ccc;">
                  <img src="[SESSIONKEY_SKUIMAGEPATH][FIELDVALUE_BATCHPICKINFOSKUImageURL]"
                  alt="" height="175" width="125">
                </div>
                <div class="col-md-3 col-xs-3 amf-data-layout-responsive" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_BATCHPICKINFOPickToLPN]">
                  <label class="col-form-label">[FIELDVALUE_BATCHPICKINFOScanPickToCaption]</label>
                  <span class="amf-display-value-largebold amf-nowrap">[FIELDVALUE_PickToLPNRight5]</span>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="form-group">
                <div class="col-xs-4 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDVALUE_BATCHPICKINFOPickEntityCaption]<sup style="color:red">*</sup></label>
                  <input type="text" class="form-control amf-form-control" data-rfname="PickedEntity"
                  data-displaycaption="[FIELDVALUE_BATCHPICKINFOPickEntityCaption]"
                  data-rfvalidationset="NOTNULL" data-rftabindex="1" data-rfinputtype="SCANNER">
                </div>
                <div class="col-xs-4 amf-data-layout-responsive" style="padding:0 10px;">
                  <label class="col-form-label">[FIELDCAPTION_AMFNumPicked]</label>
                  <span class="amf-form-number-input-decrement" style="font-size:30px">-</span>
                  <input type="text" inputmode="numeric" class="amf-form-number-input" size="5" data-rfname="PickedUnits" data-displaycaption="[FIELDCAPTION_AMFNumPicked]" value="[FIELDVALUE_OPTIONSDefaultQuantity]"
                  data-rfvalidationset="NOTNULL,LESSEROREQUAL" data-rfvalidation-lesserorequal="[FIELDVALUE_BATCHPICKINFOTotalUnitsToPick]"
                  data-rfenabled="GREATERTHAN" data-rfenabledvalue="[FIELDVALUE_OPTIONSDefaultQuantity]" data-rfenabledgreaterthan="1" data-rftabindex="3"><span class="amf-form-number-input-increment" style="font-size:30px">+</span>
                </div>
                <div class="col-md-4 col-xs-4 amf-data-layout-responsive" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_BATCHPICKINFOScanPickToCaption]">
                  <label class="col-form-label">[FIELDVALUE_BATCHPICKINFOScanPickToCaption]</label>
                  <input type="text" class="form-control amf-form-control" data-rfname="PickedTo" placeholder="[FIELDVALUE_BATCHPICKINFOPickToLPN]"
                  data-displaycaption="[FIELDVALUE_BATCHPICKINFOScanPickToCaption]" value="[FIELDVALUE_DefaultPickToLPN]"
                  data-rfvalidationset="NOTNULL" data-rfenabled="COMPAREWITH"
                  data-rfenabledvalue="[FIELDVALUE_OPTIONSEnablePickToLPN]" data-rfenabledcomparewith="Y"
                  data-rfsubmitform="true" data-rftabindex="4" data-rfinputtype="SCANNER"/>
                </div>
              </div>
            </div>
            <div class="row" data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_OPTIONSIsCoORequired]" data-rfvisiblecomparewith="Y">
              <div class="form-group">
                <div class="col-xs-5 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCaption_AMFCoO]<sup style="color:red">*</sup></label>
                  <input type="text" data-rfname="CoO" data-displaycaption="CoO" value="" data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rftabindex="2"  class="form-control amf-form-control" data-rfinputtype="SCANNER"/>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="amf-data-layout-btns">
                <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                  <button type="button" class="btn btn-default" data-rfclickhandler="Picking_ConfirmUnitPick_SkipPick">Skip Pick</button>
                </div>
                <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                  <button type="button" class="btn btn-default" data-rfclickhandler="Picking_ConfirmUnitPick_PausePicking">Pause/Stop</button>
                </div>
                <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                  <button type="button" class="btn btn-primary" data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="col-md-6 col-xs-12">
          <div class="row">
            <div class="col-md-12">
              <h3 class="amf-datacard-title">Pick List for Task [FIELDVALUE_BATCHPICKINFOTaskId] ([FIELDVALUE_BATCHPICKINFOPickToPallet])</h3>
            </div>
          </div>
          <div class="table-responsive">
            <table class="table scroll table-striped table-bordered js-datatable-confirmunitpick-picklist">
              <thead>
                <tr>
                  <th>[FIELDCAPTION_AMFLocationOrLPN]</th>
                  <th hidden>[FIELDCAPTION_PickZone]</th>
                  <th>[FIELDCAPTION_SKU]</th>
                  <th>[FIELDCAPTION_SKUDescription]</th>
                  <th hidden>[FIELDCAPTION_NumPicks]</th>
                  <th hidden>[FIELDCAPTION_TotaLIPs]</th>
                  <th hidden>[FIELDCAPTION_TotalQty]</th>
                  <th hidden>[FIELDCAPTION_IPsToPick]</th>
                  <th>[FIELDCAPTION_UnitsToPick]</th>
                </tr>
              </thead>
              <tbody>
                [DATATABLE_PICKLIST]
              </tbody>
            </table>
          </div>
          <div class="amf-data-footer">
            <p>[FIELDVALUE_BATCHPICKINFOPickListSummary]</p>
          </div>
          <div class="row">
            <div class="col-lg-12 col-md-12 col-sm-12 col-xs-12">
              <div class="js-cimsrfc-confirmunitpick-picking-timer amf-data-timer"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
