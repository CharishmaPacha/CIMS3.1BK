/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/11/22  RIA     Initial Revision(CIMSV3-650)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Picking_GetLPNPick';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'LPN Picking', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">LPN Picking</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPicking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <div class="container">
    <input  type="hidden" data-rfname="PickGroup"value="RF-C-L" />
    <input  type="hidden" data-rfname="Operation"value="CustomerOrderPicking" />
      <div class="row">
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="PickingPallet" placeholder="[FIELDCAPTION_AMFPalletOrCart_PH]" data-rfname="PickingPallet" data-displaycaption="[FIELDCAPTION_Pallet]" value=""  data-rfvalidationset="NOTNULL" data-rftabindex="1">
            <label for="PickingPallet">[FIELDCAPTION_AMFPalletOrCart]<sup style="color:red">*</sup></label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="TaskId"  placeholder="[FIELDCAPTION_TaskId]"  data-rfname="TaskId" data-displaycaption="TaskId" value="" data-rfvalidationset="ISNUMBER" data-rfsubmitform="true" data-rftabindex="2">
            <label for="TaskId">[FIELDCAPTION_TaskId]</label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="WaveNo" placeholder="[FIELDCAPTION_WaveNo]" data-rfname="WaveNo" data-displaycaption="[FIELDCAPTION_WaveNo]" value="" data-rftabindex="3">
            <label for="WaveNo">[FIELDCAPTION_WaveNo]</label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="PickTicket" placeholder="[FIELDCAPTION_PickTicket]"  data-rfname="PickTicket"  data-displaycaption="[FIELDCAPTION_PickTicket]" value="" data-rftabindex="4">
            <label for="PickTicket">[FIELDCAPTION_PickTicket]</label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text"  name="PickZone" placeholder="[FIELDCAPTION_PickZone]"  data-rfname="PickZone"  data-displaycaption="[FIELDCAPTION_PickZone]" value="" data-rftabindex="5">
            <label for="PickZone">[FIELDCAPTION_PickZone]</label>
          </div>
        </div>
        <div class="col-md-6 col-xs-6 amf-form-input-responsive-width">
          <div class="form-group">
            <input type="text" name="DestZone" placeholder="[FIELDCAPTION_DestZone]"  data-rfname="DestZone" data-displaycaption="[FIELDCAPTION_DestZone]" value="" data-rftabindex="6" data-rfsubmitform="true">
            <label for="DestZone">[FIELDCAPTION_DestZone]</label>
          </div>
        </div>
        <div class="col-md-5 col-xs-3">
          <div class="form-group">
          </div>
        </div>
        <div class="col-md-2 col-xs-6">
          <div class="form-group">
            <button type="submit" class="btn btn-primary">Submit</button>
          </div>
        </div>
        <div class="col-md-5 col-xs-3">
          <div class="form-group">
          </div>
        </div>
      </div>
  </div>
</div>
'
from vwBusinessUnits;
