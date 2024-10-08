/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/21  RIA     Corrected field values and added comittedqty (OB2-1768)
  2021/01/06  NB      HTML and CSS changes for standardization(AMF-93)
  2020/07/05  YJ      Added FieldCaption_AMFSKUDescription (HA-527)
  2020/05/19  NB      changes to navigate to main menu on logo click (HA-535)
  2020/05/14  AY      Add InvClass (HA-527)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/12/03  RIA     Made changes as per standards (CIMSV3-662)
  2019/06/18  NB      Changes to use generic css classes(CIMSV3-571)
  2019/05/15  RIA     Initial Revision(CIMSV3-464)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inquiry_LPN_Form';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'LPN Inquiry', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="js-amf-form-backtomainmenu amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">LPN Inquiry</span>
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
        <div class="col-md-6 col-sm-6 col-xs-12">
          <div class="row">
            <div class="col-md-8 col-xs-7">
              <div class="form-group">
                <input class="amf-input" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPNTrkUCC_PH]" data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value="" data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rfsubmitform="true" data-rftabindex="1" />
                <label for="LPN">[FIELDCAPTION_LPN]</label>
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
          <div class="amf-datacard-container" style="background:none; display: none;" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNStatus]">
            <div class="amf-datacard">
              <div class="col-md-6 col-xs-12  amf-border-separate">
                <div class="col-md-12">
                  <label class="col-form-label">[FIELDCAPTION_LPN]</label>
                  <span class="amf-display-value" placeholder="[AMFScanLPNTrkUCC_PH]">[FIELDVALUE_LPNInfo_LPN]</span>
                </div>
              </div>
              <div class="col-md-6 col-xs-12">
                <div class="col-md-12">
                  <label class="col-form-label">[FIELDCAPTION_Status]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_LPNStatusDesc]</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="col-md-12 col-sm-12 col-xs-12 amf-form-display-panel" style="background:none; display: none;" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LPNStatus]">
    <div class="amf-form-panel-shadow">
      <div class="amf-datacard-container">
        <div class="row">
          <div class="col-md-6 col-xs-12">
            <div class="table-responsive">
              <table class="table scroll table-striped table-bordered">
                <thead>
                  <tr>
                    <th>[FIELDCAPTION_SKU]</th>
                    <th>[FIELDCAPTION_SKUDescription]</th>
                    <th hidden>[FIELDCAPTION_InnerPacks]</th>
                    <th>[FIELDCAPTION_Quantity]</th>
                    <th hidden>[FIELDCAPTION_Quantity1]</th>
                    <th>[FIELDCAPTION_ReservedQty]</th>
                  </tr>
                </thead>
                <tbody>[DATATABLE_LPNDETAILS]</tbody>
              </table>
            </div>
          </div>
          <div class="col-md-6 col-xs-12">
            <div class="amf-datacard">
              <div class="col-md-4 col-xs-4 amf-border-separate">
                <label class="col-form-label" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_InnerPacks]" data-rfvisibility="GREATERTHAN" data-rfvisiblegreaterthan="0">[FIELDCAPTION_InnerPacks] / </label>
                <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
                <span class="amf-display-value" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_InnerPacks]" data-rfvisibility="GREATERTHAN" data-rfvisiblegreaterthan="0">[FIELDVALUE_LPNInfo_InnerPacks] /</span>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_Quantity]</span>
              </div>
              <div class="col-md-4 col-xs-4">
                <label class="col-form-label">[FIELDCAPTION_Location] ([FIELDCAPTION_Warehouse])</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_Location] ([FIELDVALUE_LPNInfo_DestWarehouse])</span>
              </div>
              <div class="col-md-4 col-xs-4">
                <label class="col-form-label">[FIELDCAPTION_Pallet]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_Pallet]</span>
              </div>
            </div>
            <div class="amf-datacard" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_InventoryClass1]" data-rfvisibility="NOTNULL">
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_InventoryClass1]</label>
                <span class="amf-display-value">[FIELDVALUE_LPNInfo_InventoryClass1]</span>
              </div>
            </div>
            <div class="amf-datacard" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_DestZone]" data-rfvisibility="NOTNULL">
               <div class="col-md-6 col-xs-6 amf-border-separate">
                 <label class="col-form-label">[FIELDCAPTION_DestZone]</label>
                 <span class="amf-display-value">[FIELDVALUE_LPNInfo_DestZone]</span>
               </div>
               <div class="col-md-6 col-xs-6" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_DestLocation]" data-rfvisibility="NOTNULL">
                 <label class="col-form-label">[FIELDCAPTION_DestLocation]</label>
                 <span class="amf-display-value">[FIELDVALUE_LPNInfo_DestLocation]</span>
               </div>
             </div>
             <div class="amf-datacard" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_ReceiptNumber]" data-rfvisibility="NOTNULL">
               <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_ReceiptNumber]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_ReceiptNumber]</span>
                </div>
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_Receiver]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_ReceiverNumber]</span>
                </div>
              </div>
              <div class="amf-datacard" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_PickTicket]" data-rfvisibility="GREATERTHAN" data-rfvisiblegreaterthan="0">
                <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_PickTicket]</span>
                </div>
                <div class="col-md-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_Wave]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_WaveNo]</span>
                </div>
              </div>
              <div class="amf-datacard" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_PickTicket]" data-rfvisibility="GREATERTHAN" data-rfvisiblegreaterthan="0">
                <div class="col-md-12 col-xs-12 amf-border-separate">
                   <label class="col-form-label">[FIELDCAPTION_Customer]</label>
                   <span class="amf-display-value">[FIELDVALUE_LPNInfo_SoldToId] [FIELDVALUE_LPNInfo_CustomerName]</span>
                 </div>
               </div>
               <div class="amf-datacard">
                 <div class="col-md-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_TaskId]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_TaskId]</span>
                </div>
                <div class="col-md-6 col-xs-6" data-rfvisiblevalue="[FIELDVALUE_LPNInfo_LoadNumber]" data-rfvisibility="GREATERTHAN" data-rfvisiblegreaterthan="0">
                  <label class="col-form-label">[FIELDCAPTION_LoadNumber]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNInfo_LoadNumber]</span>
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
