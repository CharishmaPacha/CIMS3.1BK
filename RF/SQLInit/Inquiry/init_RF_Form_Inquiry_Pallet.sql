/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/04  RIA     Changes to data table, HTML and CSS changes for standardization (OB2-1783)
  2021/01/06  NB      HTML and CSS changes for standardization(AMF-93)
  2020/10/08  RIA     Clean up (CIMSV3-1126)
  2020/05/15  RIA     Renamed Inquiry_Pallet_Picking_Form to Inquiry_Pallet_PickingCart_Form (HA-433)
  2020/05/14  AY      Setup Inquiry form for Receiving Pallet (HA-433)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/12/03  RIA     Made changes as per standards (CIMSV3-662)
  2019/08/06  RIA     Changes to show form as per the design using latest css (CID-778)
  2019/07/10  RIA     pr_AMF_Inquiry_Pallet: Changes to show the required info (CID-GoLive)
  2019/06/19  NB      Changes to use generic css classes(CIMSV3-571)
  2019/05/31  RIA     Initial Revision(CIMSV3-463)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Inquiry_Pallet_PickingCart_Form';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Pallet Inquiry', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Pallet / Cart Inquiry</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInquiry"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y" />
  <div class="amf-form-layout-container">
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y">
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-6 col-sm-6 col-xs-12">
            <div class="row">
              <div class="col-md-8 col-sm-8 col-xs-7">
                <div class="form-group">
                  <input class="amf-input" type="text" name="Pallet" id="Pallet"
                  placeholder="[FIELDCAPTION_AMFPalletOrCart]" data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]"
                  data-rfvalidationset="NOTNULL"  data-rfvalidateon="SUBMIT" data-rftabindex="1">
                  <label for="Pallet">[FIELDCAPTION_AMFPalletOrCart]</label>
                </div>
              </div>
              <div class="col-md-4 col-sm-4 col-xs-5">
                <div class="form-group">
                  <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
                  data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
                </div>
              </div>
            </div>
          </div>
          <div class="col-md-6 col-sm-6 col-xs-12 amf-mt-10">
            <div class="amf-datacard-container" style="background:none;"
            data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Pallet]">
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_Pallet]</label>
                  <span class="amf-display-value">[FIELDVALUE_Pallet]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_Status]</label>
                  <span class="amf-display-value">[FIELDVALUE_Status]</span>
                </div>
              </div>
            </div>
          </div>
        <div class="clearfix"></div>
        </div>
      </div>
    </div>
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-display-panel" style="background:none; display: none;" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Pallet]">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-6 col-sm-6 col-xs-12">
              <div class="table-responsive">
                <table data-rfrecordname="PrintTable" class="table scroll table-striped table-bordered js-datatable-inquiry-palletorcart">
                  <thead>
                    <tr>
                      <th data-rffieldname="LPN">[FIELDCAPTION_Tote/Carton]</th>
                      <th data-rffieldname="Status" hidden>[FIELDCAPTION_Status]</th>
                      <th data-rffieldname="Position">[FIELDCAPTION_Position]</th>
                      <th data-rffieldname="PickTicket">[FIELDCAPTION_PickTicket]</th>
                      <th data-rffieldname="SKU" hidden>[FIELDCAPTION_SKU]</th>
                      <th data-rffieldname="SKU1" hidden>[FIELDCAPTION_SKU1]</th>
                      <th data-rffieldname="SKU2" hidden>[FIELDCAPTION_SKU2]</th>
                      <th data-rffieldname="SKU3" hidden>[FIELDCAPTION_SKU3]</th>
                      <th data-rffieldname="SKU4" hidden>[FIELDCAPTION_SKU4]</th>
                      <th data-rffieldname="SKU5" hidden>[FIELDCAPTION_SKU5]</th>
                      <th data-rffieldname="SKUDescription" hidden>[FIELDCAPTION_SKUDescription]</th>
                      <th data-rffieldname="Quantity" hidden>[FIELDCAPTION_Quantity]</th>
                      <th data-rffieldname="UnitsToPick">[FIELDCAPTION_UnitsToPick]</th>
                      <th data-rffieldname="UnitsPicked">[FIELDCAPTION_UnitsPicked]</th>
                      <th data-rffieldname="PrintLabel" hidden>[FIELDCAPTION_PrintLabel]</th>
                    </tr>
                  </thead>
                  <tbody>[DATATABLE_PALLETDETAILS]</tbody>
                </table>
              </div>
            </div>
            <div class="col-md-6 col-sm-6 col-xs-12">
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_WaveType], [FIELDCAPTION_WaveNo]</label>
                  <span class="amf-display-value">[FIELDVALUE_WaveType], [FIELDVALUE_WaveNo]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_TaskId]</label>
                  <span class="amf-display-value">[FIELDVALUE_TaskId]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate" >
                  <label class="col-form-label">[FIELDCAPTION_Location]</label>
                  <span class="amf-display-value">[FIELDVALUE_location]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_AMFTaskAssignedTo]</label>
                  <span class="amf-display-value">[FIELDVALUE_TaskAssignedTo]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_AMFNumCartonTotes]</label>
                  <span class="amf-display-value">[FIELDVALUE_NumCartonsOrTotes]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_AMFNumPositions]</label>
                  <span class="amf-display-value">[FIELDVALUE_Positions]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_AMFTotalUnitsToPick]</label>
                  <span class="amf-display-value">[FIELDVALUE_TotalUnitsToPick]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_AMFNumPicked]</label>
                  <span class="amf-display-value">[FIELDVALUE_TotalUnitsPicked]</span>
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

