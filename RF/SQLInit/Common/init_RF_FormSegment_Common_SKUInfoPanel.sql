/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/19  SK      Include place holders for run time value updates (HA-1567)
  2020/10/13  RIA     Corrections to field value (CIMSV3-1110)
  2020/10/09  RIA     Corrected SKUImageURL value (CIMSV3-1108)
  2020/10/05  RIA     Initial Revision (CIMSV3-1110)
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Common_SKUInfoPanel';
delete from AMF_Forms where FormName = @vFormName;

/* There are several places in CIMS that have the need for showing the SKU info along
   with Image.

   However, when this HTML is embedded within another form, the onchange events would be different
   so we are using generic names here which would be replaced with actual method name on it's usage
*/

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'SKU Info Panel', 'STD', BusinessUnit,
'
          <div class="amf-datacard-container">
            <div class="col-md-12 col-xs-12">
              <div class="amf-datacard">
                <div class="col-md-9 col-xs-9 amf-border-separate">
                  <span class="amf-display-value"       data-rfjsname="SIP_SKU">[FIELDVALUE_SKUInfo_SKU]</span>
                  <span class="amf-display-value-small" data-rfjsname="SIP_DisplaySKU">[FIELDVALUE_SKUInfo_DisplaySKU]</span>
                  <span class="amf-display-value-small" data-rfjsname="SIP_DisplaySKUDesc">[FIELDVALUE_SKUInfo_DisplaySKUDesc]</span>
                </div>
                <div class="col-md-3 col-xs-3" data-rfjsname="SIP_SKUIMG">
                  <img src="[SESSIONKEY_SKUIMAGEPATH][FIELDVALUE_SKUInfo_SKUImageURL]" alt="" height="150" width="100">
                </div>
              </div>
            </div>
          </div>
'
from vwBusinessUnits;
