/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/06/13  RIA    Changes to show confirm button and input enabling (CID-518)
  2019/06/08  RIA    Changes to show confirm button (CID-518)
  2019/06/07  RIA    Initial Revision(CID-518)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'BatchPicking_ConfirmPicks';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Validate Picks', 'STD', BusinessUnit,
'
No Standard Version Defined
'
from vwBusinessUnits;

/* 1280x800 Tablet version */
insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Confirm Picks', '1280x800', BusinessUnit,
'
<!-- Page header -->
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Confirm Picks</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPicking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<!-- Page header -->
<div class="amf-form-container-tablet">
  <div class="container">
    <input  type="hidden" data-rfname="Operation"value="CustomerOrderPicking" />
    <!-- Input Panel -->
    <div class="row">
      <div class="col-md-4 col-xs-4">
        <div class="form-group" style="margin-bottom: 20px;">
          <input class="amf-input-details" type="text" name="LPN" id="LPN" placeholder="[FIELDCAPTION_AMFShipCarton_PH]" data-rfname="LPN" data-displaycaption="[FIELDCAPTION_LPN]" value="[FIELDVALUE_ConfirmPicksToLPN]" data-rfvalidationset="NOTNULL"  data-rfvalidateon="SUBMIT" data-rfsubmitform="true" data-rftabindex="1" data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_ConfirmPicksTaskId]">
          <label for="LPN">[FIELDCAPTION_AMFShipCarton]</label>
        </div>
      </div>
      <div class="col-md-2 col-xs-2">
        <div class="form-group" data-rfvisibility="ISNULL" data-rfvisiblevalue="[FIELDVALUE_ConfirmPicksTaskId]">
          <button type="submit" class="btn btn-primary amf-form-submit amf-button-top-margin">Submit</button>
        </div>
            <div class="form-group" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_ConfirmPicksTaskId]">
              <button type="submit" class="btn btn-primary amf-button-top-margin" data-rfclickhandler="RFConnect_Submit_Request" style="background: #77d677 !important;
    border: 1px solid #5fbd5f !important;">Confirm</button>
            </div>
          </div>
    </div>
    <!-- Main Screen -->
    <div data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_ConfirmPicksLPNQuantity]">
      <div class="row">
        <div class="col-md-6 col-xs-12">
          <h3 class="amf-form-datatable-title-tablet">Pick List</h3>
        </div>
      </div>
      <div class="row">
        <!-- Table: PickList -->
        <div class="col-md-6 col-xs-12">
          <div class="table-responsive" style="max-height:415px";>
            <table class="table scroll table-striped table-bordered">
              <thead>
                <tr>
                  <th>[FIELDCAPTION_Location]</th>
                  <th>[FIELDCAPTION_SKU]</th>
                  <th>[FIELDCAPTION_Quantity]</th>
                  <th>[FIELDCAPTION_Description]</th>
                  <th hidden>[FIELDCAPTION_TaskDetailId]</th>
                </tr>
              </thead>
              <tbody>
                [DATATABLE_TASKPICKDETAILS]
              </tbody>
            </table>
          </div>
        </div>
        <!-- Info Panel -->
        <div class="col-md-6 col-xs-12">
          <div class="cimsrfc-datapanel-container">
            <div class="cimsrfc-datapanel-details">
              <div class="col-md-6  col-xs-6 cimsrfc-border-separate">
                <label class="col-form-label">[FIELDCAPTION_LPN]</label>
                <span class="cimsrfc-display-value">[FIELDVALUE_ConfirmPicksToLPN]</span>
              </div>
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_TaskId]</label>
                <span class="cimsrfc-display-value">[FIELDVALUE_ConfirmPicksTaskId]</span>
              </div>
            </div>
            <div class="cimsrfc-datapanel-details">
              <div class="col-md-6 col-xs-6 cimsrfc-border-separate">
                <label class="col-form-label">[FIELDCAPTION_Wave]</label>
                <span class="cimsrfc-display-value">[FIELDVALUE_ConfirmPicksWaveType] [FIELDVALUE_ConfirmPicksWaveNo]</span>
              </div>
              <div class="col-md-6 col-xs-6">
                <label class="col-form-label">[FIELDCAPTION_PickTicket]</label>
                <span class="cimsrfc-display-value">[FIELDVALUE_ConfirmPicksPickTicket]</span>
              </div>
            </div>
            <div class="cimsrfc-datapanel-details">
              <div class="col-md-4 col-xs-4">
                <label class="col-form-label">[FIELDCAPTION_AMFTotalUnitsToPick]</label>
                <span class="cimsrfc-display-value">[FIELDVALUE_ConfirmPicksUnitsRemainingToPick]</span>
              </div>
            </div>
            <div class="cimsrfc-datapanel-details">
              <div class="col-md-12 col-xs-12 cimsrfc-border-separate">
                <label class="col-form-label">[FIELDCAPTION_AMFShipTo]</label>
                <span class="cimsrfc-display-value" style="width:100%;float:left;">[FIELDVALUE_ConfirmPicksShipToName]</span>
                <span class="cimsrfc-display-value" style="width:100%;float:left;">[FIELDVALUE_ConfirmPicksShipToCityStateZip]</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
</div>'
from vwBusinessUnits;
