/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/17  RIA     Initial Revision
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Shipping_CaptureSerialNo';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Capture Serial No', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Capture Serial No</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFShipping"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container" data-rfsubmitpreprocess="Shipping_CaptureSerialNo_PopulateEntityInput" data-rfshowpreprocess="Shipping_CaptureSerialNo_OnShow">
    <input type="hidden" data-rfname="Operation" value="CaptureSerialNo">
    <input type="hidden" data-rfname="SerialNos">
    <input type="hidden" data-rfname="Option">
    <div class="col-md-6 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="form-group">
          <input class="amf-input" type="text" name="lpn" id="lpn" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
          data-rfname="ScannedLPN" data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_LPNInfo_LPN]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LPNInfo_LPNId]"
          data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="lpn">[FIELDCAPTION_LPN]</label>
        </div>
        <div class="amf-datacard-Radiobuttons-SelectOption hidden">
          <div class="row">
            <div class="amf-radio">
              <div class="col-md-3 col-sm-6 col-xs-6 amf-datacard-SelectRadio-Add">
                <div class="radio">
                  <input id="Add" type="radio" name="add" class="amf-input"
                  data-rfname="ConfirmAdd" value="" onchange="Shipping_CaptureSerialNo_SelectOption_Add()">
                  <label for="Add" class="radio-label">[FIELDCAPTION_Add]</label>
                </div>
              </div>
              <div class="col-md-3 col-sm-6 col-xs-6 amf-datacard-SelectRadio-replace">
                <div class="radio">
                  <input id="replace" type="radio" name="replace" class="amf-input"
                  data-rfname="ConfirmReplace" value="">
                  <label for="replace" class="radio-label">[FIELDCAPTION_Replace]</label>
                </div>
              </div>
              <div class="col-md-3 col-sm-6 col-xs-6 amf-datacard-SelectRadio-Clear">
                <div class="radio">
                  <input id="Clear" type="radio" name="clear" class="amf-input"
                  data-rfname="ConfirmClear" value="" onchange="Shipping_CaptureSerialNo_SelectOption_Clear()">
                  <label for="Clear" class="radio-label">[FIELDCAPTION_Clear]</label>
                </div>
              </div>
              <div class="col-md-3 col-sm-6 col-xs-6 amf-datacard-SelectRadio-Delete">
                <div class="radio">
                  <input id="Delete" type="radio" name="delete" class="amf-input"
                  data-rfname="ConfirmDelete" value="">
                  <label for="Delete" class="radio-label">[FIELDCAPTION_Delete]</label>
                </div>
              </div>
            </div>
          </div>
          <div class="amf-hr"></div>
        </div>
        <div class="amf-datacard-container" data-rfvisibility="GREATERTHAN"
        data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
          <div class="form-group">
            <input class="amf-input" type="text" name="serialno" id="serialno" placeholder="[FIELDCAPTION_SerialNo]"
            data-rfname="SerialNo" data-displaycaption="[FIELDCAPTION_AMFNewTracking]" value=""
            data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT"
            data-rfvalidationhandler="Shipping_CaptureSerialNo_AddToList" data-rfsubmitform="false"
            data-rftabindex="2" data-rfinputtype="SCANNER">
            <label for="serialno">[FIELDCAPTION_SerialNo]</label>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-sm-4 col-xs-4" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-4" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="Shipping_CaptureSerialNo_AddToList">Add To List</button>
          </div>
          <div class="col-md-4 col-sm-4 col-xs-4" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
            <button type="button" class="amf-button amf-button-confirm amf-button-fullwidth"
            data-rfclickhandler="Shipping_CaptureSerialNo_Confirm">Confirm</button>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-6 col-sm-12 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
      data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNId]" data-rfvisiblegreaterthan="0">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_LPN]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPN]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Status]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPNStatusDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_SKU] / [FIELDCAPTION_SKUDesc]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_SKU]</span>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_SKUDescription]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Cases] / [FIELDCAPTION_Quantity]</label>
              <span class="amf-display-value">[FIELDVALUE_LPNInfo_InnerPacks] / [FIELDVALUE_LPNInfo_Quantity]</span>
            </div>
          </div>
        </div>
        <div class="amf-mb-10"></div>
        <div class="row">
          <div class="col-md-8 col-sm-8 col-xs-8">
            <h3 class="amf-datacard-title">Serial Numbers</h3>
          </div>
        </div>
        <div class="clearfix"></div>
        <div class="table-responsive">
          <table data-rfrecordname="SerialNo" class="table scroll table-striped table-bordered js-datatable-shipping-captureserialno">
            <thead>
              <tr>
                <th data-rffieldname="SerialNo">[FIELDCAPTION_SerialNo]</th>
              </tr>
            </thead>
            <tbody>
              [DATATABLE_SerialNos]
            </tbody>
          </table>
        </div>
        <div class="clearfix"></div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
