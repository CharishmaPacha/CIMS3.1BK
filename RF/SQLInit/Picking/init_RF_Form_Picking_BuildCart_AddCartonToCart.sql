/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/06/10  AY      Initial Revision(CID-547)
------------------------------------------------------------------------------*/
declare @vFormName  TName;

select @vFormName = 'Picking_BuildCart_AddCartonToCart';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Build Cart - Add Cartons/Totes', 'STD', BusinessUnit,
'
No Standard Form Defined
'
from vwBusinessUnits;

/* 1280x800 Tablet version */
insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Build Cart - Add Cartons/Totes', '1280x800', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Build Cart - Add Cartons/Totes</span>
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
          <input type="text" name="Carton" placeholder="[FIELDCAPTION_AMFCartonTote_PH]" data-rfname="ScannedLPN" data-displaycaption="[FIELDCAPTION_AMFCartonTote]" data-rfvalidationset="NOTNULL" data-rftabindex="1"/>
          <label for="Carton">[FIELDCAPTION_AMFCartonTote]</label>
        </div>
        <div class="form-group" style="margin-bottom: 20px;">
          <input type="text" name="CartPosition" placeholder="[FIELDCAPTION_AMFCartPosition_PH]" data-rfname="ScannedCartPosition" data-displaycaption="[FIELDCAPTION_AMFCartPosition]"  data-rfvalidationset="NOTNULL" data-rftabindex="2" data-rfsubmitform="true"/>
          <label for="CartPosition">[FIELDCAPTION_AMFCartPosition]</label>
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
        <div class="cimsrfc-datapanel-container" data-rfvisibility="NOTNULL" data-rfvisiblevalue="[FIELDVALUE_BUILDCARTBatch]">
	        <div class="cimsrfc-datapanel-details">
	          <div class="col-md-6 cimsrfc-border-separate">
	            <label class="col-form-label">[FIELDCAPTION_TaskId]</label>
	            <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_TaskId]</span>
	          </div>
	          <div class="col-md-6">
	            <label class="col-form-label">[FIELDCAPTION_AMFPickingCart]</label>
	            <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_Pallet]</span>
	          </div>
	        </div>
          <div class="cimsrfc-datapanel-details">
            <div class="col-md-6 cimsrfc-border-separate">
              <label class="col-form-label">[FIELDCAPTION_WaveNo]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_WaveNo]</span>
            </div>
            <div class="col-md-6">
              <label class="col-form-label">[FIELDCAPTION_WaveType]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_WaveTypeDesc]</span>
            </div>
          </div>
          <div class="cimsrfc-datapanel-details">
            <div class="col-md-6 cimsrfc-border-separate">
              <label class="col-form-label">[FIELDCAPTION_TaskType]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_TaskSubTypeDescription]</span>
            </div>
            <div class="col-md-6">
              <label class="col-form-label">[FIELDCAPTION_CartType]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_CartType]</span>
            </div>
          </div>
          <div class="cimsrfc-datapanel-details">
            <div class="col-md-4 cimsrfc-border-separate">
              <label class="col-form-label">[FIELDCAPTION_NumOrders]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_NumOrders]</span>
            </div>
            <div class="col-md-4">
              <label class="col-form-label">[FIELDCAPTION_AMFNumCartonTotes]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_NumTempLabels]</span>
            </div>
            <div class="col-md-4">
              <label class="col-form-label">[FIELDCAPTION_NumUnits]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_TotalUnits]</span>
            </div>
          </div>
          <div class="cimsrfc-datapanel-details">
            <div class="col-md-4 cimsrfc-border-separate">
              <label class="col-form-label">[FIELDCAPTION_AMFNumCartonsOnCart]</label>
              <span class="cimsrfc-display-value">[FIELDVALUE_TaskInfo_NumCartonsOnCart]</span>
            </div>
          </div>
        </div>
      </div>

    </div>
  </div>

</div>

'
from vwBusinessUnits;
