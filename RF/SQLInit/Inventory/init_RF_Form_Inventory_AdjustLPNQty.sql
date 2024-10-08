/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/14  RIA     Added filter (HA-2938)
  2020/12/08  RIA     Added classes for background (CIMSV3-1236)
  2020/10/07  RIA     Alignment changes (JL-196)
  2020/05/15  RIA     Show DisplaySKU and DisplaySKUDesc (HA-431)
  2020/05/06  RIA     Align and show small fonts for SKU and SKUDesc (HA-431)
  2020/05/04  RIA     Changes and clean up (CIMSV3-802)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/04/22  RIA     Changes to integrate Input panel (CIMSV3-756)
  2020/03/05  RIA     Changes to remove the NewInnerPacks, NewUnitsPerInnerPack values (CIMSV3-709)
  2019/11/12  RIA     Changes to FormName (CIMSV3-624)
  2019/10/28  RIA     Form clean up (CIMSV3-624)
  2019/07/02  RIA     Alignment changes and changed width for inputs (CID-593)
  2019/06/25  RIA     Initial Revision(CID-593)
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

/* Change the default OnChange methods for AdjustLPNQty form */
update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectCases_OnChange', 'Inventory_AdjustOrTransferLPNQty_SelectCases_Onchange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectEaches_OnChange', 'Inventory_AdjustOrTransferLPNQty_SelectEaches_Onchange');

/* Change the default names to LPNInfo_ for AdjustLPNQty form */
update #SKUInfoPanel
set RawHtml = replace(RawHtml, 'SKUInfo_', 'LPNInfo_');

/*------------------------------------------------------------------------------*/
select @vFormName = 'Inventory_AdjustLPNQty';
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
  <div class="amf-form-layout-container" data-rfshowpreprocess="Inventory_AdjustLPNQty_OnShow">
    <input type="hidden" data-rfname="LPNOperation" value="AdjustLPN" >
    <input type="hidden" data-rfname="LocationOperation" value="AdjustLocation" >
    <input type="hidden" data-rfname="Operation" value="AdjustQty" >
    <input type="hidden" data-rfname="LPNDetailId" value="" >
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
    data-rfmodelvalueprefix="LPNDETAILS" >
      <div class="col-md-6 col-sm-6 col-xs-12 amf-form-input-panel">
        <div class="amf-form-panel-shadow">
          <div class="row">
            <div class="col-md-8 col-sm-8 col-xs-12">
              <div class="form-group">
                <input class="amf-input" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPNPicklane_PH]"
                data-rfname="Entity" data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_LPNInfo_LPN]"
                data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
                data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LPNInfo_LPNId]"
                data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
                <label for="LPN">[FIELDCAPTION_AMFLPNOrPicklane]</label>
              </div>
            </div>
            <div class="col-md-4 col-sm-4 col-xs-12">
              <div class="form-group" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]">
                <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
                data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
              </div>
              <div class="form-group" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]"
              data-rfvisiblegreaterthan="0">
                <button type="button" class="amf-button amf-button-confirm amf-button-fullwidth amf-button-top-margin"
                data-rfclickhandler="RFConnect_Submit_Request">Confirm</button>
              </div>
            </div>
          </div>
          <div class="clearfix"></div>
          <div style="display: none;" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LPNInfo_NumLines]" data-rfvisiblegreaterthan="1">
            <div class="row">
              <div class="col-md-8 col-xs-8">
                <div class="form-group">
                  <input class="amf-input" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKUUPC_PH]"
                  data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value=""
                  data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Inventory_AdjustLPNQty_OnSKUEnter"
                  data-rfsubmitform="false" data-rftabindex="2" data-rfinputtype="SCANNER">
                  <label for="SKU">[FIELDCAPTION_SKU]</label>
                </div>
              </div>
            </div>
          </div>
          <div class ="row" data-rfvisibility="COMPAREWITH" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_NumLines]" data-rfvisiblecomparewith="1">' +
            SIP.RawHtml +
            '<div class="amf-mb-10"></div>'+
