/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  RIA     Included STARTSWITH validation (HA-1914)
  2020/12/28  RIA     Clean up and changes (HA-1790)
  2020/06/17  SK      Updated form to include a different file value for LPN and other changes (HA-905)
  2020/05/23  SK      Initial Revision (HA-640)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Picking_ActivateShipCartons';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Activate Ship Cartons', 'STD', BusinessUnit,
'
<!-- Page header -->
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Activate Ship Cartons</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPicking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<!-- Page header -->
<div class="amf-form-layout-container" data-rfshowpreprocess="Picking_LPNActivation_InputOnShow">
  <div class="container">
    <!-- Input Panel -->
    <div class="row">
      <div class="col-md-6 col-xs-12 amf-form-input-responsive-width">
        <div class="row" hidden>
          <div class="col-md-8 col-xs-7">
            <div class="form-group">
              <input class="amf-input-details" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanLocation_PH]"
              data-rfname="Location" data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_LocationInfo_Location]"
              data-rfsubmitform="false">
              <label for="Location">[FIELDCAPTION_Location]</label>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-8 col-xs-7">
            <div class="form-group">
              <input class="amf-input-details" type="text" name="Pallet" id="Pallet" placeholder="[FIELDCAPTION_AMFScanPallet_PH]"
              data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]" value="[FIELDVALUE_PalletInfo_Pallet]"
              data-rfvalidationset="STARTSWITH" data-rfvalidation-startswith="P" data-rfvalidateon="SUBMIT" data-rftabindex="1">
              <label for="Pallet">[FIELDCAPTION_Pallet]</label>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-8 col-xs-7 amf-form-input-responsive-width">
            <div class="form-group">
              <input class="amf-input-details" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFShipCarton_PH]"
              data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_LPNInfo_LPN]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="2">
              <label for="LPN">[FIELDCAPTION_AMFShipCarton]</label>
            </div>
          </div>
          <div class="col-md-4 col-xs-5 amf-form-input-responsive-width">
            <div class="form-group" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPN]">
              <button type="button" class="btn btn-primary amf-button-top-margin"
              data-rfclickhandler="Picking_LPNActivation_OnSubmit">Submit</button>
            </div>
            <div class="form-group" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPN]">
              <button type="button" class="btn btn-primary amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request"
              style="background: #77d677 !important; border: 1px solid #5fbd5f !important;">Confirm</button>
            </div>
          </div>
        </div>

        <!-- Main Screen -->
        <div class="amf-datacard-container" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPN]">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <h3 class="amf-data-title">Carton Contents</h3>
            </div>
          </div>
          <!-- Data Table: Carton Contents List -->
          <div class="table-responsive" style="max-height:415px";>
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

      <!-- Info Panel -->
      <div class="col-md-6 col-xs-12">
        <div class="amf-datacard-container" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPN]"
        data-rfshowpreprocess="Picking_LPNActivation_InfoOnShow">
          <div class="amf-datacard">
            <div class="col-md-6  col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_LPN]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPN]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Status]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPNStatusDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Wave]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_WaveTypeDesc] [FIELDVALUE_LPNInfo_WaveNo]</span>
            </div>
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_PickTicket]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_UCCBarcode]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_UCCBarcode]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_TrackingNo]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_TrackingNo]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ShipTo]</label>
                <span class="amf-display-value">[FIELDVALUE_OrderInfo_ShipToName]</span>
                <span class="amf-display-value-small">[FIELDVALUE_OrderInfo_ShipToAddressLine1]</span>
                <span class="amf-display-value-small">[FIELDVALUE_OrderInfo_ShipToAddressLine2]</span>
                <span class="amf-display-value-small">[FIELDVALUE_OrderInfo_ShipToCityStateZip]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_ShipVia]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_ShipViaDesc]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;