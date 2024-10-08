/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/02/06  RIA     Form cleanup and changes (CID-1318)
  2019/06/21  RIA     Changes to display table info (CID-577)
  2019/05/19  RIA     Initial Revision(CID-382)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inquiry_VAS_Form';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'VAS Instructions', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">VAS Instructions</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInquiry"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="N" />
  <div class="amf-form-layout-container">
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-4 col-sm-4 col-xs-5">
            <div class="form-group">
              <input class="amf-input" type="text" name="LPN" id="LPN"
              placeholder="[FIELDCAPTION_AMFScanLPNTrkUCC_PH]" data-rfname="LPN"
              data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_LPNInfo_LPN]"
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT"
              data-rfsubmitform="true" data-rftabindex="1">
              <label for="LPN">[FIELDCAPTION_LPN]</label>
            </div>
          </div>
          <div class="col-md-2 col-sm-2 col-xs-3">
            <div class="form-group">
              <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
          <div class="col-md-2 col-sm-2 col-xs-4">
            <div class="form-group">
              <button type="button" class="amf-button amf-button-confirm amf-button-fullwidth amf-button-top-margin" data-rfclickhandler="InquiryVAS_Complete">Completed</button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-display-panel" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_PickTicket]">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-6 col-sm-12 col-xs-12">
              <div class="table-responsive">
                <table class="table scroll table-striped table-bordered">
                  <thead>
                    <tr>
                      <th hidden>[FIELDCAPTION_SKUId]</th>
                      <th>[FIELDCAPTION_SKU]</th>
                      <th>[FIELDCAPTION_Description]</th>
                      <th>[FIELDCAPTION_Quantity]</th>
                    </tr>
                  </thead>
                  <tbody>
                   [DATATABLE_LPNDETAILS]
                  </tbody>
                </table>
              </div>
              <div class="amf-mb-10"></div>
            </div>
            <div class="col-md-6 col-sm-12 col-xs-12">
              <div class="amf-datacard amf-mb-10">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_LPN]</label>
                  <span class="amf-display-value" placeholder="[AMFScanLPNTrkUCC_PH]">[FIELDVALUE_LPNInfo_LPN]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_Status]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPNStatusDesc]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_SalesOrder] / [FIELDCAPTION_PickTicket]</label>
                  <span class="amf-display-value">[FIELDVALUE_SalesOrder] / [FIELDVALUE_PickTicket]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_ShipFrom]</label>
                  <span class="amf-display-value">[FIELDVALUE_ShipFromName]</span>
                  <span class="amf-display-value">[FIELDVALUE_ShipFromAddressLine1]</span>
                  <span class="amf-display-value">[FIELDVALUE_ShipFromAddressLine2]</span>
                  <span class="amf-display-value">[FIELDVALUE_ShipFromCityStateZip]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_ShipTo]</label>
                  <span class="amf-display-value">[FIELDVALUE_ShipToCustomerName]</span>
                  <span class="amf-display-value">[FIELDVALUE_ShipToAddressLine1]</span>
                  <span class="amf-display-value">[FIELDVALUE_ShipToAddressLine2]</span>
                  <span class="amf-display-value">[FIELDVALUE_ShipToCityStateZip]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <span class="amf-display-value">[FIELDVALUE_OH_UDF2]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <span class="amf-display-value">[FIELDVALUE_OH_UDF3]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <span class="amf-display-value">[FIELDVALUE_SoldToId]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <span class="amf-display-value">[FIELDVALUE_ShipToCustomerName]</span>
                </div>
              </div>
              <div class="amf-datacard" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Comments]">
                <div class="col-md-12 col-sm-12 col-xs-12">
                  <span class="amf-display-value">[FIELDVALUE_Comments]</span>
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
