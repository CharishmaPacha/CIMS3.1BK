/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/27  RV      Added the custom validation method to input LPN and submit button (HA-1179)
  2020/07/20  AY      Show QtyOrdered and QtyReceived
  2020/05/15  YJ      Added InvClass1 (HA-527)
  2020/05/13  RIA     Changes to show location that is entered earlier (HA-395)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/03/16  RIA     Initial Revision(CIMSV3-754)
------------------------------------------------------------------------------*/

declare @vFormName           TName,
        @vQtyInputPanelName  TName,
        @vQtyInputPanelHTML  TVarchar;

/*------------------------------------------------------------------------------*/
select @vQtyInputPanelName = 'Common_QuantityInputPanel';

  /* Drop temp table for QtyInputPanel, if exists */
  if (object_id('tempdb..#QtyInputPanel') is not null)
     drop table #QtyInputPanel;

select F.RawHtml, BU.BusinessUnit
into #QtyInputPanel
from AMF_Forms F, vwBusinessUnits BU
where (F.FormName = @vQtyInputPanelName);

/* Change the default OnChange methods for ReceiveToLPN form */
update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectCases_OnChange', 'Receiving_ReceiveToLPN_SelectCases_Onchange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectEaches_OnChange', 'Receiving_ReceiveToLPN_SelectEaches_Onchange');

/*------------------------------------------------------------------------------*/
select @vFormName = 'Receiving_ReceiveToLPN';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Receive To LPN', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Receive To LPN</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFReceiving"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input  type="hidden" data-rfname="ValidateOption" value="V" />
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
  data-rfmodelvalueprefix="ReceiptDetails" />
  <input type="hidden" data-rfname="Operation" value="ReceiveToLPN" />
  <div class="container">
    <div class="row">
      <div class="col-md-5 col-xs-12 amf-full-width-responsive">
        <div class="row">
          <div class="col-md-12 col-xs-12 amf-full-width-responsive">
            <div class="form-group">
              <input class="amf-input-details js-receivetolpn-sku" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKUUPC_PH]"
              data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value=""
              data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Receiving_ReceiveToLPN_OnSKUEnter"
              data-rfsubmitform="false" data-rftabindex="1" data-rfinputtype="SCANNER">
              <label for="SKU">[FIELDCAPTION_SKU]</label>
            </div>
          </div>
                ' +
          QIP.RawHtml +
'         <div class="col-md-12 col-xs-12 amf-datacard-LPN-input hidden">
            <div class="form-group">
              <input class="amf-input-details js-receivetolpn-lpn" type="text" name="ScanLPN" id="ScanLPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
              data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value=""
              data-rfsubmitform="false" data-rftabindex="11" data-rfinputtype="SCANNER">
              <label for="LPN">[FIELDCAPTION_LPN]</label>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-xs-4 amf-full-width-responsive">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-form-submit"
              data-rfclickhandler="Receiving_ValidateAndSubmit">Submit</button>
            </div>
          </div>
          <div class="col-md-4 col-xs-4 amf-full-width-responsive">
            <div class="form-group">
              <button type="button" class="btn btn-primary"
              data-rfclickhandler="Receiving_PauseReceiving">Pause</button>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-7 col-xs-12 amf-full-width-responsive">
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
              <label class="col-form-label">[FIELDCAPTION_LPNsReceived]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_LPNsReceived]</span>
            </div>
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFUnitsReceived]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_UnitsReceived] of [FIELDVALUE_ReceiptInfo_NumUnits]</span>
            </div>
            <div class="col-md-4 col-xs-4">
              <label class="col-form-label">[FIELDCAPTION_AMFReceivingLocation]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceivingLocation]</span>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-12 col-xs-12">
            <h3 class="amf-datacard-title" style="margin-top:10px;">Receipt Details</h3>
          </div>
        </div>
        <div class="table-responsive" style="height:310px;">
          <table class="table scroll table-striped table-bordered js-datatable-content-details">
            <thead>
              <tr>
                <th>[FIELDCAPTION_SKU]</th>
                <th>[FIELDCAPTION_AMFSKUDescription]</th>
                <th hidden>[FIELDCAPTION_InnerPacks]</th>
                <th>[FIELDCAPTION_QtyOrdered]</th>
                <th>[FIELDCAPTION_QtyReceived]</th>
                <th>[FIELDCAPTION_QtyToReceive]</th>
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
from #QtyInputPanel QIP join vwBusinessUnits BU on QIP.BusinessUnit = BU.BusinessUnit;
