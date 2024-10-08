/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/12/09  RIA     Initial Revision(CID-1211)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Putaway_CompleteVAS';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Complete Production', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Complete Production</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPutaway"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input type="hidden" data-rfname="Operation" value="VASComplete" />
  <div class="container">
    <div class="row">
      <div class="col-md-5 col-xs-12">
        <div class="form-group"> 
          <input class="amf-input-details" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanLocation_PH]"
          data-rfname="Location" data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_LocationInfo_Location]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
          data-rfsubmitform="true" data-rftabindex="1"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]"
          data-rfinputtype="SCANNER">
          <label for="location">[FIELDCAPTION_Location]</label>
        </div>
        <div class="amf-datacard-container">
          <div class="form-group" data-rfvisibility="GREATERTHAN" 
          data-rfvisiblevalue="[FIELDVALUE_ScannedLPNs]" data-rfvisiblegreaterthan="0"> 
            <input class="amf-input-details" type="text" name="ScannedLPNs" id="LPNs" placeholder=""
            data-rfname="ScannedLPNs" data-displaycaption="[FIELDCAPTION_ScannedLPNs]" value="[FIELDVALUE_ScannedLPNs]"
            data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]"
            <label for="LPNs">[FIELDCAPTION_AMFScannedLPNs]</label>
          </div>
          <div class="form-group" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0">
            <input class="amf-input-details" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
            data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value=""
            data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
            data-rfsubmitform="true" data-rftabindex="2"
            data-rfinputtype="SCANNER">
            <label for="LPN">[FIELDCAPTION_LPN]</label>
          </div>
        </div>
        <div class="row">
          <div class="col-md-6 col-xs-6">
            <div class="form-group">
              <button type="button" class="btn btn-primary"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-7 col-xs-12 amf-form-input-responsive-width">
        <div class="amf-datacard-container" data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <h3 class="amf-datacard-title">LPN info</h3>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
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
              <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_Quantity]</span>
            </div>
            <div class="col-md-6 col-xs-6" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_TaskId]">
              <label class="col-form-label">[FIELDCAPTION_TaskId]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_TaskId]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
              <span class="amf-display-value">[FIELDVALUE_PickTicket]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_PickBatchNo]</label>
              <span class="amf-display-value">[FIELDVALUE_WaveNo]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_SKU]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_SKU]</span>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_UPC]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_SKUDescription]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_SKUDescription]</span>
            </div>
          </div>
        </div>
        <div class="amf-datacard-container" data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_LocationInfo_LocationId]" data-rfvisiblegreaterthan="0" style="margin-top:15px">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <h3 class="amf-datacard-title">Location Information</h3>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_LocationType]/[FIELDCAPTION_StorageType]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationTypeDesc] / [FIELDVALUE_LocationInfo_StorageTypeDesc]</span>
            </div>
            <div class="col-md-6 col-xs-6">
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
              <label class="col-form-label">[FIELDCAPTION_PickZone]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_PickingZoneDesc]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_PutawayZone]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_PutawayZoneDesc]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
