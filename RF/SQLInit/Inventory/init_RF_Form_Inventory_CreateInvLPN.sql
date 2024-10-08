/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/05  RIA     Initial Revision(HA-1839)
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

/* Change the default OnChange methods for CreateInvLPN form */
update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectCases_OnChange', 'Inventory_CreateInvLPN_SelectCases_Onchange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectEaches_OnChange', 'Inventory_CreateInvLPN_SelectEaches_Onchange');

/*------------------------------------------------------------------------------*/
select @vFormName = 'Inventory_CreateInvLPN';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Create Inventory LPN', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Create Inventory LPN</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);"><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container" data-rfshowpreprocess="Inventory_CreateInvLPN_OnShow">
    <input type="hidden" data-rfname="Operation" value="CreateInvLPN">
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
    data-rfmodelvalueprefix="InventoryClass1, Ownership, Warehouse, ReasonCodes" />
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-6 col-sm-6 col-xs-12">
            <div class="form-group">
              <input class="amf-input-details" type="text" name="SKU" id="SKU" placeholder="Scan SKU"
              data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value="[FIELDVALUE_SKUInfo_SKU]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
              data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_SKUInfo_SKU]"
              data-rftabindex="1" data-rfinputtype="SCANNER">
              <label for="SKU">[FIELDCAPTION_SKU]</label>
            </div>' +
            QIP.RawHtml +
'           <div class="amf-btn-top-margin"></div>
            <div class="form-group" data-rfvisibility="GREATERTHAN"
            data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
              <select class="form-control" data-rfdefaultindex="1"
              data-rfname="InventoryClass1" data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
              data-rfvalidationhandler="Inventory_CreateInvLPN_ValidateInvClass1" data-rftabindex="11">[DATAOPTIONS_InventoryClass1]</select>
              <label class="col-form-label">[FIELDCAPTION_InventoryClass1]</label>
            </div>
          </div>
          <div class="col-md-6 col-sm-6 col-xs-12" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
            <div class="form-group">
              <input class="amf-input-details" type="text" name="LPN" id="LPN" placeholder="Scan LPN"
              data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value=""
              data-rftabindex="12" data-rfinputtype="SCANNER">
              <label for="LPN">[FIELDCAPTION_LPN]</label>
            </div>
            <div class="clearfix"></div>
            <div class="form-group">
              <select class="form-control"
              data-rfname="ReasonCode" data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
              data-rfvalidationhandler="Inventory_CreateInvLPN_ValidateReasonCode" data-rftabindex="13">[DATAOPTIONS_ReasonCodes]</select>
              <label class="col-form-label">[FIELDCAPTION_ReasonCode]</label>
            </div>
            <div class="row">
              <div class="col-md-6 col-sm-6 col-xs-12">
                <div class="form-group">
                  <select class="form-control" data-rfdefaultindex="1"
                  data-rfname="Owner" data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
                  data-rfvalidationhandler="Inventory_CreateInvLPN_ValidateOwnership" data-rftabindex="14">[DATAOPTIONS_Ownership]</select>
                  <label class="col-form-label">[FIELDCAPTION_Ownership]</label>
                </div>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-12">
                <div class="form-group">
                  <select class="form-control" data-rfdefaultvalue = "[SESSIONKEY_WAREHOUSE]"
                  data-rfname="Warehouse" data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
                  data-rfvalidationhandler="Inventory_CreateInvLPN_ValidateWarehouse" data-rftabindex="15">[DATAOPTIONS_Warehouse]</select>
                  <label class="col-form-label">[FIELDCAPTION_Warehouse]</label>
                </div>
              </div>
            </div>
            <div class="form-group">
              <input class="amf-input-details" type="text" name="Reference" id="Reference" placeholder="Scan Reference"
              data-rfname="Reference" data-displaycaption="[FIELDCAPTION_Reference]" value=""
              data-rftabindex="16" data-rfinputtype="SCANNER">
              <label for="Reference">[FIELDCAPTION_Reference]</label>
            </div>
          </div>
          <div class="clearfix"></div>
          <div class="col-md-4 col-xs-2"></div>
            <div class="col-md-4 col-xs-8">
              <button type="button" class="btn btn-primary amf-form-submit"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
            <div class="col-md-4 col-xs-2"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
'
from #QtyInputPanel QIP join vwBusinessUnits BU on QIP.BusinessUnit = BU.BusinessUnit;
