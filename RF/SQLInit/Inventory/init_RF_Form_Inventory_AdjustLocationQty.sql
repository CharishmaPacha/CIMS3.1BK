/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/14  RIA     Added filter (HA-2938)
  2020/12/08  RIA     Added classes for background (CIMSV3-1236)
  2020/10/20  RIA     Integrated SKUInfoPanel (HA-431)
  2020/10/12  RIA     Alignment changes (CIMSV3-1134)
  2020/05/04  RIA     Changes and clean up (CIMSV3-802)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/04/22  RIA     Changes to integrate Input panel (CIMSV3-802)
  2020/03/05  RIA     Changes to remove the NewInnerPacks, NewUnitsPerInnerPack values (CIMSV3-709)
  2019/11/12  RIA     Initial Revision(CIMSV3-624)
------------------------------------------------------------------------------*/

declare @vFormName           TName,
        @vQtyInputPanelName  TName,
        @vSKUPanelName       TName,
        @vQtyInputPanelHTML  TVarchar,
        @vSKUPanelHTML       TVarchar;

/*------------------------------------------------------------------------------*/
select @vQtyInputPanelName = 'Common_QuantityInputPanel',
       @vSKUPanelName      = 'Common_SKUInfoPanel';

/* Drop temp table for QtyInputPanel, if exists */
if (object_id('tempdb..#QtyInputPanel') is not null)
  drop table #QtyInputPanel;

select F.RawHtml, BU.BusinessUnit
into #QtyInputPanel
from AMF_Forms F, vwBusinessUnits BU
where (F.FormName = @vQtyInputPanelName);

  /* Drop temp table for SKUInfoPanel, if exists */
  if (object_id('tempdb..#SKUInfoPanel') is not null)
     drop table #SKUInfoPanel;

select F.RawHtml, BU.BusinessUnit
into #SKUInfoPanel
from AMF_Forms F, vwBusinessUnits BU
where (F.FormName = @vSKUPanelName);

/* Change the default OnChange methods for AdjustLocQty form */
update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectCases_OnChange', 'Inventory_AdjustOrTransferLocQty_SelectCases_Onchange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectEaches_OnChange', 'Inventory_AdjustOrTransferLocQty_SelectEaches_Onchange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, '"GREATEROREQUAL"', '"ISBETWEEN"');

/* Change the default names to LocationInfo_ for AdjustLocationQty form */
update #SKUInfoPanel
set RawHtml = replace(RawHtml, 'SKUInfo_', 'LocationInfo_');

