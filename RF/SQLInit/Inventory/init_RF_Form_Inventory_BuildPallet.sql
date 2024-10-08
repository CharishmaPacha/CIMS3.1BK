/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/13  RIA     Included Style, color and size along with other necessary info (HA-426)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/10/20  RIA     Changes to not send the data table (CID-947)
  2019/10/14  RIA     Corrections to form to show data correctly (CID-947)
  2019/08/19  RIA     Changes for pause build (CID-967)
  2019/08/16  RIA     Initial Revision(CID-947)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inventory_BuildPallet';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Build Pallet', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Build Pallet</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInventoryManagement"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input type="hidden" data-rfname="Operation" value="BuildPallet" />
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y"
  data-rfmodelvalueprefix="PALLETLPNS" />
  <div class="container">
    <div class="row">
      <div class="col-md-5 col-xs-12">
        <div class="form-group">
          <input class="amf-input-details" type="text" name="Pallet" id="Pallet" placeholder="[FIELDCAPTION_AMFPalletOrCart_PH]"
          data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]" value="[FIELDVALUE_PalletInfo_Pallet]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
          data-rfsubmitform="true" data-rftabindex="1"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_PalletInfo_PalletId]"
          data-rfinputtype="SCANNER">
          <label for="Pallet">[FIELDCAPTION_Pallet]</label>
        </div>
        <div class="amf-datacard-container" style="background:none;" data-rfvisibility="GREATERTHAN" data-rfvisiblevalue="[FIELDVALUE_PalletInfo_PalletId]" data-rfvisiblegreaterthan="0">
          <div class="row">
            <div class="col-md-12 col-xs-6 hidden amf-full-width-responsive">
              <div class="form-group">
                <input type="text" name="PalletSKU" id="Palletsku" placeholder="Pallet SKU" readonly value="-">
                <label for="PalletSKU">[FIELDCAPTION_PalletSKU]</label>
              </div>
            </div>
            <div class="col-md-12 col-xs-6 amf-full-width-responsive">
              <div class="form-group">
                <input type="text" name="LPNsonpallet" id="LPNsonpallet" value="[FIELDVALUE_PalletInfo_NumLPNsWithQty]"
                data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_PalletInfo_PalletId]">
                <label for="LPN-pallet">[FIELDCAPTION_AMFNumLPNsOnPallet]</label>
              </div>
            </div>
            <div class="col-md-12 col-xs-12">
              <div class="form-group">
                <input type="text" name="ScanLPN" id="scanlpn" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
                data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value=""
                data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
                data-rfsubmitform="true" data-rftabindex="2">
                <label for="ScanLPN">[FIELDCAPTION_LPN]</label>
              </div>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-xs-4 amf-full-width-responsive">
            <div class="form-group">
              <button type="button" class="btn btn-primary"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
          <div class="col-md-6 col-xs-6 amf-full-width-responsive" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_PalletInfo_PalletId]" data-rfvisiblegreaterthan="0">
            <div class="form-group">
              <button type="button" class="btn btn-primary"
              data-rfclickhandler="Inventory_BuildPallet_CompleteOrPause">Complete/Pause Build</button>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-7 col-xs-12 amf-full-width-responsive">
        <div class="amf-datacard-container" data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_PalletInfo_PalletId]" data-rfvisiblegreaterthan="0">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <h3 class="amf-datacard-title">LPNs on Pallet</h3>
            </div>
          </div>
          <div class="table-responsive">
            <table class="table scroll table-striped table-bordered">
              <thead>
                <tr>
                  <th>[FIELDCAPTION_LPN]</th>
                  <th>[FIELDCAPTION_SKU]</th>
                  <th>[FIELDCAPTION_SKUDescription]</th>
                  <th>[FIELDCAPTION_Quantity]</th>
                </tr>
              </thead>
              <tbody>[DATATABLE_PALLETLPNS]</tbody>
            </table>
          </div>
          <div class="amf-data-footer" style="margin-bottom:10px;">
            <p>Scanned LPNs: [FIELDVALUE_PalletInfo_NumLPNsWithQty]</p>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Pallet]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_Pallet]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Status]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_PalletStatusDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumLPNs] / [FIELDCAPTION_Quantity]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_NumLPNsWithQty] / [FIELDVALUE_PalletInfo_Quantity]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Location] / [FIELDCAPTION_Warehouse]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_Location] / [FIELDVALUE_PalletInfo_Warehouse]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_SKU]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_SKU]</span>
              <span class="amf-display-value-small">[FIELDVALUE_PalletInfo_DisplaySKU]</span>
              <span class="amf-display-value-small">[FIELDVALUE_PalletInfo_DisplaySKUDesc]</span>
            </div>
            <div class="col-md-6 col-xs-6" hidden>
              <label class="col-form-label">[FIELDCAPTION_SKUImage]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_SKUImage]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_SKU1]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_SKU1]</span>
            </div>
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_SKU2]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_SKU2]</span>
            </div>
            <div class="col-md-4 col-xs-4">
              <label class="col-form-label">[FIELDCAPTION_SKU3]</label>
              <span class="amf-display-value">[FIELDVALUE_PalletInfo_SKU3]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
