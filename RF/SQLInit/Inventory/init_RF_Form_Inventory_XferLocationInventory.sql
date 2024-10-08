/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/11/14  RIA     Initial Revision(CIMSV3-636)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inventory_XferLocationInventory';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Xfer Inventory', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Xfer Inventory</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input type="hidden" data-rfname="Action" value="Xfer" />
  <input type="hidden" data-rfname="Operation" value="TransferInventory" />
  <div class="container">
    <div class="row">
      <div class="col-md-5 col-xs-12 amf-form-input-responsive-width">
        <div class="form-group"> 
          <input class="amf-input-details" type="text" name="FromEntity" id="FromEntity" placeholder="[FIELDCAPTION_AMFScanFromLocationOrLPN_PH]" 
          data-rfname="Entity" data-displaycaption="[FIELDCAPTION_AMFLPNOrPicklane]" value="[FIELDVALUE_LocationInfo_Location]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]"
          data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="LPNOrLocation">[FIELDCAPTION_FromAMFLPNOrPicklane]</label>
        </div>
        <div class="amf-datacard-container" data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
          <div class="form-group">
            <input type="text" class="amf-input-details" name="ToEntity" id="ToEntity" placeholder="[FIELDCAPTION_AMFScanToLocationOrLPN_PH]"
            data-rfname="ToEntity" data-displaycaption="[FIELDCAPTION_AMFLPNOrPicklane]" value="[FIELDVALUE_ToEntity]"
            data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
            data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_XferInventory]"
            data-rftabindex="2" data-rfinputtype="SCANNER">
            <label for="LPNOrLoction">[FIELDCAPTION_ToAMFLPNOrPicklane]</label>
          </div>
          <div class="form-group">
            <input type="text" class="amf-input-details" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKU_PH]"
            data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value=""
            data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
            data-rfsubmitform="true" data-rftabindex="3" data-rfinputtype="SCANNER">
            <label for="SKU">[FIELDCAPTION_SKU]</label>
          </div>
          <div class="amf-datacard" style="margin-bottom:15px;">
            <div class="col-md-4 col-xs-4">
              <label class="col-form-label">[FIELDCAPTION_NumUnits]</label>
              <span class="amf-form-number-input-decrement" style="font-size:30px">-</span>
              <input type="text" inputmode="numeric" class="amf-form-number-input amf-input-number-width" style="width:87px";
              data-rfname="Quantity" data-displaycaption="[FIELDCAPTION_Quantity]" value="[FIELDVALUE_LocationInfo_Quantity]"
              data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="1,[FIELDVALUE_LocationInfo_Quantity]" data-rfvalidateon="SUBMIT"><span class="amf-form-number-input-increment" style="font-size:30px">+</span>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-form-submit"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-7 col-xs-12 amf-form-input-responsive-width"
      data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]"
      data-rfvisiblegreaterthan="0">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <h3 class="amf-datacard-title">SKU List</h3>
            </div>
          </div>
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
              <tbody>[DATATABLE_LOCLPNS]</tbody>
           </table>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_LocationType] / [FIELDCAPTION_StorageTypeDescription]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationTypeDesc] / [FIELDVALUE_LocationInfo_StorageTypeDesc]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Status]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationStatusDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-3 col-xs-3 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumSKUs]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_NumLPNs]</span>
            </div>
            <div class="col-md-3 col-xs-3 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_Quantity]</span>
            </div>
            <div class="col-md-3 col-xs-3 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ReservedQuantity]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_ReservedQty]</span>
            </div>
            <div class="col-md-3 col-xs-3">
              <label class="col-form-label">[FIELDCAPTION_DirectedQty]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_DirectedQty]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_PutawayZone]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_PutawayZone] / [FIELDVALUE_LocationInfo_PutawayZoneDesc]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_PickingZone]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_PickingZone] / [FIELDVALUE_LocationInfo_PickingZoneDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_MinReplenishLevel]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_MinReplenishLevel]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_MaxReplenishLevel]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_MaxReplenishLevel]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
