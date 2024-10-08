/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/11  RIA     Changes to show total quantity and SKU (OB2-1792)
  2021/04/25  RIA     Made changes to bind values as per the standards (OB2-1769)
  2020/10/08  RIA     Caption changes and alignment changes (CIMSV3-1126)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/12/03  RIA     Made changes as per the standards (CIMSV3-662)
  2019/06/17  NB      Changes to use generic css classes(CIMSV3-571)
  2019/06/09  RIA     Changes to show primary location (CID-500)
  2019/05/12  AY      Initial Revision(CIMSV3-461)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inquiry_SKU_Form';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'SKU Inquiry', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">SKU Inquiry</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInquiry"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input  type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y">
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-6 col-sm-6 col-xs-12">
            <div class="row">
              <div class="col-md-8 col-xs-7">
                <div class="form-group">
                  <input class="amf-input" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKUUPC_PH]"
                  data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value=""
                  data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="1">
                  <label for="SKU">[FIELDCAPTION_SKU]</label>
                </div>
              </div>
              <div class="col-md-4 col-xs-5">
                <div class="form-group">
                  <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
                  data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
                </div>
              </div>
            </div>
          </div>
          <div class="col-md-6 col-sm-6 col-xs-12 amf-mt-10">
            <div class="amf-datacard-container" style="background:none; display: none;" data-rfvisibility="GREATERTHAN"
            data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
              <div class="amf-datacard">
                <div class="col-md-6 col-xs-12">
                  <div class="col-md-12">
                    <label class="col-form-label">[FIELDCAPTION_SKU]</label>
                    <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU]</span>
                  </div>
                </div>
                <div class="col-md-6 col-xs-12">
                  <div class="col-md-12" hidden>
                    <label class="col-form-label">[FIELDCAPTION_Status]</label>
                    <span class="amf-display-value">[FIELDVALUE_SKUInfo_StatusDescription]</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
    data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKUId]" data-rfvisiblegreaterthan="0">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-6 col-sm-6 col-xs-12">
              <div class="amf-datacard" hidden>
                <div class="col-md-8 col-sm-8 col-xs-8 amf-border-separate">
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_DisplaySKUDesc]</span>
                </div>
                <div class="col-md-4 col-sm-4 col-xs-4">
                  <label class="col-form-label">[FIELDCAPTION_Status]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_StatusDescription]</span>
                </div>
                <div class="amf-mb-10"></div>
              </div>
              <div class="clearfix"></div>
              <div class="row">
                <div class="col-md-12 col-sm-12 col-xs-12">
                  <h3 class="amf-datacard-title">Inventory</h3>
                </div>
              </div>
              <div class="row">
                <div class="col-md-12 col-sm-12 col-xs-12">
                  <div class="table-responsive">
                    <table class="table scroll table-striped table-bordered">
                      <thead>
                        <tr>
                          <th>[FIELDCAPTION_Location]</th>
                          <th>[FIELDCAPTION_LPN]</th>
                          <th>[FIELDCAPTION_Status]</th>
                          <th>[FIELDCAPTION_Qty]</th>
                          <th>[FIELDCAPTION_ReservedQty]</th>
                          <th>[FIELDCAPTION_Pallet]</th>
                        </tr>
                      </thead>
                      <tbody>
                        [DATATABLE_SKUDETAILS]
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
              <div class="amf-data-footer" style="margin-bottom:10px;">
                <p>[FIELDCAPTION_AMFTotalQtyResvQty]: [FIELDVALUE_TotalQuantity], [FIELDVALUE_TotalReservedQty]</p>
              </div>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-12">
              <div class="amf-datacard">
                <div class="col-md-8 col-sm-8 col-xs-8 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKUDesc]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_DisplaySKUDesc]</span>
                </div>
                <div class="col-md-4 col-sm-4 col-xs-4">
                  <label class="col-form-label">[FIELDCAPTION_Status]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_StatusDescription]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-4 col-sm-4 col-xs-4 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKU1]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU1]</span>
                </div>
                <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKU2]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU2]</span>
                </div>
                <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKU3]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU3]</span>
                </div>
                <div class="col-md-2 col-sm-2 col-xs-2"
                data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_SKUInfo_SKU4]">
                  <label class="col-form-label">[FIELDCAPTION_SKU4]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU4]</span>
                </div>
                <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate" hidden>
                  <label class="col-form-label">[FIELDCAPTION_SKU5]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_SKU5]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_UPC]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_UPC]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_PrimaryLocation]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_PrimaryLocation]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-4 col-sm-4 col-xs-4 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_InnerPacksPerLPN]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_InnerPacksPerLPN]</span>
                </div>
                <div class="col-md-4 col-sm-4 col-xs-4 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_UnitsPerInnerPack]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitsPerInnerPack]</span>
                </div>
                <div class="col-md-4 col-sm-4 col-xs-4 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_UnitsPerLPN]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitsPerLPN]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-4 col-sm-4 col-xs-12 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_UnitVolume] (cubic inches)</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitVolume]</span>
                </div>
                <div class="col-md-4 col-sm-4 col-xs-12 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_UnitDimensions] L x W x H</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitDimensions]</span>
                </div>
                <div class="col-md-4 col-sm-4 col-xs-12">
                  <label class="col-form-label">[FIELDCAPTION_UnitWeight] (lbs)</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_UnitWeight]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_ProdCategory]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_ProdCategoryDesc]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_ProdSubCategory]</label>
                  <span class="amf-display-value">[FIELDVALUE_SKUInfo_ProdSubCategoryDesc]</span>
                </div>
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
from vwBusinessUnits;
