/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/15  RIA     Added LPNId and SKUId (HA-2877)
  2021/05/16  RIA     Added button to stop (HA-1688)
  2021/04/16  RIA     Added button to refresh (HA-1688)
  2021/03/10  RIA     Changes to bind value (HA-1688)
  2020/07/30  RIA     Changes to caption (HA-652)
  2020/06/26  RIA     Changed caption for AMFMinMaxReplenishLevel, AllowMultipleSKUs (HA-998)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/01/16  RIA     Changes to not have extra spaces (CIMSV3-655)
  2020/01/05  RIA     Initial Revision(CIMSV3-643)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inventory_ManagePicklane';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Manage Picklane', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Manage Picklane</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input type="hidden" data-rfname="Operation" value="ManagePicklane">
    <input type="hidden" data-rfname="LPNId">
    <input type="hidden" data-rfname="SKUId">
    <input type="hidden" data-rfname="InventoryClasses" value="[FIELDVALUE_InventoryClasses]">
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="form-group">
          <input class="amf-input" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanPicklane_PH]"
          data-rfname="ScannedPicklane" data-displaycaption="[FIELDCAPTION_AMFPickLane]" value="[FIELDVALUE_LocationInfo_Location]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]"
          data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="Location">[FIELDCAPTION_Location]</label>
        </div>
        <div data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
          <div class="form-group" data-rfvisibility="COMPAREWITH"
          data-rfvisiblevalue="[FIELDVALUE_AddSKU]" data-rfvisiblecomparewith="Y">
            <div class="amf-checkbox-container">
              <input class="amf-checkbox amf-input" type="checkbox"
              data-rfname="ConfirmAddSKU" data-displaycaption="[FIELDCAPTION_CheckBox]"
              id="AddSKUcheckbox1" onchange="Inventory_MP_SelectOption_Onchange()">
              <label for="AddSKUcheckbox1">Add SKU</label>
            </div>
          </div>
          <div class="form-group" data-rfvisibility="COMPAREWITH"
          data-rfvisiblevalue="[FIELDVALUE_RemoveSKU]" data-rfvisiblecomparewith="Y">
            <div class="amf-checkbox-container">
              <input class="amf-checkbox amf-input" type="checkbox"
              data-rfname="ConfirmRemoveSKU" data-displaycaption="[FIELDCAPTION_CheckBox]"
              id="RemoveSKUcheckbox2" onchange="Inventory_MP_SelectOption_Onchange()">
              <label for="RemoveSKUcheckbox2">Remove SKU</label>
            </div>
          </div>
          <div class="form-group" data-rfvisibility="COMPAREWITH"
          data-rfvisiblevalue="[FIELDVALUE_SetupPicklane]" data-rfvisiblecomparewith="Y">
            <div class="amf-checkbox-container">
              <input class="amf-checkbox amf-input" type="checkbox"
              data-rfname="ConfirmSetupPicklane" data-displaycaption="[FIELDCAPTION_CheckBox]"
              id="SetupPicklanecheckbox3" onchange="Inventory_MP_SelectOption_Onchange()">
              <label for="SetupPicklanecheckbox3">Setup Picklane</label>
            </div>
          </div>
          <div class="form-group" data-rfvisibility="COMPAREWITH"
          data-rfvisiblevalue="[FIELDVALUE_AddInventory]" data-rfvisiblecomparewith="Y">
            <div class="amf-checkbox-container">
              <input class="amf-checkbox amf-input" type="checkbox"
              data-rfname="ConfirmAddInventory" data-displaycaption="[FIELDCAPTION_CheckBox]"
              id="AddInventorycheckbox4" onchange="Inventory_MP_SelectOption_Onchange()">
              <label for="AddInventorycheckbox4">Update Inventory</label>
            </div>
          </div>
          <div class="form-group">
            <input class="amf-input" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKU_PH]"
            data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value="[FIELDVALUE_ValidatedSKU]"
            data-rfsubmitform="true" data-rftabindex="2" data-rfinputtype="SCANNER"
            data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT" data-rfvalidationhandler="Inventory_MP_ValidateSelectedOptions">
            <label for="SKU">[FIELDCAPTION_SKU]</label>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-sm-4 col-xs-4 amf-form-input-responsive-width">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-4" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
            <button type="button" class="amf-button amf-button-fullwidth"
            data-rfclickhandler="Inventory_MP_Stop">Complete</button>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-4" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
            <button type="button" class="amf-button amf-button-fullwidth"
            data-rfclickhandler="Inventory_MP_RefreshGrid">Refresh</button>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
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
          <div class="amf-mb-10"></div>
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
            <div class="clearfix"></div>
            <div class="col-md-12 col-sm-12 col-xs-12">
              <div class="table-responsive">
                <table class="table scroll table-striped table-bordered js-datatable-sku-details">
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
