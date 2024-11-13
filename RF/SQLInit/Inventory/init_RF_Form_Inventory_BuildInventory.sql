                                                                       /*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/08/22  GAG     Added Pallets and Location with Clear button, made default for ReasonCode
                      and made changes to show based on control variable (CIMSV3-3035)
  2023/08/22  VKN     Initial Revision (CIMSV3-3034)
------------------------------------------------------------------------------*/

declare @vFormName                TName,
        @vQtyInputPanelName       TName,
        @vQtyInputPanelHTML       TVarchar;

/*------------------------------------------------------------------------------*/
select @vQtyInputPanelName = 'Common_QuantityInputPanel';

  /* Drop temp table for QtyInputPanel, if exists */
  if (object_id('tempdb..#QtyInputPanel') is not null)
     drop table #QtyInputPanel;

select F.RawHtml, BU.BusinessUnit
into #QtyInputPanel
from AMF_Forms F, vwBusinessUnits BU
where (F.FormName = @vQtyInputPanelName);

/* Change the default OnChange methods for BuildInv form */
update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectCases_OnChange', 'Inventory_BuildInv_SelectCases_Onchange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectEaches_OnChange', 'Inventory_BuildInv_SelectEaches_Onchange');

/*------------------------------------------------------------------------------*/
select @vFormName = 'Inventory_BuildInventory';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Build Inventory', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Build Inventory</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);"><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container" data-rfshowpreprocess="Inventory_BuildInv_OnShow">
    <input type="hidden" data-rfname="Operation" value="BuildInvLPN">
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
    data-rfmodelvalueprefix="InventoryClass1, Ownership, Warehouse, ReasonCodes, LabelFormats" />
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-6 col-sm-6 col-xs-12">
            <div class="row">
              <div class="col-md-8 col-sm-8 col-xs-12">
                <div class="form-group">
                  <input class="amf-input" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKU_PH]" data-rfname="SKU"
                  data-displaycaption="[FIELDCAPTION_SKU]" value="[FIELDVALUE_SKUInfo_SKU]"
                  data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rfenabled="ISNULL"
                  data-rfenabledvalue="[FIELDVALUE_SKUInfo_SKU]" data-rftabindex="1" data-rfinputtype="SCANNER">
                  <label for="SKU">[FIELDCAPTION_SKU]</label>
                </div>
              </div>
              <div class="col-md-4 col-sm-4 col-xs-12">
                <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
                data-rfclickhandler="Inventory_BuildInv_Submit">Submit</button>
              </div>
            </div>
            <div class="amf-btn-top-margin"></div>
            <div class="row" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
              <div class="col-md-12 col-sm-12 col-xs-12" data-rfvisibility="COMPAREWITH"
              data-rfvisiblevalue="[FIELDVALUE_InventoryClassesUsed]" data-rfvisiblecomparewith="InvClass1">
                <label class="col-form-label">[FIELDCAPTION_InventoryClass1]</label>
                <select class="amf-dropdown-list" data-rfdefaultindex="1" data-rfname="InventoryClass1"
                data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
                data-rfvalidationhandler="Inventory_BuildInv_ValidateInvClass1"
                data-rftabindex="11">[DATAOPTIONS_InventoryClass1]</select>
              </div>
            </div>
            <div class="clearfix"></div>
            <div data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">' +
              QIP.RawHtml +
            '</div>
            <div class="row" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]"
            data-rfvisiblegreaterthan="0">
              <div class="col-md-6 col-sm-6 col-xs-12">
                <div class="form-group">
                  <input class="amf-input js-buildinv-input-pallet" type="text" name="Pallet" id="Pallet"
                  placeholder="[FIELDCAPTION_AMFScanPallet_PH]" data-rfname="Pallet"
                  data-displaycaption="[FIELDCAPTION_Pallet]" value="[FIELDVALUE_Pallet]"
                  data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Inventory_BuildInv_SetFocusToLocOrLPN"
                  data-rftabindex="12" data-rfinputtype="SCANNER">
                  <button type="button" class="amf-icon-button" data-rfcontrolselector=".js-buildinv-input-pallet"
                  data-rfclickhandler="Utility_ClearControlValue">
                  <i class="amfi-eraser"></i></button>
                  <label for="Pallet">[FIELDCAPTION_Pallet]</label>
                </div>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-12">
                <div class="form-group">
                  <input class="amf-input js-buildinv-input-location" type="text" name="Location" id="Location"
                  placeholder="[FIELDCAPTION_AMFScanLocation_PH]" data-rfname="Location"
                  data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_Location]"
                  data-rftabindex="13" data-rfinputtype="SCANNER">
                  <button type="button" class="amf-icon-button" data-rfcontrolselector=".js-buildinv-input-location"
                  data-rfclickhandler="Utility_ClearControlValue">
                  <i class="amfi-eraser"></i></button>
                  <label for="Location">[FIELDCAPTION_Location]</label>
                </div>
              </div>
            </div>
          </div>
          <div class="col-md-6 col-sm-6 col-xs-12" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
            <div class="row">
              <div class="col-md-6 col-sm-6 col-xs-12">
                <div class="form-group">
                  <input class="amf-input" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
                  data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
                  data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value="" data-rftabindex="14"
                  data-rfinputtype="SCANNER">
                  <label for="LPN">[FIELDCAPTION_LPN]</label>
                </div>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-6">
                <label>[FIELDCAPTION_NumLPNs]</label>
                <div class="clearfix"></div>
                <div class="amf-form-number-input-container js-form-number-input-container">
                  <span class="amf-form-number-input-decrement">-</span>
                  <input class="amf-form-number-input amf-form-number-input-width js-form-number-input" type="text"
                  inputmode="numeric" data-rfname="NumLPNs" data-displaycaption="[FIELDCAPTION_NumLPNs]" value="1" size="5" id="Units1"
                  data-rfvalidationset="GREATEROREQUAL" data-rfvalidation-greaterorequal="1" data-rfvalidateon="SUBMIT">
                  <span class="amf-form-number-input-increment">+</span>
                  <div class="clearfix"></div>
                </div>
              </div>
            </div>
            <div class="clearfix"></div>
            <div class="row">
              <div class="col-md-12 col-sm-12 col-sm-12">
                <label class="col-form-label">[FIELDCAPTION_ReasonCode]</label>
                <select class="amf-dropdown-list" data-rfdefaultindex="1"
                data-rfname="ReasonCode">[DATAOPTIONS_ReasonCodes]</select>
              </div>
            </div>
            <div class="row">
              <div class="col-md-6 col-sm-6 col-xs-12">
                <label class="col-form-label">[FIELDCAPTION_Ownership]</label>
                <select class="amf-dropdown-list" data-rfdefaultindex="1"
                data-rfname="Owner" data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
                data-rfvalidationhandler="Inventory_BuildInv_ValidateOwnership">[DATAOPTIONS_Ownership]</select>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-12">
                <label class="col-form-label">[FIELDCAPTION_Warehouse]</label>
                <select class="amf-dropdown-list" data-rfdefaultvalue = "[SESSIONKEY_WAREHOUSE]"
                data-rfname="Warehouse" data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
                data-rfvalidationhandler="Inventory_BuildInv_ValidateWarehouse">[DATAOPTIONS_Warehouse]</select>
              </div>
            </div>
            <div class="row">
              <div class="col-md-6 col-sm-6 col-xs-12">
                <div class="form-group">
                  <input class="amf-input" type="text" name="Reference" id="Reference" placeholder="[FIELDCAPTION_AMFEnterReference_PH]"
                  data-rfname="Reference" data-displaycaption="[FIELDCAPTION_Reference]" value=""
                  data-rfinputtype="SCANNER">
                  <label for="Reference">[FIELDCAPTION_Reference]</label>
                </div>
              </div>
              <div class="col-md-6 col-sm-6 col-xs-12">
                <label class="col-form-label">[FIELDCAPTION_LabelFormatName]</label>
                <select class="amf-dropdown-list"
                data-rfname="LabelFormatToPrint">[DATAOPTIONS_LabelFormatToPrint]</select>
              </div>
            </div>
          </div>
          <div class="clearfix"></div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from #QtyInputPanel QIP join vwBusinessUnits BU on QIP.BusinessUnit = BU.BusinessUnit;