/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/27  RIA     Show SKU image (CIMSV3-733)
  2020/07/24  RIA     Corrected data-rfenabled value and EnablePickToLPN (OB2-1189)
  2020/06/11  RIA     Alignment changes and field value mappings (HA-889)
  2020/05/15  TK      Display LPN in Pick List (HA-543)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/11/22  RIA     Initial Revision(CIMSV3-650)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Picking_LPNPick_Confirm';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName , DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'LPN Pick', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">LPN Pick</span>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-menu-open"><i class="amfi-menu"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-operation-info-open"><i class="amfi-info"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfsubmitpreprocess="Picking_ConfirmUnitPick_ProcessInputs" data-rfshowpreprocess="Picking_LPNPickConfirm_OnShow">
  <div class="container">
    <input type="hidden" data-rfname="Operation"value="CustomerOrderPicking" />
    <input type="hidden" data-rfname="ShortPick" value="N" />
    <div class="amf-form-menu">
      <a class="amf-form-menu-close">&times;</a>
      <button type="button" class="btn btn-info" data-rfclickhandler="Picking_LPNPick_ShortPick">Short Pick</button>
    </div>
    <div class="amf-form-operation-info">
      <a class="amf-form-operation-info-close">&times;</a>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_WaveNo]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_LPNPickInfo_WaveNo]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_AMFPalletOrCart]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_LPNPickInfo_PickToPallet]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_TaskId]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_LPNPickInfo_TaskId]</span>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_PickTicket]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_LPNPickInfo_PickTicket]</span>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_NumOrders]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_LPNPickInfo_TaskNumOrders]</span>
          </div>
        </div>
        <div class="form-group">
          <div class="col-md-4 col-xs-4 amf-slide-details-responsive">
            <label>[FIELDCAPTION_User]</label>
          </div>
          <div class="col-md-8 col-xs-8 amf-slide-details-responsive">
            <span>[FIELDVALUE_LPNPickInfo_UserNameDisplay]</span>
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
                <div class="col-md-7 col-xs-7 amf-data-layout-responsive" style="border-right:1px solid #ccc;">
                  <label class="col-form-label">[FIELDCAPTION_AMFPickFrom]</label>
                  <span class="amf-display-value-largebold">[FIELDVALUE_LPNPickInfo_Location]</span>
                  <span class="amf-display-value-small">Zone [FIELDVALUE_LPNPickInfo_PickZoneDesc]</span>
                  <span class="amf-display-value-small" style="color:#b41700"
                  data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_LPNPickInfo_LocationType]"
                  data-rfvisiblecomparewith="R,B">[FIELDVALUE_LPNPickInfo_LPN]</span>
                </div>
                <div class="col-md-5 col-xs-5 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCAPTION_AMFLPNToPick]</label>
                  <span class="amf-display-value-large" style="color:#b41700">[FIELDVALUE_LPNRight10]</span>
                  <label class="col-form-label" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNPickInfo_Pallet]">[FIELDCAPTION_Pallet]</label>
                  <span class="amf-display-value-medium">[FIELDVALUE_LPNPickInfo_Pallet]</span>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="form-group">
                <div class="col-md-6 col-xs-6 amf-data-layout-responsive" >
                  <span class="amf-display-value-medium">[FIELDVALUE_LPNPickInfo_DisplaySKU]</span>
                  <span class="amf-display-value-small">[FIELDVALUE_LPNPickInfo_DisplaySKUDesc]</span>
                  <span class="amf-display-value-small">[FIELDVALUE_LPNPickInfo_DisplaySKUDesc2]</span>
                </div>
                <div class="col-md-3 col-xs-3 amf-data-layout-responsive" style="border-right:1px solid #ccc;">
                  <img src="[SESSIONKEY_SKUIMAGEPATH][FIELDVALUE_LPNPickInfo_SKUImageURL]"
                  alt="" height="175" width="150">
                </div>
                <div class="col-md-3 col-xs-3 amf-data-layout-responsive">
                  <label class="col-form-label">[FIELDCAPTION_LPNQuantity]</label>
                  <span class="amf-display-value-medium">[FIELDVALUE_LPNPickInfo_DisplayQty]</span>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="form-group">
                <div class="col-xs-4 amf-data-layout-responsive">
                  <label class="col-form-label">Scan LPN<sup style="color:red">*</sup></label>
                  <input type="text" class="form-control amf-form-control" data-rfname="PickedEntity"
                  data-displaycaption="[FIELDVALUE_LPNPickInfo_PickEntityCaption]"
                  data-rfvalidationset="NOTNULL" data-rftabindex="1" data-rfinputtype="SCANNER">
                </div>
                <div class="col-md-4 col-xs-4 amf-data-layout-responsive" data-rfvisibility="COMPAREWITH"
                data-rfvisiblevalue="[FIELDVALUE_Options_EnablePickToLPN]" data-rfvisiblecomparewith="Y">
                  <label class="col-form-label">Scan SKU</label>
                  <input type="text" class="form-control amf-form-control" data-rfname="PickedTo" data-displaycaption="[FIELDVALUE_LPNPickInfo_ScanPickToCaption]" value=""
                  data-rfvalidationset="NOTNULL" data-rfsubmitform="true"
                  data-rfinputtype="SCANNER" data-rftabindex="2"/>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="amf-data-layout-btns">
                <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                  <button type="button" class="btn btn-default" data-rfclickhandler="Picking_LPNPick_SkipPick">Skip Pick</button>
                </div>
                <div class="col-md-4 col-xs-4 amf-button-layout-responsive">
                  <button type="button" class="btn btn-default" data-rfclickhandler="Picking_LPNPick_PausePicking">Pause/Stop</button>
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
              <h3 class="amf-datacard-title">Pick List for Task [FIELDVALUE_LPNPickInfo_TaskId] ([FIELDVALUE_LPNPickInfo_PickToPallet])</h3>
            </div>
          </div>
          <div class="table-responsive">
            <table class="table scroll table-striped table-bordered js-datatable-confirmlpnpick-picklist">
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
                  <th>[FIELDCAPTION_Quantity]</th>
                </tr>
              </thead>
              <tbody>
                [DATATABLE_PICKLIST]
              </tbody>
            </table>
          </div>
          <div class="amf-data-footer">
            <p>[FIELDVALUE_LPNPickInfo_PickListSummary]</p>
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
