/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/22  RIA     Changed the order to show counts in data table (CIMSV3-828)
  2020/06/23  YJ      Removed PickTicket from the panel, added AMFSKUDescription to show in the grid for ReceiptOrder Inquiry (CIMSV3-828)
  2020/06/23  YJ      Changes to show QtyOrdered, QtyReceived for ReceiptOrder Inquiry (CIMSV3-828)
  2020/06/05  YJ      DataTableSKUDetails 'AvailableQty', 'ReservedQty' Added changes
                      to get QtyOrdered, QtyReceived for ReceiptOrder Inquiry (CIMSV3-828)
  2020/06/03  YJ      Changed FieldValues to return as per xmlReceiptInfo (CIMSV3-828)
  2020/05/28  RIA     Clean up and alignment changes (CIMSV3-828)
  2020/05/18  RIA     Changes to field values (CIMSV3-828)
  2020/04/22  YJ      Initial Revision(CIMSV3-828)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inquiry_ReceiptOrder_Form';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Receipt Order Inquiry', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Receipt Order Inquiry</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInquiry"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y" />
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-6 col-xs-12">
            <div class="row">
              <div class="col-md-8 col-xs-7">
                <div class="form-group">
                  <input class="amf-input" type="text" name="ReceiptNumber" id="ReceiptNumber"
                  placeholder="[FIELDCAPTION_AMFScanReceipt_PH]" data-rfname="ReceiptNumber"
                  data-displaycaption="[FIELDCAPTION_ReceiptNumber]" value="[FIELDVALUE_ReceiptInfo_ReceiptNumber]"
                  data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="1" />
                  <label for="ReceiptNumber">[FIELDCAPTION_ReceiptNumber]</label>
                </div>
              </div>
              <div class="col-md-4 col-xs-5">
                <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
                 data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
              </div>
            </div>
          </div>
          <div class="col-md-6 col-xs-12">
            <div class="amf-datacard-container" style="background:none;"
              data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_ReceiptInfo_ReceiptNumber]">
              <div class="amf-datacard">
                <div class="col-md-8 col-xs-8 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_ReceiptNumber]</label>
                  <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_ReceiptTypeDesc] [FIELDVALUE_ReceiptInfo_ReceiptNumber]</span>
                </div>
                <div class="col-md-4 col-xs-4">
                  <label class="col-form-label">[FIELDCAPTION_Status]</label>
                  <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_ReceiptStatusDesc]</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-display-panel" style="background:none; display: none;"
     data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_ReceiptInfo_ReceiptNumber]">
        <div class="amf-form-panel-shadow">
          <div class="amf-datacard-container" >
            <div class="row">
              <div class="col-md-6 col-xs-12">
                <div class="table-responsive">
                  <table class="table scroll table-striped table-bordered">
                    <thead>
                      <tr>
                        <th>[FIELDCAPTION_SKU]</th>
                        <th>[FIELDCAPTION_AMFSKUDescription]</th>
                        <th hidden></th>
                        <th>[FIELDCAPTION_QtyOrdered]</th>
                        <th>[FIELDCAPTION_QtyReceived]</th>
                        <th>[FIELDCAPTION_QtyToReceive]</th>
                      </tr>
                    </thead>
                    <tbody>[DATATABLE_ReceiptDetails]</tbody>
                  </table>
                </div>
              </div>
              <div class="col-md-6 col-xs-12">
                <div class="amf-datacard">
                  <div class="col-md-6 col-xs-6">
                    <label class="col-form-label">[FIELDCAPTION_ContainerNo]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_ContainerNo]</span>
                  </div>
                  <div class="col-md-6 col-xs-6">
                    <label class="col-form-label">[FIELDCAPTION_BillNo]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_BillNo]</span>
                  </div>
                </div>
                <div class="amf-datacard">
                  <div class="col-md-6 col-xs-6 amf-border-separate">
                    <label class="col-form-label">[FIELDCAPTION_Vendor]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_VendorName]</span>
                  </div>
                  <div class="col-md-6 col-xs-6 amf-border-separate">
                    <label class="col-form-label">[FIELDCAPTION_Warehouse]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_Warehouse]</span>
                  </div>
                </div>
                <div class="amf-datacard">
                  <div class="col-md-3 col-xs-3 amf-border-separate">
                    <label class="col-form-label">[FIELDCAPTION_UnitsOrdered]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_NumUnits]</span>
                  </div>
                  <div class="col-md-3 col-xs-3 amf-border-separate">
                    <label class="col-form-label">[FIELDCAPTION_UnitsInTransit]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_UnitsInTransit]</span>
                  </div>
                  <div class="col-md-3 col-xs-3 amf-border-separate">
                    <label class="col-form-label">[FIELDCAPTION_UnitsReceived]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_UnitsReceived]</span>
                  </div>
                  <div class="col-md-3 col-xs-3">
                    <label class="col-form-label">[FIELDCAPTION_QtyToReceive]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_QtyToReceive]</span>
                  </div>
                </div>
                <div class="amf-datacard">
                  <div class="col-md-4 col-xs-4 amf-border-separate">
                    <label class="col-form-label">[FIELDCAPTION_LPNsInTransit]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_LPNsInTransit]</span>
                  </div>
                  <div class="col-md-4 col-xs-4">
                    <label class="col-form-label">[FIELDCAPTION_LPNsReceived]</label>
                    <span class="amf-display-value">[FIELDVALUE_ReceiptInfo_LPNsReceived]</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="clearfix">
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;