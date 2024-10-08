/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/26  RIA     Initial Revision (HA-2087)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Shipping_CancelShipCartons';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Cancel Ship Cartons', 'STD', BusinessUnit,
'
<!-- Page header -->
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Cancel Ship Cartons</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFShipping"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<!-- Page header -->
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input type="hidden" data-rfname="Operation" value="CancelCartonActivation" >
    <!-- Input Panel -->
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row" hidden>
          <div class="col-md-8 col-sm-8  col-xs-7">
            <div class="form-group">
              <input class="amf-input" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanLocation_PH]"
              data-rfname="Location" data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_LocationInfo_Location]"
              data-rfsubmitform="false">
              <label for="Location">[FIELDCAPTION_Location]</label>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-8 col-sm-8 col-xs-7">
            <div class="form-group">
              <input class="amf-input" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFShipCarton_PH]"
              data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_LPNInfo_LPN]"
              data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LPNInfo_LPN]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit" data-rftabindex="1" data-rfinputtype="SCANNER">
              <label for="LPN">[FIELDCAPTION_AMFShipCarton]</label>
            </div>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-5">
            <div class="form-group" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPN]">
              <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
            <div class="form-group" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPN]">
              <button type="button" class="amf-button amf-button-confirm amf-button-fullwidth amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Cancel Ship Cartons</button>
            </div>
          </div>
        </div>
        <!-- Main Screen -->
        <div class="amf-datacard-container" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPN]">
          <div class="row">
            <div class="col-md-12 col-sm-12 col-xs-12">
              <h3 class="amf-data-title">Carton Contents</h3>
            </div>
          </div>
          <!-- Data Table: Carton Contents List -->
          <div class="table-responsive">
            <table class="table scroll table-striped table-bordered">
              <thead>
                <tr>
                  <th>[FIELDCAPTION_SKU]</th>
                  <th>[FIELDCAPTION_SKUDescription]</th>
                  <th hidden>[FIELDCAPTION_InnerPacks]</th>
                  <th>[FIELDCAPTION_Quantity]</th>
                </tr>
              </thead>
              <tbody>
                [DATATABLE_LPNDETAILS]
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    <!-- Info Panel -->
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-display-panel" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPN]">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_LPN]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPN]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Status]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPNStatusDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Wave]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_WaveTypeDesc] [FIELDVALUE_LPNInfo_WaveNo]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_PickTicket]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_UCCBarcode]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_UCCBarcode]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_TrackingNo]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_TrackingNo]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Account]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_AccountName]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_CustPO]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_CustPO]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ShipTo]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_ShipToName]</span>
              <span class="amf-display-value-small">[FIELDVALUE_OrderInfo_ShipToAddressLine1]</span>
              <span class="amf-display-value-small">[FIELDVALUE_OrderInfo_ShipToAddressLine2]</span>
              <span class="amf-display-value-small">[FIELDVALUE_OrderInfo_ShipToCityStateZip]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_ShipVia]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_ShipViaDesc]</span>
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