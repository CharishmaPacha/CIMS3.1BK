/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/03  RIA     Initial Revision
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Receiving_ReceiveASNLPN';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Receive ASN LPN', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Receive ASN LPN</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFReceiving"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfshowpreprocess="Receiving_ReceiveASNLPN_OnShow">
  <input type="hidden" data-rfname="Operation" value="ReceiveASNLPN" />
  <div class="container">
    <div class="row">
      <div class="col-md-5 col-xs-12">
        <div class="form-group">
          <input class="amf-input-value" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanReceivingLocation_PH]"
          data-rfname="Location" data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_ReceivingLocation]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="Location">[FIELDCAPTION_AMFReceivingLocation]</label>
        </div>
        <div class="form-group">
          <input class="amf-input-value" type="text" name="Pallet" id="Pallet" placeholder="[FIELDCAPTION_AMFScanPallet_PH]"
          data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]" value="[FIELDVALUE_ReceivingPallet]"
          data-rftabindex="2" data-rfinputtype="SCANNER">
          <label for="ScanLPN">[FIELDCAPTION_Pallet]</label>
        </div>
        <div class="form-group">
          <input class="amf-input-value" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
          data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value=""
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rftabindex="3" data-rfinputtype="SCANNER">
          <label for="ScanLPN">[FIELDCAPTION_LPN]</label>
        </div>
        <div class="row">
          <div class="col-md-4 col-xs-6">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
          <div class="col-md-4 col-xs-6">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-button-top-margin"
              data-rfclickhandler="Receiving_PauseReceiving">Pause</button>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-7 col-xs-12" data-rfvisibility="GREATERTHAN"
      data-rfvisiblevalue="[FIELDVALUE_ReceiptInfo_ReceiptId]" data-rfvisiblegreaterthan="0">
        <div class="amf-datacard-container">
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
              <label class="col-form-label">[FIELDCAPTION_Location]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_Location]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Pallet]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_Pallet]</span>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-12 col-xs-12">
            <h3 class="amf-datacard-title" style="margin-top:10px;">LPN Details</h3>
          </div>
        </div>
        <div class="table-responsive">
          <table class="table scroll table-striped table-bordered">
            <thead>
              <tr>
                <th>[FIELDCAPTION_SKU]</th>
                <th>[FIELDCAPTION_Description]</th>
                <th hidden>[FIELDCAPTION_InnerPacks]</th>
                <th>[FIELDCAPTION_Quantity]</th>
              </tr>
            </thead>
            <tbody>
              [DATATABLE_LPNDETAILS]
            </tbody>
          </table>
        </div>
        <div class="amf-datacard-container">
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ReceiptNumber]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_ReceiptTypeDesc] [FIELDVALUE_ReceiptInfo_ReceiptNumber]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Status]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_ReceiptStatusDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFToReceive]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_LPNsInTransit]  ([FIELDVALUE_ReceiptInfo_QtyToReceive])</span>
            </div>
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_LPNsReceived]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_LPNsReceived] of [FIELDVALUE_ReceiptInfo_NumLPNs]</span>
            </div>
            <div class="col-md-4 col-xs-4">
              <label class="col-form-label">[FIELDCAPTION_AMFUnitsReceived]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_UnitsReceived] of [FIELDVALUE_ReceiptInfo_NumUnits]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
