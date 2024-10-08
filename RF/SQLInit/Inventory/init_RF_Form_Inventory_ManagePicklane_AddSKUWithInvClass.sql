/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/16  RIA     Added button to refresh (HA-1688)
  2020/07/20  RIA     Initial Revision(HA-652)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inventory_MP_AddSKUWithInvClass';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Add SKU With Inv Classes', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Add SKU With Inv Classes</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input type="hidden" data-rfname="Operation" value="ManagePicklane" >
    <input type="hidden" data-rfname="ConfirmAddSKU" value="[FIELDVALUE_ConfirmAddSKU]" >
    <input type="hidden" data-rfname="ConfirmSetupPicklane" value="[FIELDVALUE_ConfirmSetupPicklane]" >
    <input type="hidden" data-rfname="ConfirmAddInventory" value="[FIELDVALUE_ConfirmAddInventory]" >
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
    data-rfmodelvalueprefix="InventoryClass1" >
    <div class="col-md-5 col-sm-5 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="form-group">
          <input class="amf-input" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanPicklane_PH]"
          data-rfname="ScannedPicklane" data-displaycaption="[FIELDCAPTION_AMFPickLane]" value="[FIELDVALUE_LocationInfo_Location]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]"
          data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="Location">[FIELDCAPTION_Location]</label>
        </div>
        <div class="form-group">
          <input class="amf-input" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKU_PH]"
          data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value="[FIELDVALUE_SKU]"
          data-rftabindex="2" data-rfinputtype="SCANNER">
          <label for="SKU">[FIELDCAPTION_SKU]</label>
        </div>
        <div class="row">
          <div class="col-md-12 col-sm-12 col-xs-12">
            <div class="form-group">
              <div class="amf-form-input-responsive-width">
                <label class="col-form-label">[FIELDCAPTION_InventoryClass1]</label>
                <select class="form-control" data-rfname="InventoryClass1"
                data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
                data-rfvalidationhandler="Inventory_MP_ValidateInvClass1" data-rftabindex="3">[DATAOPTIONS_InventoryClass1]</select>
              </div>
            </div>
          </div>
          <div class="col-md-12 col-sm-12 col-xs-12 hidden">            
            <label class="col-form-label">[FIELDCAPTION_InventoryClass2]</label>
            <select class="amf-dropdown-list" data-rfname="InventoryClass2">[DATAOPTIONS_InventoryClass2]</select>
          </div>
          <div class="col-md-12 col-sm-12 col-xs-12 hidden">
            <label class="col-form-label">[FIELDCAPTION_InventoryClass3]</label>
            <select class="amf-dropdown-list" data-rfname="InventoryClass3">[DATAOPTIONS_InventoryClass3]</select>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-sm-4 col-xs-4">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-4" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
            <button type="button" class="amf-button amf-button-fullwidth"
            data-rfclickhandler="Inventory_MP_RefreshGrid">Cancel</button>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-7 col-sm-7 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
    data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-12 col-sm-12 col-xs-12">
              <h3 class="amf-datacard-title">Location Info</h3>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_LocationType] / [FIELDCAPTION_StorageType]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationTypeDesc] / [FIELDVALUE_LocationInfo_StorageTypeDesc]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Status]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationStatusDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFMinMaxReplenishLevel]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_MinReplenishLevel] / [FIELDVALUE_LocationInfo_MaxReplenishLevel]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_AMFAllowMultipleSKUs]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_AllowMultipleSKUs]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumSKUs]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_NumSKUs]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_Quantity]</span>
            </div>
          </div>
          <div class="row">
            <div class="col-md-12 col-sm-12 col-xs-12">
              <h3 class="amf-datacard-title">SKU List</h3>
              <div class="table-responsive">
                <table class="table scroll table-striped table-bordered">
                  <thead>
                    <tr>
                      <th hidden>[FIELDCAPTION_LPN]</th>
                      <th>[FIELDCAPTION_SKU]</th>
                      <th>[FIELDCAPTION_SKUDescription]</th>
                      <th>[FIELDCAPTION_Quantity]</th>
                    </tr>
                  </thead>
                  <tbody>
                    [DATATABLE_LOCLPNS]
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
        <div class="clearfix"></div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
