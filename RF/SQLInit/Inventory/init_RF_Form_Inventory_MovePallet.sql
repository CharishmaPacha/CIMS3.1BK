/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/04  AY      Show SKU/SKUDesc in one panel JL-289
  2020/08/19  RIA     Clean up and changes (HA-1245)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/10/14  RIA     Changes to show NumLPNs with Qty (CID-911)
  2019/08/11  RIA     Initial Revision(CID-911)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inventory_MovePallet';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Move Pallet', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Move Pallet/Cart</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input type="hidden" data-rfname="Operation" value="MovePallet" />
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
  data-rfmodelvalueprefix="PALLETLPNS" />
  <div class="container">
    <div class="row">
      <div class="col-md-6 col-xs-12">
        <div class="row">
          <div class="col-md-8 col-xs-6 amf-form-input-responsive-width">
            <div class="form-group">
              <input class="amf-input-details" type="text" name="Pallet" id="Pallet" placeholder="[FIELDCAPTION_AMFPalletOrCart_PH]"
              data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_AMFPalletOrCart]" value="[FIELDVALUE_PalletInfo_Pallet]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
              data-rfsubmitform="true" data-rftabindex="1"
              data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_PalletInfo_PalletId]"
              data-rfinputtype="SCANNER">
              <label for="Pallet">[FIELDCAPTION_Pallet]</label>
            </div>
          </div>
          <div class="col-md-4 col-xs-6 amf-form-input-responsive-width">
            <div class="form-group" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_PalletId]">
              <button type="button" class="btn btn-primary amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
            <div class="form-group" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_PalletId]" data-rfvisiblegreaterthan="0">
              <button type="button" class="btn btn-primary amf-button-top-margin"
              style="background: #77d677 !important; border: 1px solid #5fbd5f !important;"
              data-rfclickhandler="RFConnect_Submit_Request">Confirm</button>
            </div>
          </div>
        </div>
        <div class="amf-datacard-container" style="background:none; display: none;" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_PalletId]" data-rfvisiblegreaterthan="0">
          <div class="row">
            <div class="col-md-8 col-xs-6 amf-form-input-responsive-width">
              <div class="form-group">
                <input type="text" class="amf-input-details" name="ScannedLocation" id="ScannedLocation"
                placeholder="[FIELDCAPTION_AMFScanPalletOrLoc_PH]" data-rfname="ScannedLocation" data-displaycaption="[FIELDCAPTION_AMFScanPalletOrLoc]" value=""
                data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
                data-rfsubmitform="true" data-rftabindex="2" data-rfinputtype="SCANNER">
                <label for="location">[FIELDCAPTION_AMFScanPalletOrLoc]</label>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-6 col-xs-12">
        <div class="amf-datacard-container" style="background:none; display: none;" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_PalletId]" data-rfvisiblegreaterthan="0">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <div class="amf-datacard">
                <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_Pallet]</label> <span class="amf-display-value">[FIELDVALUE_PalletInfo_Pallet]</span>
                </div>
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_Status]</label> <span class="amf-display-value">[FIELDVALUE_PalletInfo_PalletStatusDesc]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-xs-6"data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_NumLPNsWithQty]">
                  <label class="col-form-label">[FIELDCAPTION_NumLPNs]</label> <span class="amf-display-value">[FIELDVALUE_PalletInfo_NumLPNsWithQty]</span>
                </div>
                <div class="col-md-6 col-xs-6 amf-border-separate" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_Quantity]">
                  <label class="col-form-label">[FIELDCAPTION_Quantity]</label> <span class="amf-display-value">[FIELDVALUE_PalletInfo_Quantity]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-xs-6 amf-border-separate" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_Location]">
                  <label class="col-form-label">[FIELDCAPTION_Location]</label> <span class="amf-display-value">[FIELDVALUE_PalletInfo_Location]</span>
                </div>
                <div class="col-md-6 col-xs-6" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_DestZone]">
                  <label class="col-form-label">[FIELDCAPTION_DestZone]</label> <span class="amf-display-value">[FIELDVALUE_PalletInfo_DestZone]</span>
                </div>
              </div>
              <div class="amf-datacard" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_OrderId]" data-rfvisiblegreaterthan="0">
                <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_PickTicket]</label> <span class="amf-display-value">[FIELDVALUE_PalletInfo_PickTicket]</span>
                </div>
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_WaveNo]</label> <span class="amf-display-value">[FIELDVALUE_PalletInfo_WaveNo]</span>
                </div>
              </div>
              <div class="amf-datacard" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_SKU]">
                <div class="col-md-12 col-xs-12 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKU]</label>
                  <span class="amf-display-value">[FIELDVALUE_PalletInfo_SKU]</span>
                  <span class="amf-display-value">[FIELDVALUE_PalletInfo_SKUDescription]</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>'
from vwBusinessUnits;
