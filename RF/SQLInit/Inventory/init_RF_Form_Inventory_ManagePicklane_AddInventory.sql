/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/16  RIA     Added button to refresh (HA-1688)
  2020/08/18  RIA     Included additional inputs (HA-1316)
  2020/07/30  RIA     Included additional inputs, made changes to captions (HA-652)
  2020/07/24  RIA     Included reason codes (HA-652)
  2020/06/26  RIA     Changed caption for AMFMinMaxReplenishLevel, AllowMultipleSKUs (HA-998)
  2020/05/06  RIA     set focus to quantiy input (HA-428)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/01/07  RIA     Cleaned up the form (CIMSV3-655)
  2020/01/05  RIA     Initial Revision(CIMSV3-643)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inventory_AddInventory';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Update Inventory', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Update Inventory</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container" data-rfshowpreprocess="Inventory_MP_AddInv_OnShow">
    <input type="hidden" data-rfname="Operation" value="ManagePicklane" >
    <input type="hidden" data-rfname="LPNId" >
    <input type="hidden" data-rfname="SKUId" >
    <input type="hidden" data-rfname="CurrInvClass1" >
    <input type="hidden" data-rfname="CurrInvClass2" >
    <input type="hidden" data-rfname="CurrInvClass3" >
    <div class="col-md-5 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="form-group">
          <input class="amf-input" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanPicklane_PH]"
          data-rfname="ScannedPicklane" data-displaycaption="[FIELDCAPTION_AMFPickLane]" value="[FIELDVALUE_LocationInfo_Location]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]"
          data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="Location">[FIELDCAPTION_Location]</label>
        </div>
            <div class="amf-datacard-container">
              <div class="amf-datacard">
            <div class="col-md-12 col-xs-12">
                <span class="amf-display-value-medium">[FIELDVALUE_SKU]</span>
                <span class="amf-display-value-small">[FIELDVALUE_SKUDescription]</span>
              </div>
            </div>
          </div>
        <div class="amf-mb-10"></div>
        <div class="row">
          <div class="col-md-5 col-sm-5 col-xs-5 amf-form-number-input-container">
            <label class="col-form-label">[FIELDCAPTION_NewQuantity]</label>
            <div class="clearfix"></div>
            <span class="amf-form-number-input-decrement">-</span>
            <input class="amf-form-number-input amf-form-number-input-width" type="text" size="5" inputmode="numeric"
            data-rfname="Quantity" data-displaycaption="[FIELDCAPTION_Quantity]" value="1"
            data-rfvalidationset="GREATEROREQUAL" data-rfvalidation-greaterorequal="0" data-rfvalidateon="SUBMIT"
            id="MaxQuantity" data-rftabindex="2">
            <span class="amf-form-number-input-increment">+</span>
          </div>
          <div class="col-md-5 col-sm-5 col-xs-5">
            <label class="col-form-label">[FIELDCAPTION_UoM]</label>
            <select class="form-control" data-rfdefaultvalue = [FIELDVALUE_DefaultUoM]
            data-rfname="UoM" data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
            data-rfvalidationhandler="Inventory_MP_ValidateUoM">[DATAOPTIONS_UoM]</select>
          </div>
        </div>
        <div class="row">
          <div class="col-md-12 col-sm-12 col-xs-12">
            <label class="col-form-label">[FIELDCAPTION_ReasonCode]</label>
            <select class="form-control" data-rfname="ReasonCode"
            data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
            data-rfvalidationhandler="Inventory_MP_ValidateReasonCodes" data-rftabindex="3">[DATAOPTIONS_ReasonCodes]</select>
          </div>
        </div>
        <div class="row">
          <div class="col-md-5 col-sm-5 col-xs-5">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="Inventory_MP_AddInv_Confirm">Submit</button>
          </div>
          <div class="col-md-5 col-sm-5 col-xs-5" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
            <button type="button" class="amf-button amf-button-fullwidth"
            data-rfclickhandler="Inventory_MP_RefreshGrid">Cancel</button>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-7 col-sm-12 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
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
            <div class="col-md-12 col-sm-12 col-xs-12">
              <h3 class="amf-datacard-title">SKU List</h3>
              <div class="table-responsive">
                <table class="table scroll table-striped table-bordered js-datatable-loc-details">
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
