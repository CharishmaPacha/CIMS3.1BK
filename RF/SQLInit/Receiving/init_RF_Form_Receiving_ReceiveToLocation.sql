/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/08/26  RV      Added the custom validation method to submit button (HA-1179)
  2020/07/13  RKC     Hide LPNsReceived (HA-397)
  2020/06/08  RIA     Added hidden input to get current SKUs sortorder (HA-491)
  2020/05/17  RIA     Integrated with Quantity Input Panel (HA-491)
  2020/05/13  AY      Show InventoryClass1 (LabelCode) (HA-???)
  2020/05/11  RIA     Changes to show location that is scanned initially (HA-396)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/03/17  RIA     Initial Revision(CIMSV3-755)
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

/*------------------------------------------------------------------------------*/
select @vFormName = 'Receiving_ReceiveToLoc';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Receive To Loc', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Receive To Loc</span>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-menu-open"><i class="amfi-menu"></i></span></a>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFReceiving"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfshowpreprocess="Receiving_ReceiveToLocation_OnShow">
  <div class="amf-form-menu">
    <a class="amf-form-menu-close" >&times;</a>
    <button type="button" class="btn btn-info js-receivetoloc-scanmode" id="ScanMode"
    data-rfclickhandler="Receiving_ReceiveToLocation_OnScanModeClick">Mode: Scan Each SKU</button>
    <br/><br/>
    <button type="button" class="btn btn-info js-receivetoloc-suggestedmode" id="SuggestedMode"
    data-rfclickhandler="Receiving_ReceiveToLocation_OnSuggestedModeClick">Mode: Suggest Next SKU</button>
  </div>
  <input type="hidden" data-rfname="ValidateOption" value="V" />
  <input type="hidden" data-rfname="Operation" value="ReceiveToLocation" />
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
  data-rfmodelvalueprefix="ReceiptDetails" />
  <div class="container">
    <div class="row">
      <div class="col-md-5 col-xs-12 amf-full-width-responsive">
        <div class="row">
          <div class="col-md-12 col-xs-12 amf-full-width-responsive">
            <div class="form-group">
              <input class="amf-input-details js-receivetoloc-sku" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKUUPC_PH]"
              data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value=""
              data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Receiving_ReceiveToLocation_OnSKUEnter"
              data-rfsubmitform="false" data-rftabindex="1" data-rfinputtype="SCANNER">
              <label for="SKU">[FIELDCAPTION_SKU]</label>
            </div>
          </div>' +
          QIP.RawHtml +
'         <div class="col-md-12 col-xs-12 amf-datacard-Location-input hidden">
            <div class="form-group hidden">
              <input class="amf-input-details" type="text" name="SortOrder" id="SortOrder"
              data-rfname="SortOrder" data-displaycaption="" value="">
              <label for="SortOrder">[FIELDCAPTION_SortOrder]</label>
            </div>
            <div class="form-group">
              <input class="amf-input-details" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanLocation_PH]"
              data-rfname="Location" data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_ReceivingLocation]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
               data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_ReceivingLocation]"
              data-rftabindex="11" data-rfinputtype="SCANNER">
              <label for="Location">[FIELDCAPTION_Location]</label>
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
            <div class="col-md-6 col-xs-6 amf-border-separate hidden">
              <label class="col-form-label">[FIELDCAPTION_LPNsReceived]</label>
              <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_LPNsReceived]</span>
            </div>
            <div class="col-md-6 col-xs-6">
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
