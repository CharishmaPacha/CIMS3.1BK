/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/30  RIA     Form clean up and added buttons (OB2-1970)
  2021/06/21  RIA     Added filter (HA-2878)
  2020/07/16  NB      Changes to process FORMATTR for QuantityInputPanel via Function (CIMSV3-773)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/04/23  RIA     Changes to set focus to Quantity after scanning ToEntity/SKU (CIMSV3-834)
  2019/11/13  RIA     Initial Revision(CIMSV3-632)
------------------------------------------------------------------------------*/

declare @vFormName           TName,
        @vQtyInputPanelName  TName,
        @vQtyInputPanelHTML  TVarchar;

/*------------------------------------------------------------------------------*/
select @vQtyInputPanelName = 'Common_QuantityInputPanel';
declare @ttSubstituteFormAttributes TAMFFormAttributes;

insert into @ttSubstituteFormAttributes
             (AttributeName,                          AttributeValue)
      select 'SelectCases_OnChange',                  'Inventory_AdjustOrTransferLocQty_SelectCases_Onchange'
union select 'SelectEaches_OnChange',                 'Inventory_AdjustOrTransferLocQty_SelectEaches_Onchange'
union select '"GREATEROREQUAL"',                      '"ISBETWEEN"'
/*------------------------------------------------------------------------------*/
select @vFormName = 'Inventory_TransferLocationInventory';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Transfer Inventory', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Transfer Inventory</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container" data-rfshowpreprocess="Inventory_TransferLocQty_OnShow">
    <input type="hidden" data-rfname="LPNOperation" value="TransferLPN" >
    <input type="hidden" data-rfname="LocationOperation" value="TransferLocation" >
    <input type="hidden" data-rfname="Operation" value="TransferInventory">
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
    data-rfmodelvalueprefix="SKUDETAILS">
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="form-group"> 
          <input class="amf-input" type="text" name="FromEntity" id="FromEntity" placeholder="[FIELDCAPTION_AMFScanFromLocationOrLPN_PH]" 
          data-rfname="Entity" data-displaycaption="[FIELDCAPTION_AMFLPNOrPicklane]" value="[FIELDVALUE_LocationInfo_Location]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]"
          data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="LPNOrLocation">[FIELDCAPTION_AMFFromLPNOrPicklane]</label>
        </div>
        <div data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
          <div class="form-group"> 
            <input type="text" class="amf-input" name="ToEntity" id="ToEntity" placeholder="[FIELDCAPTION_AMFScanToLocationOrLPN_PH]"
            data-rfname="ToEntity" data-displaycaption="[FIELDCAPTION_AMFLPNOrPicklane]" value=""
            data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
            data-rftabindex="2" data-rfinputtype="SCANNER">
            <label for="LPNOrLoction">[FIELDCAPTION_AMFToLPNOrPicklane]</label>
          </div>
          <div class="form-group" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LocationInfo_NumSKUs]" data-rfvisiblegreaterthan="1">
            <input type="text" class="amf-input" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKU_PH]"
            data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value=""
            data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT"
            data-rfvalidationhandler="Inventory_TransferLocQty_OnSKUEnter"
            data-rfsubmitform="false" data-rftabindex="3" data-rfinputtype="SCANNER">
            <label for="SKU">[FIELDCAPTION_SKU]</label>
          </div>
        </div>
        <div class="clearfix"></div>
        <div data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">' +
          dbo.fn_AMF_SubstituteFormAttributes(@vQtyInputPanelName, @ttSubstituteFormAttributes, null /* Device Category */, BusinessUnit) +				  
        '</div>
        <div class="row">
          <div class="col-md-4 col-sm-5 col-xs-5" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-6" div data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
            <button type="button" class="amf-button amf-button-confirm amf-button-fullwidth"
            data-rfclickhandler="Inventory_TransferQty_Continue">Confirm & Continue</button>
          </div>
          <div class="col-md-4 col-sm-6 col-xs-6" div data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
            <button type="button" class="amf-button amf-button-confirm amf-button-fullwidth"
            data-rfclickhandler="RFConnect_Submit_Request">Confirm & Exit</button>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-display-panel"
    data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]"
    data-rfvisiblegreaterthan="0">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
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
            <table class="table scroll table-striped table-bordered js-datatable-content-details">
              <thead>
                <tr>
                  <th>[FIELDCAPTION_SKU]</th>
                  <th>[FIELDCAPTION_SKUDescription]</th>
                  <th hidden>[FIELDCAPTION_InnerPacks]</th>
                  <th>[FIELDCAPTION_Quantity]</th>
                  <th>[FIELDCAPTION_ComittedQty]</th>
                </tr>
              </thead>
              <tbody>[DATATABLE_SKUDETAILS]</tbody>
            </table>
          </div>
          <div class="amf-mb-10"></div>
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
            <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumSKUs]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_NumLPNs]</span>
            </div>
            <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_Quantity]</span>
            </div>
            <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ReservedQuantity]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_ReservedQty]</span>
            </div>
            <div class="col-md-3 col-sm-3 col-xs-3">
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
from vwBusinessUnits BU;
