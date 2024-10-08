/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  RIA     Added a button to navigate to CreateInventoryLPN (HA-1840)
  2020/09/09  RIA/SK  Changes to not allow user to key in Location value after screen 1 (HA-1405)
                      On Enter, Confirm LPN should be the default functionality 
                      Also include hidden pallet input (HA-1371)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2020/04/08  SK      Initial Revision (CIMSV3-788)
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

/* Change the default OnChange methods for ReceiveToLPN form */
update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectCases_OnChange', 'CC_ConfirmResvLocLPN_SelectCases_OnChange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectEaches_OnChange', 'CC_ConfirmResvLocLPN_SelectEaches_OnChange');

/*------------------------------------------------------------------------------*/

select @vFormName = 'Cyclecount_ConfirmReserveLocLD2';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Reserve Location Cycle Count', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Confirm Reserve Location Cycle Count - LPN</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFCycleCounting"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container" data-rfshowpreprocess="CC_ConfirmResvLocLPN_OnShow" data-rfsubmitpreprocess="CC_PopulateEntityInput">
  <input type="hidden" data-rfname="CCData"></input>
  <div class="container">
    <div class="row">
      <div class="col-md-6 col-xs-12">
        <div class="form-group">
          <input class="amf-input-details" type="text" name="Location" id="Location"
          data-rfname="Location" data-displaycaption="[FIELDCAPTION_Location]" value="[FIELDVALUE_LocationInfo_Location]"
          data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_LocationInfo_LocationId]">
          <label for="Location">[FIELDCAPTION_Location]</label>
        </div>
        <div class="form-group">
          <input type="hidden" data-rfname="Pallet" value="[FIELDVALUE_Pallet]">
        </div>
        <div class="form-group">
          <input class="amf-input-value" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
          data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]"
          data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT"
          data-rftabindex="1" data-rfinputtype="SCANNER" data-rfsubmitform="false"
          data-rfvalidationhandler="CC_ConfirmResvLocLPN_Tabulate">
          <label for="LPN">[FIELDCAPTION_LPN]</label>
        </div>'
        +QIP.RawHtml+
        '<div class="row">
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="form-group">
               <button type="button" class="btn btn-primary"
               data-rfclickhandler="CC_ConfirmCount_Stop">Stop Counting</button>
            </div>
          </div>
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="form-group">
               <button type="button" class="btn btn-primary amf-form-submit"
               data-rfclickhandler="CC_ConfirmResvLocLPN_Tabulate">Confirm LPN</button>
            </div>
          </div>
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="form-group">
               <button type="button" class="btn btn-primary amf-form-submit"
               data-rfclickhandler="CC_ReserveLoc_CreateInvLPN">Create Inv LPN</button>
            </div>
          </div>
        </div>
        <div class="row">
          <div class="col-md-4 col-xs-4 amf-form-input-responsive-width">
            <div class="amf-datacard-container">
              <div class="form-group">
                <button type="button" class="btn btn-primary"
                style="background: #77d677 !important; border: 1px solid #5fbd5f !important;"
                data-rfclickhandler="CC_ConfirmResvLocLPN_Submit">Complete Cycle Count</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-6 col-xs-12">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-12 col-xs-12">
              <h3 class="amf-datacard-title">Scanned LPNs</h3>
            </div>
          </div>
          <div class="row">
            <div class="col-md-12">
              <div class="table-responsive">
                <table  data-rfrecordname="CCTable" class="table scroll table-striped table-bordered js-datatable-cyclecount-confirmlpns">
                  <thead>
                    <tr>
                      <th data-rffieldname="LPN">[FIELDCAPTION_LPN]</th>
                      <th data-rffieldname="SKU">[FIELDCAPTION_SKU]</th>
                      <th data-rffieldname="SKUDesc">[FIELDCAPTION_SKUDescription]</th>
                      <th data-rffieldname="NewInnerPacks">[FIELDCAPTION_Cases]</th>
                      <th data-rffieldname="NewUnits">[FIELDCAPTION_Quantity]</th>
                    </tr>
                  </thead>
                  <tbody>
                    [DATATABLE_CCLPNLIST]
                  </tbody>
                </table>
              </div>
              <div class="amf-data-footer js-footer-cyclecount-confirmlpns" style="margin-bottom:10px;">
                <p>Scanned - Total LPNs: <span class="js-footer-cyclecount-NumLPNs">[FIELDVALUE_CCLPNLIST_NumLPNs]</span>,
                   Total Cases: <span class="js-footer-cyclecount-NumCases">[FIELDVALUE_CCLPNLIST_NumCases]</span>,
                   Total Units: <span class="js-footer-cyclecount-NumUnits">[FIELDVALUE_CCLPNLIST_NumUnits]</span>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'
from #QtyInputPanel QIP join vwBusinessUnits BU on QIP.BusinessUnit = BU.BusinessUnit;