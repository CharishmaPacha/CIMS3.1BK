/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/03  PK      Removed ? from ConfirmQuantity caption (HA-1382)
  2020/05/05  RIA     Changes to show SKU and UPC captions (HA-414)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/02/18  RIA     Checkbox related changes (CIMSV3-721)
  2019/07/31  RIA     Changes to validate quantity and confirm qty (CID-726)
  2019/07/16  RIA     Initial Revision(CID-726)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Putaway_PutawayLPN';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Putaway LPN', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Putaway LPN</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPutaway"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="N" />
  <div class="container">
    <div class="row">
      <div class="col-md-6">
        <div class="row">
          <div class="col-md-8 col-xs-6 amf-form-input-responsive-width">
            <div class="form-group">
              <input class="amf-input-details" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
              data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_LPN]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
              data-rfsubmitform="true" data-rftabindex="1"
              data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LPNInfo_LPNId]"
              data-rfinputtype="SCANNER">
              <label for="LPN">[FIELDCAPTION_LPN]</label>
            </div>
          </div>
          <div class="col-md-4 col-xs-6 amf-form-input-responsive-width">
            <div class="form-group" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]">
              <button type="button" class="btn btn-primary amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
            <div class="form-group" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
              <button type="button" class="btn btn-primary amf-button-top-margin" style="background: #77d677 !important;
              border: 1px solid #5fbd5f !important;" data-rfclickhandler="RFConnect_Submit_Request">Confirm</button>
            </div>
          </div>
        </div>
        <div class="amf-datacard-container" style="background:none; display: none;"
        data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <div class="row">
                <div class="col-md-12 col-xs-12 amf-form-input-responsive-width" style="width:100%; float:left;outline:none;">
                  <div class="amf-checkbox-container">
                    <input type="checkbox" class="amf-checkbox amf-input-details"
                    data-rfname="ConfirmQty" data-displaycaption="[FIELDCAPTION_CheckBox]"
                    id="ConfirmQtycheck" onchange="Putaway_PALPN_ConfirmQtyCheckBox_Onchange()"
                    data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT" data-rfvalidationhandler="Putaway_PALPN_ConfirmQtyValidation">
                    <label for="ConfirmQtycheck">Confirm Quantity</label>
                  </div>
                </div>
                <div class="col-md-8 col-xs-6 amf-form-input-responsive-width">
                  <div class="form-group">
                    <input type="text" class="amf-input-details" name="ScannedLocation" id="ScannedLocation" placeholder="[FIELDCAPTION_AMFScanLocation_PH]"
                    data-rfname="ScannedLocation" data-displaycaption="[FIELDCAPTION_Location]" value=""
                    data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
                    data-rfsubmitform="true" data-rftabindex="2" data-rfinputtype="SCANNER">
                    <label for="location">[FIELDCAPTION_Location]</label>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-6">
        <div class="amf-datacard-container" style="background:none; display: none;"
        data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
          <div class="row">
            <div class="col-md-12 col-xs-12">
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
                  <label class="col-form-label">[FIELDCAPTION_AMFDestLocation]</label>
                  <span class="amf-display-value" style="color:red">[FIELDVALUE_DestLocation]</span>
                </div>
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_AMFDestZone]</label>
                  <span class="amf-display-value">[FIELDVALUE_DestZone]</span>
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
              <div class="amf-datacard" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_OrderId]" data-rfvisiblegreaterthan="0">
                <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_PickTicket]</span>
                </div>
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_WaveNo]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_WaveNo]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKU/UPC]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_SKU] / [FIELDVALUE_LPNInfo_UPC]</span>
                </div>
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_SKUDescription]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_SKUDescription]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_Location]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_Location]</span>
                </div>
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_Pallet]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_Pallet]</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
