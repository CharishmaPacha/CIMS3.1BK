/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  RIA     Included InventoryClass1 (HA-1794)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/04/12  AY      Use Common_QuantityInputPanel
  2020/04/11  RIA     Changes to form to show radio group and also case qty panel (CIMSV3-812)
  2019/10/22  RIA     Changes to not send data table and to bind data (CIMSV3-634)
  2019/08/19  RIA     Added complete button (CID-948)
  2019/08/17  RIA     Initial Revision(CID-948)
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

/* Change the default OnChange methods for AddSKUtoLPN form */
update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectCases_OnChange', 'Inventory_AddSKUToLPN_SelectCases_Onchange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectEaches_OnChange', 'Inventory_AddSKUToLPN_SelectEaches_Onchange');

/*------------------------------------------------------------------------------*/
select @vFormName = 'Inventory_AddSKUToLPN';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Add SKU To LPN', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Add Inventory to LPN</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfshowpreprocess="Inventory_AddSKUToLPN_OnShow">
  <input type="hidden" data-rfname="Operation" value="AddSKUToLPN" />
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
  data-rfmodelvalueprefix="LPNDETAILS,InventoryClass1" />
  <div class="container">
    <div class="row">
      <div class="col-md-6 col-xs-12 amf-form-input-responsive-width">
        <div class="form-group">
          <input class="amf-input-details" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
          data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_LPNInfo_LPN]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
          data-rfsubmitform="true" data-rftabindex="1"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LPNInfo_LPNId]"
          data-rfinputtype="SCANNER">
          <label for="LPN">[FIELDCAPTION_LPN]<sup style="color:red;">*</sup></label>
        </div>
        <div class="amf-datacard-container" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
          <div class="form-group">
            <input  class="amf-input-value" type="text" name="SKU" id="SKU" placeholder="Scan SKU"
            data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value="[FIELDVALUE_SKUInfo_SKU]"
            data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
            data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_SKUInfo_SKU]"
            data-rfsubmitform="true" data-rftabindex="2" data-rfinputtype="SCANNER">
            <label for="SKU">[FIELDCAPTION_SKU]<sup style="color:red;">*</sup></label>
          </div>
        </div>' +
        QIP.RawHtml +
'       <div class="row" data-rfvisibility="COMPAREWITH"
        data-rfvisiblevalue="[FIELDVALUE_InventoryClass]" data-rfvisiblecomparewith="InvClass1">
          <div class="col-md-12 col-xs-12">
            <div class="form-group">
              <div class="amf-form-input-responsive-width">
                <label class="col-form-label">[FIELDCAPTION_InventoryClass1]</label>
                <select class="form-control" data-rfname="InventoryClass1"
                data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
                data-rfvalidationhandler="Inventory_MP_ValidateInvClass1" data-rftabindex="11">[DATAOPTIONS_InventoryClass1]</select>
              </div>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="form-group">
              <button type="button" class="btn btn-primary amf-form-submit"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="form-group" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
              <button type="button" class="btn btn-primary amf-form-submit" data-rfclickhandler="Inventory_AddSKUToLPN_Complete">Complete</button>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-6 col-xs-12 amf-form-input-responsive-width" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <h3 class="amf-datacard-title">LPN Contents</h3>
            </div>
          </div>
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <div class="table-responsive">
                <table class="table scroll table-striped table-bordered js-datatable-content-details">
                  <thead>
                    <tr>
                      <th>[FIELDCAPTION_SKU]</th>
                      <th>[FIELDCAPTION_SKUDescription]</th>
                      <th hidden>[FIELDCAPTION_InnerPacks]</th>
                      <th>[FIELDCAPTION_Quantity]</th>
                    </tr>
                  </thead>
                  <tbody>[DATATABLE_LPNDETAILS]</tbody>
                </table>
              </div>
              <div class="amf-data-footer" style="margin-bottom:10px;">
                <p>Scanned SKUs: [FIELDVALUE_LPNInfo_NumLines]</p>
              </div>
            </div>
          </div>
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
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_PickTicket]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Wave]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_WaveNo]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumInnerPacks]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_InnerPacks]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_Quantity]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from #QtyInputPanel QIP join vwBusinessUnits BU on QIP.BusinessUnit = BU.BusinessUnit;
