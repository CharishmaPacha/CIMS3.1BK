/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/18  RKC     Added Complete or pause button (HA-2115)
  2020/08/06  RIA     Cleanup and changes for filter value input (HA-1263)
  2020/07/01  RIA     Added InventoryClass1, InventoryClass2, InventoryClass3 (HA-789)
  2020/06/30  RIA     Renamed the datatable to SKUDetailsToReserve (HA-789)
  2020/06/17  RIA     Cleanup and made changes to show pallet below Wave,PT (HA-789)
  2020/06/11  RIA     Added Pallet (HA-789)
  2020/05/29  RIA     Removed Reassign and added padding between tables and added  SKU as hidden input (HA-521)
  2020/05/27  RIA     Changes to SKU Info datatable and aslo to show Wave and PickTicket info in data panel (HA-521)
  2020/05/25  RIA     QIP and form changes (HA-521)
  2020/05/24  TK      WIP Changes (HA-521)
  2020/02/02  RIA     Initial Revision(CIMSV3-677)
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

/* Change the default OnChange methods for LPN Reservation form */
update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectCases_OnChange', 'Picking_LPNReservation_SelectCases_Onchange');

update #QtyInputPanel
set RawHtml = replace(RawHtml, 'SelectEaches_OnChange', 'Picking_LPNReservation_SelectEaches_Onchange');

