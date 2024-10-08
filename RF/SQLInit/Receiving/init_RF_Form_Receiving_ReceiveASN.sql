/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/05  RIA     Corrected form name and title (JL-296)
  2020/11/02  MS      Bug fix to show ReceiverNumber (JL-291)
  2020/10/27  RIA     Added Location input and corrected captions for Pallet (JL-211)
  2020/10/22  RIA     Included LPNsIntransit and LPNsReceived (JL-271)
  2020/07/22  AY      Show QtyOrdered and QtyReceived
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/03/05  RIA     Changes to form (CIMSV3-652)
  2020/02/03  RIA     Initial Revision(CIMSV3-652)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Receiving_ReceiveASN';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Receive ASN', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Receive ASN</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFReceiving"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfshowpreprocess="Receiving_ReceiveASN_OnShow">
  <input  type="hidden" data-rfname="ValidateOption" value="V" />
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
  data-rfmodelvalueprefix="ReceiptDetails" />
  <input type="hidden" data-rfname="Operation" value="ReceiveASNLPN" />
  <div class="container">
    <div class="row">
      <div class="col-md-5 col-xs-12">
        <div class="form-group">
          <input class="amf-input-value" type="text" name="ScanLPN" id="ScanLPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
          data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_LPNInfo_LPN]"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LPNInfo_LPN]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="ScanLPN">[FIELDCAPTION_LPN]</label>
        </div>
        <div class="form-group" data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_LPNInfo_DefaultQty]" data-rfvisiblegreaterthan="0">
          <div class="amf-datacard-container">
            <div class="amf-datacard">
              <div class="col-md-9 col-xs-9 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_SKU]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_SKU]</span>
                <span class="amf-display-value-small">[FIELDVALUE_LPNInfo_SKUDescription]</span>
              </div>
              <div class="col-md-3 col-xs-3">
                <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_Quantity]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-9 col-xs-9 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_AMFSuggestedPallet]</label>
                <span class="amf-display-value-medium" data-rfname="Pallet">[FIELDVALUE_LPNInfo_SuggestionDisplay]</span>
              </div>
              <div class="col-md-3 col-xs-3">
                <span class="amf-display-value-large" style="color:#b41700">[FIELDVALUE_PalletRight]</span>
              </div>
            </div>
          </div>
        </div>
        <div class="row" data-rfvisibility="COMPAREWITH"
        data-rfvisiblevalue="[FIELDVALUE_LPNInfo_IsPalletizationRequired]" data-rfvisiblecomparewith="Y">
        <div class="col-md-12 col-xs-6">
          <div class="form-group">
            <input class="amf-input-value" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanReceivingLocation_PH]"
            data-rfname="ConfirmedLocation" data-displaycaption="[FIELDCAPTION_ReceivingLocation]" value="[FIELDVALUE_LPNInfo_ReceivingLocation]"
            data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LPNInfo_ReceivingLocation]"
            data-rftabindex="2" data-rfinputtype="SCANNER">
            <label for="Location">[FIELDCAPTION_AMFReceivingLocation]</label>
          </div>
        </div>
        <div class="col-md-12 col-xs-6">
          <div class="form-group">
            <input class="amf-input-value" type="text" name="Pallet" id="Pallet" placeholder="[FIELDCAPTION_AMFScanPallet_PH]"
            data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]"
            data-rftabindex="3" data-rfinputtype="SCANNER">
            <label for="Pallet">[FIELDCAPTION_Pallet]</label>
          </div>
        </div>
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
      <div class="col-md-7 col-xs-12">
        <div class="amf-datacard-container">
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ReceiptNumber]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_ReceiptTypeDesc] [FIELDVALUE_ReceiptInfo_ReceiptNumber]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Receiver]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiverNumber]</span>
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
        <div class="row">
          <div class="col-md-12 col-xs-12">
            <h3 class="amf-datacard-title" style="margin-top:10px;">Receipt Details</h3>
          </div>
        </div>
        <div class="table-responsive">
          <table class="table scroll table-striped table-bordered">
            <thead>
              <tr>
                <th>[FIELDCAPTION_SKU]</th>
                <th>[FIELDCAPTION_Description]</th>
                <th hidden>[FIELDCAPTION_InnerPacks]</th>
                <th>[FIELDCAPTION_AMFUnitsOrdered]</th>
                <th>[FIELDCAPTION_AMFUnitsReceived]</th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th hidden></th>
                <th>[FIELDCAPTION_AMFLPNsInTransit]</th>
                <th>[FIELDCAPTION_AMFLPNsReceived]</th>
                <th>[FIELDCAPTION_AMFUnitsToReceive]</th>
              </tr>
            </thead>
            <tbody>
              [DATATABLE_ReceiptDetails]
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
