/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  DEPRECATED DEPRECATED DEPRECATED
  2019-02-22 NB This is no longer used. For Drop Pallet, ValidatePallet form is used for validate and drop

  Revision History:

  Date        Person  Comments

  2020/05/01  SAK     Added SESSIONKEY_WAREHOUSE (HA-285)
  2019/02/15  NB      1280x800 version of Drop Pallet (CIMSV3-331)
  2019/01/08  NB      changes for addressing renaming of tables for AMF and naming conventions (AMF-26)
  2018/11/06  NB      Initial Revision(CIMSV3-331)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'DropPickingPallet_DropPallet';
delete from AMF_Forms where FormName = @vFormName;

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Drop Pallet', 'STD', BusinessUnit,
'
<div class="amf-form-header-container">
  <div class="container">
    <div class="amf-form-heading">
      <span class="amf-form-heading-title"><img src="[TITLELOGOIMAGEPATH]" alt="image">
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="center">Drop Picking Pallet/Cart</span></span>
      <span class="pull-right js-amf-message-showhide hidden"><i class="amfi-bell"></i></span>
    </div>
  </div>
</div>

<div class="amf-form-container">

  <div class="container">
    <input  type="hidden" data-rfname="Operation"value="DropPallet" />
    <div class="row">
      <div class="form-group">
        <div class="col-xs-6 col-xs-4" style="border-right:1px solid #ccc;">
          <label>[FIELDCAPTION_AMFPalletOrCart]</label>
        </div>
        <div class="col-xs-6 col-xs-4" style="border-right:1px solid #ccc;">
          <span>[FIELDVALUE_DROPPALLETRESPONSEPallet]</span>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="form-group">
        <div class="col-xs-6" style="border-right:1px solid #ccc;">
          <label>[FIELDCAPTION_AMFDropZone]</label>
        </div>
        <div class="col-xs-6" style="border-right:1px solid #ccc;">
          <span>[FIELDVALUE_DROPPALLETRESPONSESuggestedDropZone]</span>
        </div>
      </div>
      <div class="form-group">
        <div class="col-xs-6" style="border-right:1px solid #ccc;">
          <label>[FIELDCAPTION_AMFDropLocation]</label>
        </div>
        <div class="col-xs-6" style="border-right:1px solid #ccc;">
          <span>[FIELDVALUE_DROPPALLETRESPONSESuggestedDropLocation]</span>
        </div>
      </div>
    </div>
    <div class="col-xs-12">
      <div class="form-group">
        <label>Scan [FIELDCAPTION_Location]</label>
        <input type="text" class="form-control amf-form-control" data-rfname="DroppedLocation" data-displaycaption="[FIELDCAPTION_Location]"  data-rfvalidationset="NOTNULL" data-rftabindex="1"/>
      </div>
    </div>
    <div class="col-xs-12">
      <div class="form-group">
        <button type="submit" class="btn btn-primary amf-form-submit">Submit</button>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;

/* 1280x800 Tablet Version */
insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Drop Pallet', '1280x800', BusinessUnit,
'
<div class="amf-form-header-container-tablet">
  <div class="container">
    <div class="amf-form-heading-tablet">
      <a class="amf-form-heading-logo-tablet" href="#"><img src="[TITLELOGOIMAGEPATH]" alt="image"></a>
      <span class="amf-form-heading-logo-name-tablet" style="">[TITLEAPPNAME]</span>
      <span class="pull-left amf-form-heading-key-info">[SESSIONKEY_WAREHOUSE]</span>
      <span class="amf-form-heading-title js-amf-menu-title">Drop Pallet</span>
      <a class="pull-right amf-message-showhide js-amf-message-showhide hidden"><i class="amfi-bell"></i></a>
    </div>
  </div>
</div>

<div class="amf-form-container-tablet">
  <div class="container">
    <div class="row">
      <div class="col-md-6 col-xs-6">
        <div class="form-group">
          <input type="text" value="[FIELDVALUE_DROPPALLETRESPONSEPallet]" readonly>
          <label>[FIELDCAPTION_AMFPalletOrCart]</label>
        </div>
      </div>
      <div class="col-md-6 col-xs-6">
        <div class="form-group">
          <input type="text" value="[FIELDVALUE_DROPPALLETRESPONSESuggestedDropZone]" readonly>
          <label>[FIELDCAPTION_AMFDropZone]</label>
        </div>
      </div>
      <div class="col-md-6 col-xs-6">
        <div class="form-group">
          <input type="text" value="[FIELDVALUE_DROPPALLETRESPONSESuggestedDropLocation]" readonly>
          <label>[FIELDCAPTION_AMFDropLocation]</label>
        </div>
      </div>
      <div class="col-md-6 col-xs-6">
        <div class="form-group">
          <input type="text" data-rfname="DroppedLocation" data-displaycaption="[FIELDCAPTION_Location]"  data-rfvalidationset="NOTNULL" data-rftabindex="1"/>
          <label>Scan [FIELDCAPTION_Location]</label>
        </div>
      </div>
      <div class="col-md-4 col-xs-2">
        <div class="form-group">
        </div>
      </div>
      <div class="col-md-4 col-xs-8">
        <div class="form-group">
          <button type="submit" class="btn btn-primary amf-form-submit">Submit</button>
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