/*------------------------------------------------------------------------------*/
select @vFormName = 'Picking_LPNReservation';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'LPN Reservation', 'STD', BU.BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="js-amf-form-backtomainmenu amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">LPN Reservation</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPicking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);"><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <div class="amf-form-layout-container" data-rfshowpreprocess="Picking_LPNReservation_OnShow">
    <input type="hidden" data-rfname="SelectedSKU">
    <input type="hidden" data-rfname="InventoryClass1">
    <input type="hidden" data-rfname="InventoryClass2">
    <input type="hidden" data-rfname="InventoryClass3">
    <div class="col-md-5 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="amf-allocate amf-reassign wave-detail-input">
          <div class="row">
            <div class="col-md-6 col-sm-6 col-xs-6">
              <div class="form-group">
                <input class="amf-input" type="text" name="WaveNo" id="WaveNo" placeholder="[FIELDCAPTION_AMFScanWaveNo_PH]"
                data-rfname="WaveNo" data-displaycaption="[FIELDCAPTION_WaveNo]" value="[FIELDVALUE_WaveInfo_WaveNo]"
                data-rftabindex="1" data-rfsubmitform="true" data-rfinputtype="SCANNER">
                <label for="WaveNo">[FIELDCAPTION_WaveNo]</label>
              </div>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <div class="form-group">
                <input class="amf-input" type="text" name="PickTicket" id="PickTicket" placeholder="[FIELDCAPTION_AMFScanPickTicket_PH]"
                data-rfname="PickTicket" data-displaycaption="[FIELDCAPTION_PickTicket]" value="[FIELDVALUE_OrderInfo_PickTicket]"
                data-rftabindex="2" data-rfinputtype="SCANNER"
                data-rfvalidationset="CUSTOM" data-rfvalidateon="SUBMIT"
                data-rfvalidationhandler="Picking_LPNReservation_ValidateInputs">
                <label for="PickTicket">[FIELDCAPTION_PickTicket]</label>
              </div>
            </div>
          </div>
        </div>
        <div class="amf-datacard-scanpallet-input hidden">
          <div class="row">
            <div class="col-md-6 col-sm-6 col-xs-6">
              <div class="form-group">
                <input class="amf-input" type="text" name="Pallet" id="Pallet" placeholder="[FIELDCAPTION_AMFScanPallet_PH]"
                data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]" value="[FIELDVALUE_LPNReservationInfo_Pallet]"
                data-rftabindex="3" data-rfinputtype="SCANNER">
                <label for="Pallet">[FIELDCAPTION_Pallet]</label>
              </div>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-6">
              <div class="form-group">
                <input class="amf-input-details" type="text" name="FilterValue" id="FilterValue" placeholder="[FIELDCAPTION_AMFScanFilterValue_PH]"
                data-rfname="FilterValue" data-displaycaption="[FIELDCAPTION_AMFFilterValue]" value="[FIELDVALUE_LPNReservationInfo_FilterValue]"
                data-rftabindex="4" data-rfinputtype="SCANNER">
                <label for="FilterSKU">[FIELDCAPTION_AMFSKUFilter]</label>
              </div>
            </div>
          </div>
        </div>
        <div class="form-group">
          <select class="amf-dropdown-list" id="select" data-rfname="AllocateOption">
            <option value="A">Allocate</option>
            <option value="U">Unallocate</option>
          </select>
        </div>
        <div class="amf-datacard-scanlpn-input hidden">
          <div class="row">
            <div class="col-md-6 col-sm-6 col-xs-12">
              <div class="form-group">
                <input class="amf-input" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFScanLPN_PH]"
                data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_LPNReservationInfo_LPN]"
                data-rfvalidationset="NOTNULL" data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Picking_LPNReservation_OnLPNEnter"
                data-rfsubmitform="false" data-rftabindex="5" data-rfinputtype="SCANNER">
                <label for="LPN">[FIELDCAPTION_LPN]</label>
              </div>
            </div>
          </div>
        </div>
        <div class="clearfix"></div>' +
        QIP.RawHtml +
        '<div class="row">
          <div class="col-md-6 col-sm-6 col-xs-6 ">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
          </div>
          <div class="col-md-6 col-sm-6 col-xs-6" data-rfvisibility="GREATERTHAN"
           data-rfvisiblevalue="[FIELDVALUE_WaveInfo_WaveId][FIELDVALUE_OrderInfo_OrderId]" data-rfvisiblegreaterthan="0">
            <button type="button" class="amf-button amf-button-submit amf-button-fullwidth"
            data-rfclickhandler="Picking_LPNReservation_CompleteOrPause">Complete / Pause</button>
          </div>
        </div>
        <div class="clearfix"></div>
      </div>
    </div>
    <div class="col-md-7 col-sm-12 col-xs-12 amf-form-display-panel" data-rfvisibility="GREATERTHAN"
    data-rfvisiblevalue="[FIELDVALUE_WaveInfo_WaveId][FIELDVALUE_OrderInfo_OrderId]" data-rfvisiblegreaterthan="0">
      <div class="amf-form-panel-shadow">
        <div class="scan-lpn datatable-unitstoreserve">
          <div class="amf-datacard-container">
            <div class="row">
              <div class="col-md-12 col-xs-12">
                <h3 class="amf-datacard-title">Inventory Needed</h3>
              </div>
            </div>
            <div class="row">
              <div class="col-md-12">
                <div class="table-responsive" style="height:200px; margin-bottom:15px;">
                  <table class="table scroll table-striped table-bordered js-datatable-content-details">
                    <thead>
                      <tr>
                        <th>[FIELDCAPTION_DisplaySKU]</th>
                        <th>[FIELDCAPTION_DisplaySKUDesc]</th>
                        <th hidden>[FIELDCAPTION_InnerPacks]</th>
                        <th>[FIELDCAPTION_QtyOrdered]</th>
                        <th>[FIELDCAPTION_QtyReserved]</th>
                        <th>[FIELDCAPTION_QtyNeeded]</th>
                      </tr>
                    </thead>
                    <tbody>
                      [DATATABLE_SKUDetailsToReserve]
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="scan-lpn datatable-availableinventory">
          <div class="amf-datacard-container">
            <div class="row">
              <div class="col-md-12 col-xs-12">
                <h3 class="amf-datacard-title">Available Inventory for [FIELDVALUE_LPNReservationInfo_SKU]</h3>
              </div>
            </div>
            <div class="row">
              <div class="col-md-12">
                <div class="table-responsive">
                  <table class="table scroll table-striped table-bordered js-datatable-available-lpns">
                    <thead>
                      <tr>
                        <th>[FIELDCAPTION_Location]</th>
                        <th>[FIELDCAPTION_LPN]</th>
                        <th>[FIELDCAPTION_SKU]</th>
                        <th>[FIELDCAPTION_SKUDescription]</th>
                        <th>[FIELDCAPTION_AvailableQty]</th>
                      </tr>
                    </thead>
                    <tbody>
                      [DATATABLE_LPNs]
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="scan-wave-details">
          <div class="amf-datacard-container" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_WaveInfo_WaveId]" data-rfvisiblegreaterthan="0">
            <div class="amf-datacard">
              <div class="col-md-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_Wave]</label>
                <span class="amf-display-value">[FIELDVALUE_WaveInfo_WaveTypeDesc] / [FIELDVALUE_WaveInfo_WaveNo]</span>
              </div>
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_WaveStatus]</label>
                <span class="amf-display-value">[FIELDVALUE_WaveInfo_WaveStatusDesc]</span>
              </div>
            </div>
            <div class="amf-datacard">
              <div class="col-md-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_Account]</label>
                <span class="amf-display-value">[FIELDVALUE_WaveInfo_Account]</span>
              </div>
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_Customer]</label>
                <span class="amf-display-value">[FIELDVALUE_WaveInfo_AccountName]</span>
              </div>
            </div>
          </div>
          <div class="amf-datacard-container" data-rfvisibility="GREATERTHAN"
          data-rfvisiblevalue="[FIELDVALUE_OrderInfo_OrderId]" data-rfvisiblegreaterthan="0">
            <div class="amf-datacard">
              <div class="col-md-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
                <span class="amf-display-value">[FIELDVALUE_OrderInfo_WaveTypeDesc] / [FIELDVALUE_OrderInfo_PickTicket]</span>
              </div>
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_Ownership] / [FIELDCAPTION_Warehouse]</label>
                <span class="amf-display-value">[FIELDVALUE_OrderInfo_Ownership] / [FIELDVALUE_OrderInfo_Warehouse]</span>
              </div>
            </div>
            <div class="amf-datacard" data-rfvisibility="NOTIN"
            data-rfvisiblevalue="[FIELDVALUE_OrderInfo_WaveType]" data-rfvisiblenotin="BCP">
              <div class="col-md-6 col-xs-6 amf-border-separate">
                <label class="col-form-label">[FIELDCAPTION_Account]</label>
                <span class="amf-display-value">[FIELDVALUE_OrderInfo_Account]</span>
              </div>
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_Customer]</label>
                <span class="amf-display-value">[FIELDVALUE_OrderInfo_AccountName]</span>
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
from #QtyInputPanel QIP join vwBusinessUnits BU on QIP.BusinessUnit = BU.BusinessUnit;
