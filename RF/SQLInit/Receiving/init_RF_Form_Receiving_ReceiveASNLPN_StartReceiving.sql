/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/02/03  RIA     Initial Revision(CIMSV3-652)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Receiving_ReceiveASNLPN_StartReceiving';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Start ASN LPN Receiving', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Start ASN LPN Receiving</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFReceiving"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <div class="container">
    <input  type="hidden" data-rfname="Operation" value="ReceiveASNLPN" />
    <input  type="hidden" data-rfname="ValidateOption" value="V" />
      <div class="row">
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="Receiver" placeholder="[FIELDCAPTION_AMFScanReceiver_PH]"
            data-rfname="ReceiverNumber" data-displaycaption="[FIELDCAPTION_Receiver]" value=""
            data-rftabindex="1">
            <label for="Receiver">[FIELDCAPTION_Receiver]</label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="Receipt" placeholder="[FIELDCAPTION_AMFScanReceipt_PH]"
            data-rfname="ReceiptNumber" data-displaycaption="[FIELDCAPTION_Receipt]" value=""
            data-rftabindex="2" data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
            data-rfvalidationhandler="Receiving_ValidateInputs">
            <label for="Receipt">[FIELDCAPTION_Receipt]<sup style="color:red;">*</sup></label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="CustPO" placeholder="[FIELDCAPTION_AMFScanCustPO_PH]"
            data-rfname="CustPO" data-displaycaption="[FIELDCAPTION_CustPO]" value=""
            data-rftabindex="3">
            <label for="CustPO">[FIELDCAPTION_CustPO]</label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="Warehouse" placeholder="[FIELDCAPTION_AMFScanWarehouse_PH]"
            data-rfname="Warehouse" data-displaycaption="[FIELDCAPTION_Warehouse]" value=""
            data-rftabindex="4">
            <label for="Warehouse">[FIELDCAPTION_Warehouse]</label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="ReceivingZone" placeholder="[FIELDCAPTION_AMFScanReceivingZone_PH]"
            data-rfname="ReceivingZone" data-displaycaption="[FIELDCAPTION_ReceivingZone]" value=""
            data-rftabindex="5">
            <label for="ReceivingZone">[FIELDCAPTION_AMFReceivingZone]</label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="ReceivingLocation" placeholder="[FIELDCAPTION_AMFScanReceivingLocation_PH]"
            data-rfname="ReceivingLocation" data-displaycaption="[FIELDCAPTION_ReceivingLocation]" value=""
            data-rftabindex="6" data-rfsubmitform="true">
            <label for="ReceivingLocation">[FIELDCAPTION_AMFReceivingLocation]</label>
          </div>
        </div>
        <div class="col-md-4 col-xs-2">
          <div class="form-group">
          </div>
        </div>
        <div class="col-md-4 col-xs-8">
          <div class="form-group">
            <button type="button" class="btn btn-primary amf-form-submit"
            data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
          </div>
        </div>
        <div class="col-md-4 col-xs-2">
          <div class="form-group">
          </div>
        </div>
      </div>
  </div>
</div>
'
from vwBusinessUnits;
