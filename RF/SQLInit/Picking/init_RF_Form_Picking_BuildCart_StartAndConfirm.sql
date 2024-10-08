/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/05/24  NB      Removed conditions for visibility of back to menu option
  2019/04/18  NB      Added ISNUMBER validation to task id(CID-286)
  2019/02/25  NB      Initial Revision(CIMSV3-370)
------------------------------------------------------------------------------*/
declare @vFormName  TName;

select @vFormName = 'Picking_BuildCart_StartAndConfirm';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Build Cart', 'STD', BusinessUnit,
'
No Standard Form Defined
'
from vwBusinessUnits;

/* 1280x800 Tablet version */
insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Build Cart', '1280x800', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Build Cart</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPicking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>

<div class="amf-form-container-tablet">
  <div class="container">
    <div class="row">
      <div class="col-md-6 col-xs-6">
        <div class="form-group" style="margin-bottom: 20px;">
          <input type="text" name="TaskId" placeholder="[FIELDCAPTION_AMFTaskId_PH]" data-rfname="TaskId" data-displaycaption="[FIELDCAPTION_TaskId]" data-rfvalidationset="NOTNULL,ISNUMBER" data-rfvalidateon="FOCUSOUT" data-rfvalidationhandler="Picking_BuildCart_ValidateTask" data-rfenabled="ISNULL" data-rfenabledvalue="[FIELDVALUE_TASKDETAILSTaskId]" value="[FIELDVALUE_TASKDETAILSTaskId]" data-rftabindex="1"/>
          <label for="TaskId">Scan [FIELDCAPTION_TaskId]</label>
        </div>
        <div class="form-group" style="margin-bottom: 20px;">
          <input type="text" name="PickingCart" placeholder="[FIELDCAPTION_AMFPickingCart_PH]" data-rfname="PickingCart" data-displaycaption="[FIELDCAPTION_Cart]"  data-rfvalidationset="NOTNULL" data-rftabindex="2" data-rfsubmitform="true"/>
          <label for="PickingCart">Scan [FIELDCAPTION_Cart]</label>
        </div>
        <div class="row">
          <div class="col-md-4 col-xs-6">
            <div class="form-group">
              <button type="submit" class="btn btn-primary amf-form-submit" style="margin-top:0;">Submit</button>
            </div>
          </div>
        </div>
      </div>
      <div class="col-md-6 col-xs-6">
        <div class="cimsrfc-buildcart-taskdetails-container" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_TASKDETAILSTaskId]">
          <div class="cimsrfc-buildcart-taskdetails">
            <div class="col-md-6 cimsrfc-border-separate">
              <label class="col-form-label">[FIELDCAPTION_WaveNo]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TASKDETAILSWaveNo]</span>
            </div>
            <div class="col-md-6">
              <label class="col-form-label">[FIELDCAPTION_WaveType]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TASKDETAILSWaveTypeDesc]</span>
            </div>
          </div>
          <div class="cimsrfc-buildcart-taskdetails">
            <div class="col-md-6 cimsrfc-border-separate">
              <label class="col-form-label">[FIELDCAPTION_TaskType]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TASKDETAILSTaskSubTypeDescription]</span>
            </div>
            <div class="col-md-6">
              <label class="col-form-label">[FIELDCAPTION_CartType]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TASKDETAILSCartType]</span>
            </div>
          </div>
          <div class="cimsrfc-buildcart-taskdetails">
            <div class="col-md-6 cimsrfc-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumOrders]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TASKDETAILSNumOrders]</span>
            </div>
            <div class="col-md-6">
              <label class="col-form-label">[FIELDCAPTION_AMFNumCartonTotes]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TASKDETAILSNumTempLabels]</span>
            </div>
          </div>
          <div class="cimsrfc-buildcart-taskdetails">
            <div class="col-md-6 cimsrfc-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumUnits]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TASKDETAILSTotalUnits]</span>
            </div>
            <div class="col-md-6">
            </div>
          </div>

        </div>
      </div>

    </div>
  </div>

</div>

'
from vwBusinessUnits;
