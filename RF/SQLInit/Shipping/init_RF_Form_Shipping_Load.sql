/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/01/22  RIA     Initial Revision(CIMSV3-689)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Shipping_Load';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Load Pallet/LPN', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Load Pallet/LPN</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFShipping"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input type="hidden" data-rfname="Operation" value="LoadLPNOrPallet">
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="form-group">
          <input class="amf-input" type="text" name="scanload" id="scanload" placeholder="[FIELDCAPTION_AMFScanLoad_PH]"
          data-rfname="LoadNumber" data-displaycaption="[FIELDCAPTION_Load]" value="[FIELDVALUE_LoadInfo_LoadNumber]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LoadInfo_LoadId]"
          data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="scanload">[FIELDCAPTION_Load]</label>
        </div>
        <div class="amf-datacard-container" data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_LoadInfo_LoadId]" data-rfvisiblegreaterthan="0">
          <div class="form-group">
            <input class="amf-input" type="text" name="scanlpnorpallet" id="scanlpnorpallet" placeholder="[FIELDCAPTION_AMFScanLPNOrPallet_PH]"
            data-rfname="LPNOrPallet" data-displaycaption="[FIELDCAPTION_AMFLPNOrPallet]" value=""
            data-rftabindex="2" data-rfinputtype="SCANNER"
            data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT">
            <label for="scanlpnorpallet">[FIELDCAPTION_AMFLPNOrPallet]</label>
          </div>
          <div class="form-group">
            <input class="amf-input" type="text" name="scandock" id="scandock" placeholder="[FIELDCAPTION_AMFScanDock_PH]"
            data-rfname="Dock" data-displaycaption="[FIELDCAPTION_Dock]" value=""
            data-rfsubmitform="true" data-rftabindex="3" data-rfinputtype="SCANNER"
            data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT">
            <label for="scandock">[FIELDCAPTION_Dock]</label>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-sm-4 col-xs-4">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
    data-rfvisiblevalue="[FIELDVALUE_LoadInfo_LoadId]" data-rfvisiblegreaterthan="0">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-12 col-sm-12 col-xs-12">
              <h3 class="amf-datacard-title">Load Info</h3>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ShipTo]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_ShipTo]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Dock]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_DockLocation]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Loaded]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_LoadedDisplay]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Available]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_AvailableDisplay]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-12 col-sm-12 col-xs-12">
              <label class="col-form-label">[FIELDCAPTION_TotalWeight]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_TotalWtVolDisplay]</span>
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
