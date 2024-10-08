/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/06/17  RIA    Initial Revision(CID-591)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Picking_ClearCart';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Clear Cart', 'STD', BusinessUnit,
'
No Standard Version Defined
'
from vwBusinessUnits;

/* 1280x800 Tablet version */
insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Clear Cart', '1280x800', BusinessUnit,
'
<!-- Page header -->
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <a class="amf-form-heading-logo" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Clear Cart</span>
      <a href="javascript:void(0);" class="js-amf-form-backtosubmenu" data-amfsubmenu="RFPicking"><span class="pull-right"><i class="amfi-back-left"></i></span></a>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>
<!-- Page header -->
<div class="amf-form-container-tablet">
  <div class="container">
    <input  type="hidden" />
    <!-- Input Panel -->
    <div class="row">
      <div class="col-md-4 col-xs-4">
        <div class="form-group" style="margin-bottom: 20px;">
          <input class="amf-input-details" type="text" name="Pallet" id="Pallet" placeholder="[FIELDCAPTION_AMFPalletOrCart_PH]" data-rfname="Pallet" data-displaycaption="[FIELDCAPTION_Pallet]" data-rfsubmitform="true" data-rftabindex="1">
          <label for="Pallet">[FIELDCAPTION_Pallet]</label>
        </div>
      </div>
	  <div class="col-md-2 col-xs-2">
        <div class="form-group">
          <button type="submit" class="btn btn-primary amf-form-submit amf-button-top-margin">Submit</button>
        </div>
      </div>
    </div>
  </div>
</div>'
from vwBusinessUnits;
