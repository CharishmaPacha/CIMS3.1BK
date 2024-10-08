/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/22  RIA     Changes to form name, title and added operation (HA-832)
  2020/06/17  RIA     Initial Revision(HA-832)
------------------------------------------------------------------------------*/
declare @vFormName  TName;

select @vFormName = 'Misc_CompleteRework_ScanOrder';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Complete Rework - Scan Order', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="js-amf-form-backtomainmenu amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Complete Rework</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFMiscellaneous"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a href="javascript:void(0);"><span class="pull-right amf-form-keyboard-showhide js-amf-keyboard-showhide" style="display:none;"><i class="amfi-text"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<div class="amf-form-layout-container">
  <input type="hidden" data-rfname="Operation" value="CompleteRework" />
  <input type="hidden" name="SkipSendingModelValuesOnSubmit" value="Y" />
  <div class="container">
    <div class="row">
      <div class="col-md-4 col-xs-7">
        <div class="form-group">
          <input class="amf-input-details" type="text" name="PickTicket" id="PickTicket"
          placeholder="[FIELDCAPTION_AMFScanPickTicket_PH]" data-rfname="PickTicket"
          data-displaycaption="[FIELDCAPTION_PickTicket]" value=""
          data-rfvalidationset="NOTNULL" data-rfvalidateon="SUBMIT" data-rftabindex="1" />
          <label for="PickTicket">[FIELDCAPTION_PickTicket]</label>
        </div>
      </div>
      <div class="col-md-2 col-xs-5 amf-button-padding-left">
        <div class="form-group">
          <button type="button" class="btn btn-primary amf-button-top-margin"
          data-rfclickhandler="RFConnect_Submit_Request">Submit</button>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
