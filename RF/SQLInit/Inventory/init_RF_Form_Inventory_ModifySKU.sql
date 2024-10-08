/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/24  RIA     Changed ISBETWEEN values for Unit Length, Width and Height (CIMSV3-1108)
  2020/11/13  RIA     Used latest classes for margins and panels (CIMSV3-1108)
  2020/11/10  RIA     Added background and made partitions (CIMSV3-1108)
  2020/10/20  RIA     Clean up and integrated the SKUInfoPanel (CIMSV3-1108)
  2020/10/01  RIA     Initial Revision(CIMSV3-1108)
------------------------------------------------------------------------------*/

declare @vFormName           TName,
        @vQtyInputPanelName  TName,
        @vSKUPanelName       TName,
        @vQtyInputPanelHTML  TVarchar,
        @vSKUPanelHTML       TVarchar;

/*------------------------------------------------------------------------------*/
select @vSKUPanelName      = 'Common_SKUInfoPanel';

/* Drop temp table for SKUInfoPanel, if exists */
if (object_id('tempdb..#SKUInfoPanel') is not null) drop table #SKUInfoPanel;

select F.RawHtml, BU.BusinessUnit
into #SKUInfoPanel
from AMF_Forms F, vwBusinessUnits BU
where (F.FormName = @vSKUPanelName);

