/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/15  RKC     Changed the caption for NumUnits, NumLPNs, NumPallets (HA-2862)
  2021/03/23  RIA     Alignmebt and display changes (HA-2361)
  2021/03/19  RIA     Initial Revision(HA-2347)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inquiry_Load_Form';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Load Inquiry', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Load Inquiry</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFShipping"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container">
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y">
    <div class="col-md-7 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-6 col-sm-8 col-xs-7">
            <div class="form-group">
              <input class="amf-input" type="text" name="LoadNumber" id="LoadNumber"
              placeholder="[FIELDCAPTION_AMFScanLoad_PH]" data-rfname="LoadNumber"
              data-displaycaption="[FIELDCAPTION_LoadNumber]" value=""
              data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="1">
              <label for="LoadNumber">[FIELDCAPTION_LoadNumber]</label>
            </div>
          </div>
          <div class="col-md-3 col-sm-4 col-xs-5">
            <div class="form-group">
              <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
              data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
            </div>
          </div>
          <div class="clearfix"></div>
          <div data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_LoadInfo_LoadId]" data-rfvisiblegreaterthan="0">
            <div class="col-md-4 col-sm-4 col-xs-5">
              <div class="amf-mt-10"></div>
              <div class="amf-datacard-title">Pallets on Load</div>
            </div>
            <div class="col-md-4 col-sm-4 col-xs-5 pull-right">
              <div class="form-group">
                <input class="amf-input" type="text" name="FilterValue" id="FilterValue"
                placeholder="[FIELDCAPTION_Filter]" data-rfname="FilterValue"
                data-displaycaption="[FIELDCAPTION_Filter]" value="">
              </div>
            </div>
            <div class="clearfix"></div>
            <div class="col-md-12 col-sm-12 col-xs-12">
              <div class="table-responsive">
                <table class="table scroll table-striped table-bordered js-datatable-load-details">
                  <thead>
                    <tr>
                      <th>[FIELDCAPTION_Pallet]</th>
                      <th>[FIELDCAPTION_Status]</th>
                      <th>[FIELDCAPTION_ShipToName]</th>
                      <th>[FIELDCAPTION_CustPo]</th>
                      <th>[FIELDCAPTION_NumLPNs]</th>
                      <th>[FIELDCAPTION_Location]</th>
                    </tr>
                  </thead>
                  <tbody>[DATATABLE_LoadDetails]</tbody>
                </table>
              </div>
            </div>
          </div>
          <div class="clearfix"></div>
        </div>
      </div>
    </div>
    <div class="col-md-5 col-sm-12 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
    data-rfvisiblevalue="[FIELDVALUE_LoadInfo_LoadId]" data-rfvisiblegreaterthan="0">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_LoadNumber]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_LoadNumber]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Status]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_StatusDescription]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ClientLoad]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_ClientLoad]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Account]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_AccountName]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumOrders]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_NumOrders]</span>
            </div>
            <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFPalletsLoaded]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_PalletsLoaded]</span>
            </div>
            <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFLPNsLoaded]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_LPNsLoaded]</span>
            </div>
            <div class="col-md-3 col-sm-3 col-xs-3">
              <label class="col-form-label">[FIELDCAPTION_AMFUnitsLoaded]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_UnitsLoaded]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_ShipToDesc]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_ShipToDesc]</span>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_ShipVia]</label>
              <span class="amf-display-value">[FIELDVALUE_LoadInfo_ShipViaDescription]</span>
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