/*----------------------------------------------------------------------------------*/
select @vFormName = 'Inquiry_Pallet_Form';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Pallet Inquiry', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Pallet / Cart Inquiry</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFInquiry"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);" ><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-container">
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y" />
  <div class="amf-form-layout-container">
    <input type="hidden" data-rfname="PrintData">
    <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y">
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-input-panel">
      <div class="amf-form-panel-shadow">
        <div class="row">
          <div class="col-md-6 col-sm-6 col-xs-12">
            <div class="row">
              <div class="col-md-8 col-sm-8 col-xs-7">
                <div class="form-group">
                  <input class="amf-input" type="text" name="Pallet" id="Pallet"
                   placeholder="[FIELDCAPTION_AMFPalletOrCart]" data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]"
                  data-rfvalidationset="NOTNULL"  data-rfvalidateon="SUBMIT" data-rftabindex="1">
                  <label for="Pallet">[FIELDCAPTION_AMFPalletOrCart]</label>
                </div>
              </div>
              <div class="col-md-4 col-sm-4 col-xs-5">
                <button type="button" class="amf-button amf-button-submit amf-button-fullwidth amf-button-top-margin"
                data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
              </div>
            </div>
          </div>
          <div class="col-md-6 col-sm-6 col-xs-12 amf-mt-10">
            <div class="amf-datacard-container" style="background:none;"
            data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Pallet]">
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_Pallet]</label>
                  <span class="amf-display-value">[FIELDVALUE_Pallet]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_Status]</label>
                  <span class="amf-display-value">[FIELDVALUE_Status]</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-md-12 col-sm-12 col-xs-12 amf-form-display-panel" style="display: none;" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_Pallet]">
      <div class="amf-form-panel-shadow">
        <div class="amf-datacard-container">
          <div class="row">
            <div class="col-md-7 col-sm-7 col-xs-12">
              <div class="table-responsive">
                <table data-rfrecordname="PrintTable" class="table scroll table-striped table-bordered js-datatable-inquiry-palletorcart">
                  <thead>
                    <tr>
                      <th data-rffieldname="LPN">[FIELDCAPTION_LPN]</th>
                      <th data-rffieldname="Status">[FIELDCAPTION_Status]</th>
                      <th data-rffieldname="Position" hidden>[FIELDCAPTION_Position]</th>
                      <th data-rffieldname="PickTicket" hidden>[FIELDCAPTION_PickTicket]</th>
                      <th data-rffieldname="SKU">[FIELDCAPTION_SKU]</th>
                      <th data-rffieldname="SKU1" hidden>[FIELDCAPTION_SKU1]</th>
                      <th data-rffieldname="SKU2" hidden>[FIELDCAPTION_SKU2]</th>
                      <th data-rffieldname="SKU3" hidden>[FIELDCAPTION_SKU3]</th>
                      <th data-rffieldname="SKU4" hidden>[FIELDCAPTION_SKU4]</th>
                      <th data-rffieldname="SKU5" hidden>[FIELDCAPTION_SKU5]</th>
                      <th data-rffieldname="SKUDescription">[FIELDCAPTION_SKUDescription]</th>
                      <th data-rffieldname="Quantity">[FIELDCAPTION_Quantity]</th>
                      <th data-rffieldname="UnitsToPick" hidden>[FIELDCAPTION_UnitsToPick]</th>
                      <th data-rffieldname="UnitsPicked">[FIELDCAPTION_ReservedQty]</th>
                      <th data-rffieldname="PrintLabel" hidden>[FIELDCAPTION_PrintLabel]</th>
                    </tr>
                  </thead>
                  <tbody>[DATATABLE_PALLETDETAILS]</tbody>
                </table>
              </div>
            </div>
            <div class="col-md-5 col-sm-5 col-xs-12">
              <div class="amf-datacard" data-rfvisiblevalue="[FIELDVALUE_ReceiptNumber]" data-rfvisibility="NOTNULL">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_ReceiptType], [FIELDCAPTION_ReceiptNumber]</label>
                  <span class="amf-display-value">[FIELDVALUE_ReceiptType], [FIELDVALUE_ReceiptNumber]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_Receiver]</label>
                  <span class="amf-display-value">[FIELDVALUE_Receiver]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate" >
                  <label class="col-form-label">[FIELDCAPTION_Location] ([FIELDCAPTION_Warehouse])</label>
                  <span class="amf-display-value">[FIELDVALUE_Location] ([FIELDVALUE_Warehouse])</span>
                </div>
                <div class="col-md-3 col-sm-3 col-xs-3">
                  <label class="col-form-label">[FIELDCAPTION_NumLPNs]</label>
                  <span class="amf-display-value">[FIELDVALUE_NumLPNs]</span>
                </div>
                <div class="col-md-3 col-sm-3 col-xs-3">
                  <label class="col-form-label">[FIELDCAPTION_Quantity]</label>
                  <span class="amf-display-value">[FIELDVALUE_Quantity]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-12 col-sm-12 col-xs-12 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKU]</label>
                  <span class="amf-display-value">[FIELDVALUE_DisplaySKU]</span>
                  <span class="amf-display-value">[FIELDVALUE_DisplaySKUDesc]</span>
                </div>
              </div>
              <div class="amf-datacard">
                <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKU1]</label>
                  <span class="amf-display-value amf-word-break-all">[FIELDVALUE_SKU1]</span>
                </div>
                <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKU2]</label>
                  <span class="amf-display-value amf-word-break-all">[FIELDVALUE_SKU2]</span>
                </div>
                <div class="col-md-3 col-sm-3 col-xs-3 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_SKU3]</label>
                  <span class="amf-display-value amf-word-break-all">[FIELDVALUE_SKU3]</span>
                </div>
                <div class="col-md-3 col-sm-3 col-xs-3" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_SKU4]">
                  <label class="col-form-label">[FIELDCAPTION_SKU4]</label>
                  <span class="amf-display-value amf-word-break-all">[FIELDVALUE_SKU4]</span>
                </div>
              </div>
              <div class="amf-datacard" data-rfvisiblevalue="[FIELDVALUE_ReceiptNumber]" data-rfvisibility="NOTNULL">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_AMFLPNsInTransitWithUnits]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNsInTransit] ([FIELDVALUE_UnitsInTransit])</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_AMFLPNsReceivedWithUnits]</label>
                  <span class="amf-display-value">[FIELDVALUE_LPNsReceived] ([FIELDVALUE_UnitsReceived])</span>
                </div>
              </div>
              <div class="amf-datacard" data-rfvisiblevalue="[FIELDVALUE_TaskId]" data-rfvisibility="NOTNULL">
                <div class="col-md-6 col-sm-6 col-xs-6 amf-border-separate">
                  <label class="col-form-label">[FIELDCAPTION_PickTicket] / [FIELDCAPTION_Wave]</label>
                  <span class="amf-display-value">[FIELDVALUE_PickTicket]</span>
                  <span class="amf-display-value">[FIELDVALUE_Wave]</span>
                </div>
                <div class="col-md-6 col-sm-6 col-xs-6">
                  <label class="col-form-label">[FIELDCAPTION_TaskId]</label>
                  <span class="amf-display-value">[FIELDVALUE_TaskId]</span>
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
