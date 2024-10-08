/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/29  RIA     Changes to field value name (CIMSV3-622)
  2020/09/17  RIA     Changes to show captions (CIMSV3-622)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/09/06  RIA     Initial Revision(CID-996)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Packing_ClosePackage';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Close Package', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Close Package</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPacking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input  type="hidden" data-rfname="Action" value="CloseLPN">
    <input type="hidden" data-rfname="Operation" value="ClosePackage">
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="form-group">
          <input class="amf-input" type="text" name="PickTicket" id="PickTicket" placeholder="[FIELDCAPTION_AMFScanPTOrLPNOrToteOrCart_PH]"
          data-rfname="PickTicket" data-displaycaption="[FIELDCAPTION_PickTicket]" value="[FIELDVALUE_PackInfo_PickTicket]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
          data-rfsubmitform="true" data-rftabindex="1"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_OrderId]"
          data-rfinputtype="SCANNER">
          <label for="PickTicket">[FIELDCAPTION_PickTicket]</label>
        </div>
        <div class="form-group">
          <input class="amf-input" type="text" name="ToLPN" id="ToLPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]" value=""
          data-rfname="ToLPN" data-displaycaption="[FIELDCAPTION_AMFToLPN]" data-rftabindex="2">
          <label for="ToLPN">[FIELDCAPTION_AMFToLPN]</label>
        </div>
        <div class="form-group">
          <input class="amf-input" type="text" name="CartonType" id="CartonType" placeholder="[FIELDCAPTION_AMFPacking_CartonType_PH]"
          data-rfname="CartonType" data-displaycaption="[FIELDCAPTION_CartonType]"
          value="[FIELDVALUE_SuggestedCartonType]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="3">
          <label for="CartonType">[FIELDCAPTION_CartonType]<sup class="amf-mandatory-field">*</sup></label>
        </div>
        <div class="form-group">
          <input class="amf-input" type="text" name="Weight" id="Weight" placeholder="[FIELDCAPTION_AMFPacking_Weight_PH]"
          data-rfname="Weight" data-displaycaption="[FIELDCAPTION_AMFWeight]"
          value="[FIELDVALUE_EstimatedWeight]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="4">
          <label for="Weight">[FIELDCAPTION_AMFWeight]<sup class="amf-mandatory-field">*</sup></label>
        </div>
        <div class="row">
          <div class="col-md-4 col-sm-6 col-xs-6">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth" data-rfclickhandler="RFConnect_Submit_Request">Close Carton</button>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-6 col-sm-6 col-xs-12 amf-form-display-panel">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-12 col-sm-12 col-xs-12">
              <h3 class="amf-datacard-title">Order Information</h3>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFUnitsPacked]</label>
              <span class="amf-display-value">[FIELDVALUE_UnitsPacked]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_AMFSKUsPacked]</label>
              <span class="amf-display-value">[FIELDVALUE_SKUsPacked]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Customer]</label>
              <span class="amf-display-value">[FIELDVALUE_Customer]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_ShipTo]</label>
              <span class="amf-display-value">[FIELDVALUE_ShipToName]</span>
              <span class="amf-display-value-small">[FIELDVALUE_ShipToCSZ]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ShipVia]</label>
              <span class="amf-display-value">[FIELDVALUE_ShipVia]</span>
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