/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/23  RIA     Changes to form name, title, data table, data panel and cleanup and renamed methods and added SKUId (HA-832)
  2020/06/17  RIA     Initial Revision(HA-832)
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
select @vFormName = 'Misc_CompleteRework_Execute';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Complete Rework', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="js-amf-form-backtomainmenu amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Complete Rework</span>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-menu-open"><i class="amfi-menu"></i></span></a>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFMiscellaneous"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfshowpreprocess="Misc_CompleteRework_OnShow">
  <div class="amf-form-menu">
    <a class="amf-form-menu-close" >&times;</a>
    <button type="button" class="btn btn-info js-misc-completerework-scanmode" id="ScanMode"
    data-rfclickhandler="Misc_CompleteRework_OnScanModeClick">Mode: Scan Each SKU</button>
    <br/><br/>
    <button type="button" class="btn btn-info js-misc-completerework-suggestedmode" id="SuggestedMode"
    data-rfclickhandler="Misc_CompleteRework_OnSuggestedModeClick">Mode: Suggest Next SKU</button>  
  </div>
  <input type="hidden" data-rfname="Operation" value="CompleteRework" />
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
  data-rfmodelvalueprefix="ReceiptDetails" />
  <div class="container">
    <div class="row">
      <div class="col-md-5 col-xs-12 amf-full-width-responsive">
        <div class="row">
          <div class="col-md-12 col-xs-12 amf-full-width-responsive">
            <div class="form-group">
              <input class="amf-input-details js-misc-completerework-sku" type="text"
              name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKUUPC_PH]"
              data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value=""
              data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Misc_CompleteRework_OnSKUEnter"
              data-rfsubmitform="false" data-rftabindex="1" data-rfinputtype="SCANNER">
              <label for="SKU">[FIELDCAPTION_SKU]</label>
            </div>
          </div>' +
          QIP.RawHtml +
'         <div class="col-md-12 col-xs-12 hidden">
            <div class="form-group">
              <input class="amf-input-details" type="text" name="SortOrder" id="SortOrder"
              data-rfname="SortOrder" data-displaycaption="" value="">
              <label for="SortOrder">[FIELDCAPTION_SortOrder]</label>
            </div>
          </div>
          <div class="col-md-12 col-xs-12 hidden">
            <div class="form-group">
              <input class="amf-input-details" type="text" name="SKUId" id="SKUId"
              data-rfname="SKUId" data-displaycaption="" value="">
              <label for="SKUId">[FIELDCAPTION_SKUId]</label>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-xs-4 amf-full-width-responsive">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-form-submit"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
          <div class="col-md-4 col-xs-4 amf-full-width-responsive">
            <div class="form-group">
              <button type="button" class="btn btn-primary"
              data-rfclickhandler="Misc_CompleteRework_Pause">Pause</button>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-7 col-xs-12 amf-full-width-responsive">
        <div class="row">
          <div class="col-md-12 col-xs-12">
            <h3 class="amf-datacard-title" style="margin-top:10px;">Order Details</h3>
          </div>
        </div>
        <div class="table-responsive" style="margin-bottom:10px;">
          <table class="table scroll table-striped table-bordered js-datatable-content-details">
            <thead>
              <tr>
                <th>[FIELDCAPTION_SKU]</th>
                <th>[FIELDCAPTION_Description]</th>
                <th hidden>[FIELDCAPTION_InnerPacks]</th>
                <th>[FIELDCAPTION_AMFUnitsToRework]</th>
                <th>[FIELDCAPTION_NumPicksCompleted]</th>
                <th>[FIELDCAPTION_AMFUnitsRemaining]</th>
              </tr>
            </thead>
            <tbody>
              [DATATABLE_OrderDetails]
            </tbody>
          </table>
        </div>
        <div class="amf-datacard-container">
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_PickTicket]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_WaveNo]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_WaveTypeDesc] / [FIELDVALUE_OrderInfo_WaveNo]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFUnitsToRework]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_NumUnits]</span>
            </div>
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumPicksCompleted]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_UnitsAssigned]</span>
            </div>
            <div class="col-md-4 col-xs-4">
              <label class="col-form-label">[FIELDCAPTION_AMFUnitsRemaining]</label>
              <span class="amf-display-value">[FIELDVALUE_OrderInfo_UnitsToAllocate]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from #QtyInputPanel QIP join vwBusinessUnits BU on QIP.BusinessUnit = BU.BusinessUnit;
