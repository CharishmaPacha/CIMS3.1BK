/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/14  RIA     Form clean up (CIMSV3-975)
  2020/05/15  TK      Pass PickGroup (HA-543)
  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/06/01  AY      Submit after entering TaskId and ensure it is numeric
  2019/02/04  NB      Added 1280x800 version (CIMSV3-331)
  2019/01/08  NB      changes for addressing renaming of tables for AMF and naming conventions (AMF-26)
  2018/11/06  NB      Initial Revision(CIMSV3-331)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'BatchPicking_GetPickTask';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Get Pick Task', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Get Task To Pick</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPicking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <div class="container">
    <input  type="hidden" data-rfname="PickType"value="RF-C-CSU" />
    <input  type="hidden" data-rfname="PickGroup"value="RF-C-CSU" />
    <input  type="hidden" data-rfname="Operation"value="CustomerOrderPicking" />
    <div class="row">
      <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
        <div class="form-group">
          <input type="text" name="PickingPallet" placeholder="[FIELDCAPTION_AMFPalletOrCart]" data-rfname="PickingPallet" data-displaycaption="[FIELDCAPTION_Pallet]" value="[FIELDVALUE_PickingPallet]"  data-rfvalidationset="NOTNULL" data-rftabindex="1">
          <label for="PickingPallet">[FIELDCAPTION_AMFPalletOrCart]<sup style="color:red">*</sup></label>
        </div>
      </div>
      <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
        <div class="form-group">
          <input type="text" name="TaskId"  placeholder="[FIELDCAPTION_TaskId]"  data-rfname="TaskId" data-displaycaption="[FIELDCAPTION_TaskId]" value="[FIELDVALUE_TaskId]" data-rfvalidationset="ISNUMBER" data-rfsubmitform="true" data-rftabindex="2">
          <label for="TaskId">[FIELDCAPTION_TaskId]</label>
        </div>
      </div>
      <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
        <div class="form-group">
          <input type="text" name="WaveNo" placeholder="[FIELDCAPTION_WaveNo]" data-rfname="WaveNo" data-displaycaption="[FIELDCAPTION_WaveNo]" value="[FIELDVALUE_WaveNo]" data-rftabindex="3">
          <label for="WaveNo">[FIELDCAPTION_WaveNo]</label>
        </div>
      </div>
      <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
        <div class="form-group" style="margin-bottom: 20px;">
          <input type="text" name="PickTicket" placeholder="[FIELDCAPTION_PickTicket]"  data-rfname="PickTicket"  data-displaycaption="[FIELDCAPTION_PickTicket]" value="[FIELDVALUE_PickTicket]" data-rftabindex="4">
          <label for="PickTicket">[FIELDCAPTION_PickTicket]</label>
        </div>
      </div>
      <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
        <div class="form-group" style="margin-bottom: 20px;">
          <input type="text"  name="PickZone" placeholder="[FIELDCAPTION_PickZone]"  data-rfname="PickZone"  data-displaycaption="[FIELDCAPTION_PickZone]" value="[FIELDVALUE_PickZone]" data-rftabindex="5">
          <label for="PickZone">[FIELDCAPTION_PickZone]</label>
        </div>
      </div>
      <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
        <div class="form-group" style="margin-bottom: 20px;">
          <input type="text" name="DestZone" placeholder="[FIELDCAPTION_DestZone]"  data-rfname="DestZone" data-displaycaption="[FIELDCAPTION_DestZone]" value="[FIELDVALUE_DestZone]" data-rftabindex="6" data-rfsubmitform="true">
          <label for="DestZone">[FIELDCAPTION_DestZone]</label>
        </div>
      </div>
      <div class="col-md-4 col-xs-2">
        <div class="form-group">
        </div>
      </div>
      <div class="col-md-4 col-xs-8">
        <div class="form-group">
          <button type="button" class="btn btn-primary"
          data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
        </div>
      </div>
      <div class="col-md-4 col-xs-2">
        <div class="form-group">
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
