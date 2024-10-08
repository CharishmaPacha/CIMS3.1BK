/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  RIA     Included InventoryClass1 (HA-1766)
  2020/10/15  RIA     Form clean up and changes to set visibility for fields in data table (HA-1569)
  2020/10/12  RIA     Initial Revision(HA-1569)
------------------------------------------------------------------------------*/

declare @vFormName           TName,
        @vQtyInputPanelName  TName,
        @vSKUPanelName       TName,
        @vQtyInputPanelHTML  TVarchar,
        @vSKUPanelHTML       TVarchar;

/*------------------------------------------------------------------------------*/
select @vSKUPanelName      = 'Common_SKUInfoPanel';

  /* Drop temp table for SKUInfoPanel, if exists */
  if (object_id('tempdb..#SKUInfoPanel') is not null)
     drop table #SKUInfoPanel;

select F.RawHtml, BU.BusinessUnit
into #SKUInfoPanel
from AMF_Forms F, vwBusinessUnits BU
where (F.FormName = @vSKUPanelName);

/*------------------------------------------------------------------------------*/
select @vFormName = 'Inquiry_SKUStyle';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'SKU - Style Inquiry', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">SKU - Style Inquiry</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInquiry"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input  type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y" />
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-6 col-xs-12">
            <div class="row">
              <div class="col-md-8 col-xs-6">
                <div class="form-group">
                  <input class="amf-input" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKUUPC_PH]"
                  data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value="[FIELDVALUE_SKUInfo_SKU]"
                  data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="1">
                  <label for="SKU">[FIELDCAPTION_SKU]</label>
                </div>
              </div>
              <div class="col-md-4 col-xs-6">
                <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
                data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
              </div>
            </div>
            <div class="row">
              <div class="col-md-8 col-xs-6">
                <div class="form-group">
                  <input class="amf-input" type="text" name="InventoryClass1" id="InventoryClass1" placeholder="[FIELDCAPTION_AMFInventoryClass1_PH]"
                  data-rfname="InventoryClass1" data-displaycaption="[FIELDCAPTION_InventoryClass1]" value="[FIELDVALUE_InventoryClass1]"
                  data-rftabindex="2">
                  <label for="InventoryClass1">[FIELDCAPTION_InventoryClass1]</label>
                </div>
              </div>
            </div>
          </div>
          <div class="col-md-6 col-xs-12" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
            <div class="row" style="margin-bottom:10px;">
                ' +
              SIP.RawHtml +
'           </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-display-panel" style="background:none;"
    data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <div class="table-responsive">
                <table class="table scroll table-striped table-bordered">
                  <thead>
                    <tr>
                      <th>[FIELDCAPTION_SKU1]</th>
                      <th>[FIELDCAPTION_SKU2]</th>
                      <th>[FIELDCAPTION_Location]</th>
                      <th>[FIELDCAPTION_Total]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size1]">[FIELDVALUE_Sizes_Size1]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size2]">[FIELDVALUE_Sizes_Size2]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size3]">[FIELDVALUE_Sizes_Size3]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size4]">[FIELDVALUE_Sizes_Size4]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size5]">[FIELDVALUE_Sizes_Size5]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size6]">[FIELDVALUE_Sizes_Size6]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size7]">[FIELDVALUE_Sizes_Size7]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size8]">[FIELDVALUE_Sizes_Size8]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size9]">[FIELDVALUE_Sizes_Size9]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size10]">[FIELDVALUE_Sizes_Size10]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size11]">[FIELDVALUE_Sizes_Size11]</th>
                      <th data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Sizes_Size12]">[FIELDVALUE_Sizes_Size12]</th>
                    </tr>
                  </thead>
                  <tbody>
                    [DATATABLE_SKUDETAILS]
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
        <div class="clearfix"></div>
      </div>
    </div>
  </div>
</div>
'
from #SKUInfoPanel SIP join vwBusinessUnits BU on SIP.BusinessUnit = BU.BusinessUnit;