'       </div>
        <div class="clearfix"></div>
        <div data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">' +
          QIP.RawHtml +
        '</div>
        <div class="amf-datacard-ReasonCodes-input" style="display: none;"
        data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
          <div class="row">
            <div class="col-md-12 col-sm-12 col-xs-12">
              <label class="col-form-label">[FIELDCAPTION_ReasonCode]</label>
              <select class="amf-dropdown-list" data-rfname="ReasonCode"
                data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT" data-rftabindex="11"
                data-rfvalidationhandler="Inventory_AdjustQty_ValidateReasonCode">[DATAOPTIONS_ReasonCodes]</select>
              </div>
            </div>
          </div>
          <div class="clearfix"></div>
        </div>
      </div>
      <div class="col-md-6 col-sm-6 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
      data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
        <div class="amf-form-panel-shadow">
          <div class="amf-datacard-container">
            <div class="row">
              <div class="col-md-7 col-sm-7 col-xs-7">
                <div class="amf-datacard amf-datacard-inline">
                  <div class="col-md-12">
                    <label class="col-form-label">[FIELDCAPTION_LPN]</label>
                    <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPN]</span>
                  </div>
                </div>
              </div>
              <div class="col-md-5 col-sm-5 col-xs-5">
                <div class="amf-datacard amf-datacard-inline">
                  <div class="col-md-12">
                    <label class="col-form-label">[FIELDCAPTION_Status]</label>
                    <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPNStatusDesc]</span>
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
                <tbody>[DATATABLE_LPNDETAILS]</tbody>
              </table>
            </div>
            <div class="amf-datacard">
              <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_InnerPacks] / [FIELDCAPTION_Quantity]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_InnerPacks] / [FIELDVALUE_LPNInfo_Quantity]</span>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-6">
                <label class="col-form-label"><span data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_Location]">[FIELDCAPTION_Location] /</span> [FIELDCAPTION_Pallet]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_Location] / [FIELDVALUE_LPNInfo_Pallet]</span>
              </div>
            </div>
            <div class="amf-datacard" data-rfvisibility="GREATERTHAN"
            data-rfvisiblevalue="[FIELDVALUE_LPNInfo_ReceiptId]" data-rfvisiblegreaterthan="0">
              <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_ReceiptNumber]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_ReceiptNumber]</span>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_ReceiverNumber]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_ReceiverNumber]</span>
              </div>
            </div>
            <div class="amf-datacard" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_DestLocation]">
              <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_DestZone]" data-rfvisibility="NOTNULL">
                <label class="col-form-label">[FIELDCAPTION_DestZone]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_DestZone]</span>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-6" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_DestLocation]" data-rfvisibility="NOTNULL">
                <label class="col-form-label">[FIELDCAPTION_DestLocation]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_DestLocation]</span>
              </div>
            </div>
            <div class="amf-datacard" data-rfvisibility="GREATERTHAN"
            data-rfvisiblevalue="[FIELDVALUE_LPNInfo_OrderId]" data-rfvisiblegreaterthan="0">
              <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_Wave]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_WaveType] [FIELDVALUE_LPNInfo_WaveNo]</span>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_PickTicket]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_Ownership]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_Ownership]</span>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_Warehouse]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_DestWarehouse]</span>
              </div>
            </div>
            <div class="amf-datacard" hidden>
              <div class="col-md-12 col-sm-12 col-xs-12 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_Customer]</label>
                <span class="amf-display-value">[FIELDVALUE_SoldToId] [FIELDVALUE_CustomerName]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_TaskId]</label>
                <span class="amf-display-value">[FIELDVALUE_TaskId]</span>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_LoadNumber]</label>
                <span class="amf-display-value">[FIELDVALUE_LoadNumber]</span>
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