/*------------------------------------------------------------------------------*/
select @vFormName = 'Inventory_ModifySKU';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'SKU Setup', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">SKU Setup</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input  type="hidden" data-rfname="Operation" value="ModifySKU" />
  <div class="amf-datacard-container">
    <div class="container">
      <div class="row">
        <div class="col-md-6 col-xs-12 amf-form-input-panel">
          <div class="amf-form-panel-shadow">
            <div class="row">
              <div class="col-md-6 col-sm-6 col-xs-12">
                <div class="form-group">
                  <input class="amf-input-details" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKUUPC_PH]"
                  data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value="[FIELDVALUE_SKUInfo_SKU]"
                  data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="1">
                  <label for="SKU">[FIELDCAPTION_SKU]</label>
                </div>
              </div>
              <div class="col-md-3 col-sm-3 col-xs-6">
                <div class="form-group">
                  <button type="button" class="btn btn-primary amf-button-top-margin"
                  data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
                </div>
              </div>
              <div class="col-md-3 col-sm-3 col-xs-6">
                <div class="form-group" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]"
                data-rfvisiblegreaterthan="0">
                  <button type="button" class="btn btn-primary amf-button-top-margin"
                  style="background: #77d677 !important; border: 1px solid #5fbd5f !important;"
                  data-rfclickhandler="ModifySKU_Confirm">Modify</button>
                </div>
              </div>
            </div>
            <div class="row" style="margin-bottom:10px;" data-rfvisibility="GREATERTHAN"
            data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
                    ' +
              SIP.RawHtml +
  '         </div>
            <div class="row" data-rfvisibility="GREATERTHAN"
            data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
              <label class="col-form-label col-xs-12" style="font-size:17px;">Dimensions ([FIELDCAPTION_DimensionStdUoM])</label>
              <div class="amf-mb-10"></div>
              <div class="col-md-4 col-xs-4 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_UnitLength]</label>
                <div class="clearfix"></div>
                <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
                data-rfname="UnitLength" data-displaycaption="[FIELDCAPTION_UnitLength]" value="[FIELDVALUE_SKUInfo_UnitLength]" data-rftabindex="2" style="width:100%"
                data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="0,100"
                id="UnitLength">
              </div>
              <div class="col-md-4 col-xs-4 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_UnitWidth]</label>
                <div class="clearfix"></div>
                <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
                data-rfname="UnitWidth" data-displaycaption="[FIELDCAPTION_UnitWidth]" value="[FIELDVALUE_SKUInfo_UnitWidth]" data-rftabindex="3" style="width:100%"
                data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="0,100"
                id="UnitWidth">
              </div>
              <div class="col-md-4 col-xs-4">
                <label class="col-form-label">[FIELDCAPTION_UnitHeight]</label>
                <div class="clearfix"></div>
                <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
                data-rfname="UnitHeight" data-displaycaption="[FIELDCAPTION_UnitHeight]" value="[FIELDVALUE_SKUInfo_UnitHeight]" data-rftabindex="4" style="width:100%"
                data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="0,100"
                id="UnitHeight">
              </div>
            </div>
            <div class="amf-mb-10"></div>
            <div class="row" data-rfvisibility="GREATERTHAN"
            data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
              <div class="col-md-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_UnitVolume] ([FIELDCAPTION_VolumeStdUoMShort])</label>
                <div class="clearfix"></div>
                <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
                data-rfname="UnitVolume" data-displaycaption="[FIELDCAPTION_UnitVolume]" value="[FIELDVALUE_SKUInfo_UnitVolume]" data-rftabindex="5" style="width:100%"
                data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="0,99999"
                id="UnitVolume">
              </div>
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_UnitWeight] ([FIELDCAPTION_WeightStdUoM])</label>
                <div class="clearfix"></div>
                <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
                data-rfname="UnitWeight" data-displaycaption="[FIELDCAPTION_UnitWeight]" value="[FIELDVALUE_SKUInfo_UnitWeight]" data-rftabindex="6" style="width:100%"
                data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="0,99999"
                id="UnitWeight">
              </div>
            </div>
            <div class="amf-mb-10"></div>
            <div class="amf-datacard amf-background-none" data-rfvisibility="GREATERTHAN"
            data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
              <div class="row">
                <div class="col-form-label col-xs-12" style="font-size:17px;">Pack Configuration</div>
                <div class="amf-mb-10"></div>
                <div class="col-md-4 col-sm-4 col-xs-4 amf-border-separate"
                data-rfnumberinputhandler="ModifySKU_ChangeInIPPerLPN_OnClick">
                  <label>[FIELDCAPTION_InnerPacksPerLPN]</label>
                  <div class="clearfix"></div>
                  <span class="amf-form-number-input-decrement" style="font-size:30px">-</span>
                  <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
                  data-rfname="InnerPacksPerLPN" data-displaycaption="[FIELDCAPTION_InnerPacksPerLPN]" value="[FIELDVALUE_SKUInfo_InnerPacksPerLPN]" data-rftabindex="7" size="5"
                  data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="0,99999"
                  id="InnerPacksPerLPN" onchange="ModifySKU_ComputeUnitsPerLPN()"><span class="amf-form-number-input-increment" style="font-size:30px">+</span>
                </div>
                <div class="col-md-4 col-sm-4 col-xs-4 amf-border-separate"
                data-rfnumberinputhandler="ModifySKU_ChangeInUnitsPerIP_OnClick">
                  <label>[FIELDCAPTION_UnitsPerInnerPack]</label>
                  <div class="clearfix"></div>
                  <span class="amf-form-number-input-decrement" style="font-size:30px">-</span>
                  <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
                  data-rfname="UnitsPerInnerPack" data-displaycaption="[FIELDCAPTION_UnitsPerInnerPack]" value="[FIELDVALUE_SKUInfo_UnitsPerInnerPack]" data-rftabindex="8" size="5"
                  data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="0,99999"
                  id="UnitsPerInnerPack" onchange="ModifySKU_ComputeUnitsPerLPN()"><span class="amf-form-number-input-increment" style="font-size:30px">+</span>
                </div>
                <div class="col-md-4 col-sm-4 col-xs-4">
                  <label>[FIELDCAPTION_UnitsPerLPN]</label>
                  <div class="clearfix"></div>
                  <span class="amf-form-number-input-decrement" style="font-size:30px">-</span>
                  <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
                  data-rfname="UnitsPerLPN" data-displaycaption="[FIELDCAPTION_UnitsPerLPN]" value="[FIELDVALUE_SKUInfo_UnitsPerLPN]" data-rftabindex="9" size="5"
                  data-rfvalidationset="ISBETWEEN" data-rfvalidation-isbetween="0,99999"
                  id="UnitsPerLPN"><span class="amf-form-number-input-increment" style="font-size:30px">+</span>
                </div>
              </div>
            </div>
            <div class="clearfix"></div>
          </div>
          <div class="amf-mb-10"></div>
        </div>
        <div class="col-md-6 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
          <div class="amf-form-panel-shadow">
            <div class="amf-datacard">
              <div class="col-md-8 col-xs-7 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_SKUDesc]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_Description]</span>
              </div>
              <div class="col-md-2 col-xs-5">
                <label class="col-form-label">[FIELDCAPTION_Status]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_StatusDescription]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-5 col-xs-5 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_SKU1]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU1]</span>
              </div>
              <div class="col-md-4 col-xs-4 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_SKU2]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU2]</span>
              </div>
              <div class="col-md-3 col-xs-3 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_SKU3]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU3]</span>
              </div>
              <div class="col-md-3 col-xs-3 amf-border-separate" hidden>
                <label class="col-form-label">[FIELDCAPTION_SKU4]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU4]</span>
              </div>
              <div class="col-md-2 col-xs-2 amf-border-separate" hidden>
                <label class="col-form-label">[FIELDCAPTION_SKU5]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU5]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_UPC]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_UPC]</span>
              </div>
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_PrimaryLocation]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_PrimaryLocation]</span>
              </div>
            </div>
            <div class="amf-datacard" hidden>
              <div class="col-md-4 col-xs-4 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_InnerPacksPerLPN]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_InnerPacksPerLPN]</span>
              </div>
              <div class="col-md-4 col-xs-4 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_UnitsPerInnerPack]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitsPerInnerPack]</span>
              </div>
              <div class="col-md-4 col-xs-4 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_UnitsPerLPN]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitsPerLPN]</span>
              </div>
            </div>
            <div class="amf-datacard" hidden>
              <div class="col-md-4 col-xs-4 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_UnitVolume] (cubic inches)</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitVolume]</span>
              </div>
              <div class="col-md-4 col-xs-4 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_UnitDimensions] L x W x H</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitDimensions]</span>
              </div>
              <div class="col-md-4 col-xs-4">
                <label class="col-form-label">[FIELDCAPTION_UnitWeight] (lbs)</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitWeight]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_ProdCategory]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_ProdCategory]</span>
              </div>
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_ProdSubCategory]</label>
                <span class="amf-display-value">[FIELDVALUE_SKUInfo_ProdSubCategory]</span>
              </div>
            </div>
            <div class="clearfix"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from #SKUInfoPanel SIP join vwBusinessUnits BU on SIP.BusinessUnit = BU.BusinessUnit;
