/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/01  RIA     Initial Revision(HA-790)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'DropReservedPallet_Confirm';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Drop Pallet - LPN Reservation Drop', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Drop Pallet - LPN Reservation Drop</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPicking" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_DROPPALLETRESPONSEPallet]"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <div class="container">
    <input  type="hidden" data-rfname="Operation"value="DropPallet" />
    <div class="row">
      <div class="col-md-4 col-xs-5 amf-form-input-responsive-width">
        <div class="form-group">
          <input type="text" name="Pallet" placeholder="[FIELDCAPTION_AMFPalletOrCart_PH]"
          data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT"
          data-rfvalidationhandler="Picking_DropPallet_ValidatePallet"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_DROPPALLETRESPONSEPallet]"
          value="[FIELDVALUE_DROPPALLETRESPONSEPallet]" data-rftabindex="1"/>
          <label for="Pallet">[FIELDCAPTION_Pallet]</label>
        </div>
      </div>
      <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
        <div class="form-group">
          <input type="text" name="DroppedLocation" placeholder="[FIELDCAPTION_AMFDropLocation_PH]"
          data-rfname="DroppedLocation" data-displaycaption="[FIELDCAPTION_Location]"
          data-rfvalidationset="NOTNULL" data-rftabindex="2" data-rfsubmitform="true"/>
          <label for="DroppedLocation">[FIELDCAPTION_Location]</label>
        </div>
      </div>
      <div class="col-md-2 col-xs-3 amf-form-input-responsive-width">
        <div class="form-group">
          <button type="button" class="btn btn-primary amf-button-top-margin"
          data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
        </div>
      </div>
    </div>
    <div class="amf-datacard-container" style="background:none;" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_DROPPALLETRESPONSEPallet]">
      <div class="row">
        <div class="col-md-6 col-xs-12">
          <div class="amf-datacard" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_DROPPALLETRESPONSEPallet]">
            <div class="col-md-6  col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Wave]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_WaveNo]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_SKU]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_SKU]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFDropZone]</label>
              <span class="amf-display-value" style="color:#b41700">[FIELDVALUE_DROPPALLETRESPONSESuggestedDropZone]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_AMFDropLocation]</label>
              <span class="amf-display-value" style="color:#b41700">[FIELDVALUE_DROPPALLETRESPONSESuggestedDropLocation]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumLPNs]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_NumLPNs]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_NumUnits]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_Quantity]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