/*------------------------------------------------------------------------------*/
select @vFormName = 'Inventory_AdjustLocationQty';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Adjust Quantity', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Adjust LPN/Location Quantity</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container" data-rfshowpreprocess="Inventory_AdjustLocQty_OnShow">
    <input type="hidden" data-rfname="LPNOperation" value="AdjustLPN" >
    <input type="hidden" data-rfname="LocationOperation" value="AdjustLocation" >
    <input type="hidden" data-rfname="Operation" value="AdjustQty" >
    <input type="hidden" data-rfname="LPNDetailId" value="" >
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
    data-rfmodelvalueprefix="SKUDETAILS" >
    <div class="col-md-6 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-8 col-sm-8 col-xs-12">
            <div class="form-group">
              <input class="amf-input" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanLPNPicklane_PH]"
              data-rfname="Entity" data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_LocationInfo_Location]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
              data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]"
              data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
              <label for="LPN">[FIELDCAPTION_AMFLPNOrPicklane]</label>
            </div>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-12">
            <div data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]">
              <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
            <div data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]"
            data-rfvisiblegreaterthan="0">
              <button type="button" class="amf-button amf-button-confirm amf-button-fullwidth amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Confirm</button>
            </div>
          </div>
        </div>
        <div class="clearfix"></div>
        <div class="row" style="background:none; display: none;" data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_LocationInfo_NumSKUs]" data-rfvisiblegreaterthan="1">
          <div class="col-md-8 col-sm-8 col-xs-8">
            <div class="form-group">
              <input class="amf-input" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKUUPC_PH]"
              data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value=""
              data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Inventory_AdjustLocQty_OnSKUEnter"
              data-rfsubmitform="false" data-rftabindex="2" data-rfinputtype="SCANNER">
              <label for="SKU">[FIELDCAPTION_SKU]</label>
            </div>
          </div>
        </div>
        <div class = "row" data-rfvisibility="COMPAREWITH"data-rfvisiblevalue="[FIELDVALUE_LocationInfo_NumSKUs]" data-rfvisiblecomparewith="1">' +
          SIP.RawHtml +
          '<div class="amf-mb-10"></div>'+
        '</div>
        <div class="clearfix"></div>
        <div data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">' +
          QIP.RawHtml +
        '</div>
        <div class="row" style="background:none; display: none;"
        data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
          <div class="col-md-12 col-sm-12 col-xs-12">
            <label class="col-form-label">[FIELDCAPTION_ReasonCode]</label>
            <select class="amf-dropdown-list" data-rfname="ReasonCode"
            data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT" data-rftabindex="11"
            data-rfvalidationhandler="Inventory_AdjustQty_ValidateReasonCode">[DATAOPTIONS_ReasonCodes]</select>
          </div>
        </div>
        </div>
      </div>
      <div class="col-md-6 col-sm-12 col-xs-12 amf-form-display-panel"
      data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
        <div class="amf-form-panel-shadow">
          <div class="amf-datacard-container" style="background:none;">
            <div class="row">
              <div class="col-md-7 col-sm-7 col-xs-7">
                <div class="amf-datacard amf-datacard-inline">
                  <div class="col-md-12">
                    <label class="col-form-label">[FIELDCAPTION_Location]</label>
                    <span class="amf-display-value">[FIELDVALUE_LocationInfo_Location]</span>
                  </div>
                </div>
              </div>
              <div class="col-md-5 col-sm-5 col-xs-5">
                <div class="amf-datacard amf-datacard-inline">
                  <div class="col-md-12 col-sm-12 col-xs-12">
                    <label class="col-form-label">[FIELDCAPTION_Status]</label>
                    <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationStatusDesc]</span>
                  </div>
                </div>
              </div>
            </div>
            <div class="row">
              <div class="col-md-4 col-sm-4 col-xs-5">
                <div class="amf-mt-10"></div>
                <div class="amf-datacard-title">SKU List</div>
              </div>
              <div class="col-md-4 col-sm-4 col-xs-5 pull-right">
                <div class="form-group">
                  <input class="amf-input" type="text" name="FilterValue" id="FilterValue"
                  placeholder="[FIELDCAPTION_Filter]" data-rfname="FilterValue"
                  data-displaycaption="[FIELDCAPTION_Filter]" value="">
                </div>
              </div>
            </div>
            <div class="table-responsive">
              <table class="table table-striped table-bordered js-datatable-content-details">
                <thead>
                  <tr>
                    <th>[FIELDCAPTION_SKU]</th>
                    <th>[FIELDCAPTION_SKUDescription]</th>
                    <th hidden>[FIELDCAPTION_InnerPacks]</th>
                    <th>[FIELDCAPTION_Quantity]</th>
                    <th>[FIELDCAPTION_ComittedQty]</th>
                    <th>[FIELDCAPTION_ReservedQty]</th>
                  </tr>
                </thead>
                <tbody>[DATATABLE_SKUDETAILS]</tbody>
              </table>
            </div>
            <div class="amf-datacard">
              <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_LocationType] / [FIELDCAPTION_StorageTypeDescription]</label>
                <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationTypeDesc] / [FIELDVALUE_LocationInfo_StorageTypeDesc]</span>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_Status]</label>
                <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationStatusDesc]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-3 col-sm-3 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_NumSKUs]</label>
                <span class="amf-display-value">[FIELDVALUE_LocationInfo_NumLPNs]</span>
              </div>
              <div class="col-md-3 col-sm-3 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
                <span class="amf-display-value">[FIELDVALUE_LocationInfo_Quantity]</span>
              </div>
              <div class="col-md-3 col-sm-3 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_ReservedQuantity]</label>
                <span class="amf-display-value">[FIELDVALUE_LocationInfo_ReservedQty]</span>
              </div>
              <div class="col-md-3 col-sm-3 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_DirectedQty]</label>
                <span class="amf-display-value">[FIELDVALUE_LocationInfo_DirectedQty]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_PutawayZone]</label>
                <span class="amf-display-value">[FIELDVALUE_LocationInfo_PutawayZone] / [FIELDVALUE_LocationInfo_PutawayZoneDesc]</span>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_PickingZone]</label>
                <span class="amf-display-value">[FIELDVALUE_LocationInfo_PickingZone] / [FIELDVALUE_LocationInfo_PickingZoneDesc]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-6 col-sm-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_AMFMinMaxReplenishLevel]</label>
                <span class="amf-display-value">[FIELDVALUE_LocationInfo_MinReplenishLevel] / [FIELDVALUE_LocationInfo_MaxReplenishLevel]</span>
              </div>
            </div>
          </div>
          <div class="clearfix"></div>
        </div>
      </div>
    </div>
  </div>
'
from #QtyInputPanel QIP
     join vwBusinessUnits BU on QIP.BusinessUnit = BU.BusinessUnit
     join #SKUInfoPanel SIP on SIP.BusinessUnit = BU.BusinessUnit;
