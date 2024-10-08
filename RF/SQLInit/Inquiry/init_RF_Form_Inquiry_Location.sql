/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/26  RIA     Changes to data table fields (OB2-1767)
  2021/01/06  NB      HTML and CSS changes for standardization(AMF-93)
  2020/08/31  RIA     Changes to show data table based on LocationType (HA-527)
  2020/08/16  YJ      Changes to use the v3 data set and it's fields (HA-527)
  2020/06/23  YJ      Changes to show SKUDescription & Label Code in one column (HA-527)
  2020/05/15  YJ      Added InvClass1 (HA-527)
  2020/04/28  SAK     Added Warehouse (HA-285)
  2019/12/03  RIA     Made changes as per standards (CIMSV3-662)
  2019/03/07  RIA     Changes to display values in data panel (CIMSV3-365)
  2019/06/17  NB      Changes to use generic css classes(CIMSV3-571)
  2019/05/17  RIA     Changes to partition the NumPallets, LPNs, InnerPacks and Units (CIMSV3-389)
  2019/03/13  NB      Initial Revision(CIMSV3-389)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inquiry_Location_Form';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Location Inquiry', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Location Inquiry</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInquiry"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input  type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y" />
    <div class="col-md-6 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-8 col-sm-8 col-xs-8">
            <div class="form-group">
              <input class="amf-input" type="text" name="location" id="location"
              placeholder="[FIELDCAPTION_AMFScanLocation_PH]" data-rfname="Location"
              data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_LocationInfo_Location]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="1">
              <label for="location">[FIELDCAPTION_Location]</label>
            </div>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-4">
              <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
                data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-display-panel" style="background:none; display: none;"
    data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-7 col-xs-12">
            <div class="table-responsive" data-rfvisibility="COMPAREWITH"
            data-rfvisiblevalue="[FIELDVALUE_DetailLevel]" data-rfvisiblecomparewith="LPN-SKU">
              <table class="table scroll table-striped table-bordered">
                <thead>
                  <tr>
                    <th>[FIELDCAPTION_LPN]</th>
                    <th>[FIELDCAPTION_SKU]</th>
                    <th>[FIELDCAPTION_AMFSKUDescription]</th>
                    <th>[FIELDCAPTION_Quantity]</th>
                    <th>[FIELDCAPTION_ReservedQty]</th>
                    <th hidden>[FIELDCAPTION_NumLPNs]</th>
                    <th>[FIELDCAPTION_Pallet]</th>
                  </tr>
                </thead>
                <tbody>
                  [DATATABLE_SKUDETAILS]
                </tbody>
              </table>
            </div>
            <div class="table-responsive" data-rfvisibility="COMPAREWITH"
            data-rfvisiblevalue="[FIELDVALUE_DetailLevel]" data-rfvisiblecomparewith="SKU-Pallet">
              <table class="table scroll table-striped table-bordered">
              <table class="table scroll table-striped table-bordered">
                <thead>
                  <tr>
                    <th hidden>[FIELDCAPTION_LPN]</th>
                    <th>[FIELDCAPTION_SKU]</th>
                    <th>[FIELDCAPTION_AMFSKUDescription]</th>
                    <th>[FIELDCAPTION_Quantity]</th>
                    <th>[FIELDCAPTION_ReservedQty]</th>
                    <th>[FIELDCAPTION_NumLPNs]</th>
                    <th>[FIELDCAPTION_Pallet]</th>
                  </tr>
                </thead>
                <tbody>
                  [DATATABLE_SKUDETAILS]
                </tbody>
              </table>
            </div>
          </div>
          <div class="col-md-5 col-xs-12">
            <div class="amf-datacard-container">
              <div class="amf-datacard">
                <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_LocationType] / [FIELDCAPTION_StorageType]</label>
                  <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationTypeDesc], [FIELDVALUE_LocationInfo_StorageTypeDesc]</span>
                </div>
                <div class="col-md-6 col-xs-6 ">
                  <label class="col-form-label">[FIELDCAPTION_Status]</label>
                  <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationStatusDesc]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-3 col-xs-3 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_NumPallets]</label>
                  <span class="amf-display-value">[FIELDVALUE_LocationInfo_NumPallets]</span>
                </div>
                <div class="col-md-3 col-xs-3 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_NumLPNs]</label>
                  <span class="amf-display-value">[FIELDVALUE_LocationInfo_NumLPNs]</span>
                </div>
                <div class="col-md-3 col-xs-3 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_NumInnerPacks]</label>
                  <span class="amf-display-value">[FIELDVALUE_LocationInfo_InnerPacks]</span>
                </div>
                <div class="col-md-3 col-xs-3">
                  <label class="col-form-label">[FIELDCAPTION_NumUnits]</label>
                  <span class="amf-display-value">[FIELDVALUE_LocationInfo_Quantity]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_PutawayZone]</label>
                  <span class="amf-display-value">[FIELDVALUE_LocationInfo_PutawayZoneDesc]</span>
                </div>
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_PickZone]</label>
                  <span class="amf-display-value">[FIELDVALUE_LocationInfo_PickingZoneDesc]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_Warehouse]</label>
                  <span class="amf-display-value">[FIELDVALUE_LocationInfo_Warehouse]</span>
                </div>
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
