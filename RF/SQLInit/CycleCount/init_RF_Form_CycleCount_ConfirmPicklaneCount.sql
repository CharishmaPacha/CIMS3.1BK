/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/16  RIA     Added OnFormShow method (CIMSV3-773)
  2020/07/07  RIA     Integrated QIP, added validations (CIMSV3-773)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/03/29  RIA     Initial Revision(CIMSV3-773)
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

/* Change the default OnChange methods for CC Picklane */
update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectCases_OnChange', 'Inventory_CCPicklane_SelectCases_Onchange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectEaches_OnChange', 'Inventory_CCPicklane_SelectEaches_Onchange');

/*------------------------------------------------------------------------------*/
select @vFormName = 'CycleCount_ConfirmPicklaneCount';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Picklane Cycle Count', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Picklane Cycle Count</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFCycleCounting"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfsubmitpreprocess="CC_PopulateEntityInput" data-rfshowpreprocess="CC_ConfirmPicklane_OnShow">
  <input type="hidden" data-rfname="CCData" />
  <div class="container">
    <div class="row">
      <div class="col-md-6 col-xs-12">
        <div class="form-group">
          <input class="amf-input-details" type="text" name="Location" id="Location" placeholder="[FIELDCAPTION_AMFScanLocation_PH]"
          data-rfname="Location" data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_LocationInfo_Location]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="Submit"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]"
          data-rfsubmitform="true" data-rftabindex="1" data-rfinputtype="SCANNER">
          <label for="Location">[FIELDCAPTION_Location]</label>
        </div>
        <div class="form-group">
          <input class="amf-input-details" type="text" name="SKU" id="SKU" placeholder="[FIELDCAPTION_AMFScanSKU_PH]"
          data-rfname="SKU" data-displaycaption="[FIELDCAPTION_SKU]" value=""
          data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT"
          data-rfvalidationhandler="CC_Picklane_OnSKUEnter" data-rfsubmitform="false"
          data-rftabindex="2" data-rfinputtype="SCANNER">
          <label for="SKU">[FIELDCAPTION_SKU]</label>
        </div>
              ' +
        QIP.RawHtml +
'       <div class="row">
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="form-group">
              <button type="button" class="btn btn-primary"
              data-rfclickhandler="CC_ConfirmCount_Stop">Stop Count</button>
            </div>
          </div>
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="form-group">
              <button type="button" class="btn btn-primary"
              data-rfclickhandler="CC_Picklane_TabulateSKU">Confirm SKU</button>
            </div>
          </div>
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="form-group">
              <button type="button" class="btn btn-primary"
              style="background: #77d677 !important; border: 1px solid #5fbd5f !important;"
              data-rfclickhandler="CC_Picklane_ConfirmCount">Confirm Count</button>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-6 col-xs-12 amf-form-input-responsive-width">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <h3 class="amf-datacard-title">SKU Information</h3>
            </div>
          </div>
          <div class="row">
            <div class="col-md-12">
              <div class="table-responsive">
                <table data-rfrecordname="CCTable" class="table scroll table-striped table-bordered js-datatable-cyclecount-confirmskus">
                  <thead>
                    <tr>
                      <th data-rffieldname="SKU">[FIELDCAPTION_SKU]</th>
                      <th data-rffieldname="SKUDescription">[FIELDCAPTION_SKUDescription]</th>
                      <th data-rffieldname="NewUnits">[FIELDCAPTION_Quantity]</th>
                    </tr>
                  </thead>
                  <tbody>[DATATABLE_CCSKULIST]</tbody>
                </table>
              </div>
              <div class="amf-data-footer" style="margin-bottom:10px;">
                <p>Scanned - Total SKUs: <span class="js-footer-cyclecount-NumSKUs">[FIELDVALUE_CCSKULIST_NumSKUs]</span>,
                   Total Units: <span class="js-footer-cyclecount-NumUnits">[FIELDVALUE_CCSKULIST_NumUnits]</span>
                </p>
              </div>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_Location]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_Location]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_Status]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationStatusDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_LocationType]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_LocationTypeDesc]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_StorageType]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_StorageTypeDesc]</span>
            </div>
          </div>
          <div class="amf-datacard">
            <div class="col-md-6 col-xs-6 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFAllowMultipleSKUs]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_AllowMultipleSKUs]</span>
            </div>
            <div class="col-md-6 col-xs-6">
              <label class="col-form-label">[FIELDCAPTION_LastCycleCounted]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_LastCycleCounted]</span>
            </div>
          </div>
          <div class="amf-datacard hidden">
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumLPNs]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_NumLPNs]</span>
            </div>
            <div class="col-md-4 col-xs-4 amf-border-separate">
              <label class="col-form-label">[FIELDCAPTION_InnerPacks]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_InnerPacks]</span>
            </div>
            <div class="col-md-4 col-xs-4">
              <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
              <span class="amf-display-value">[FIELDVALUE_LocationInfo_Quantity]</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from #QtyInputPanel QIP join vwBusinessUnits BU on QIP.BusinessUnit = BU.BusinessUnit;
