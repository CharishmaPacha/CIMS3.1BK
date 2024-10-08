/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/25  RIA    Cleanup and included new classes (CIMSV3-1236)
  2020/07/16  NB     Added FORMATTR placeholders for custom attributes (CIMSV3-773)
  2020/05/25  RIA    Added classes for each input to show/hide them (HA-521)
  2020/05/14  RIA    Added data-rfvalidation-isbetween (CIMSV3-873)
  2020/05/12  RIA    Removed data-rfenabled and handled it from js (HA-430)
  2020/04/12  AY     Initial Revision
------------------------------------------------------------------------------*/

declare @vFormName  TName;

select @vFormName = 'Common_QuantityInputPanel';
delete from AMF_Forms where FormName = @vFormName;

/* There are several places in CIMS that have the need for the same functionality of
   user selecting the unit of measure and then entering the quantity either in
   InnerPacks or eaches. To ensure that this is consistent across all screens, that
   portion of the HTML is being setup separately so that all screens have the same
   functional changes. To be very careful because any bugs also will make all
   dependent screens unusable at once.

   However, when this HTML is embedded within another form, the onchange events would be different
   so we are using generic names here which would be replaced with actual method name on it's usage
*/

insert into AMF_Forms(FormName, DisplayCaption, DeviceCategory, BusinessUnit, RawHtml)
select @vFormName, 'Quantity Input Panel', 'STD', BusinessUnit,
'
<div class="amf-quantity-input-panel-container">
  <div class="amf-datacard-Radiobuttons-SelectUoM hidden">
    <div class="row">
      <div class="amf-radio">
        <div class="col-md-4 col-sm-4 col-xs-4 amf-datacard-UoMSelectRadio-Cases">
          <div class="radio">
            <input id="SelectUoMInnerPacks" type="radio" name="InnerPacks" class="amf-input-details"
            data-rfname="InnerPacks" value="" onchange="SelectCases_Onchange()">
            <label for="SelectUoMInnerPacks" class="radio-label">[FIELDCAPTION_AMFInnerPacks]</label>
          </div>
        </div>
        <div class="col-md-4 col-sm-4 col-xs-4 amf-datacard-UoMSelectRadio-Eaches">
          <div class="radio">
            <input id="SelectUoMEaches" type="radio" name="Eaches" class="amf-input-details-each"
            data-rfname="Eaches" value="" onchange="SelectEaches_Onchange()">
            <label for="SelectUoMEaches" class="radio-label">[FIELDCAPTION_AMFUoMEaches]</label>
          </div>
        </div>
        <div class="col-md-4 col-sm-4 col-xs-4 hidden">
          <span class="amf-display-value"  data-rfjsname="InventoryUoM" data-rfvalue=""></span>
        </div>
      </div>
    </div>
    <div class="amf-mb-10"></div>
  </div>
  <div class="amf-datacard-QuantityInputPanel-InnerPacks hidden">
    <div class="row">
      <div class="col-md-12 col-xs-12">
        <div class="col-md-4 col-sm-4 col-xs-4 amf-datacard-QIP-IP-InnerPacks amf-border-separate"
        data-rfnumberinputhandler="QuantityInputPanel_ChangeInCases_OnClick">
          <label class="col-form-label">[FIELDCAPTION_Cases]</label>
          <div class="clearfix"></div>
          <div class="amf-form-number-input-container">
            <span class="amf-form-number-input-decrement">-</span>
            <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
            data-rfname="NewInnerPacks" data-displaycaption="[FIELDCAPTION_Cases]" value="[FIELDVALUE_Cases]" data-rftabindex="6" size="5"
            data-rfvalidationset="GREATEROREQUAL" data-rfvalidation-greaterorequal="1" data-rfvalidation-isbetween="1,99999"
            id="Cases" onchange="QuantityInputPanel_OnChangeCases()">
            <span class="amf-form-number-input-increment">+</span>
            <div class="clearfix"></div>
            <span class="amf-form-number-input-display-value amf-datacard-QuantityInputPanel-ShowChange hidden"
            data-rfname="InitialInnerPacks"
            data-rfjsname="ChangeInnerPacks" data-rfvalue=""></span>
          </div>
        </div>
        <div class="col-md-4 col-sm-4 col-xs-4 amf-datacard-QIP-IP-UnitsPerInnerPack amf-border-separate"
        data-rfnumberinputhandler="QuantityInputPanel_ChangeInUnitsPerIP_OnClick">
          <label class="col-form-label">[FIELDCAPTION_UnitsPerInnerPack]</label>
          <div class="clearfix"></div>
          <div class="amf-form-number-input-container">
            <span class="amf-form-number-input-decrement">-</span>
            <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
            data-rfname="NewUnitsPerInnerPack" data-displaycaption="[FIELDCAPTION_NewUnitsPerInnerPack]"
            value="[FIELDVALUE_UnitsPerInnerPack]" data-rftabindex="7" size="5"
            data-rfvalidationset="GREATEROREQUAL" data-rfvalidation-greaterorequal="1" data-rfvalidation-isbetween="1,99999"
            id="NewUnitsPerInnerPack" onchange="QuantityInputPanel_OnChangeUnitsPerIP()">
            <span class="amf-form-number-input-increment">+</span>
            <div class="clearfix"></div>
            <span class="amf-form-number-input-display-value amf-datacard-QuantityInputPanel-ShowChange hidden"
            data-rfname="InitialUnitsPerInnerPack"
            data-rfjsname="ChangeUnitsPerInnerPack" data-rfvalue=""></span>
          </div>
        </div>
        <div class="col-md-4 col-sm-4 col-xs-4 amf-datacard-QIP-IP-Eaches"
        data-rfnumberinputhandler="QuantityInputPanel_ChangeInUnits_OnClick">
          <label class="col-form-label">[FIELDCAPTION_Units]</label>
          <div class="clearfix"></div>
          <div class="amf-form-number-input-container">
            <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
            data-rfname="NewUnits" data-displaycaption="[FIELDCAPTION_TotalUnits]"
            value="[FIELDVALUE_Units]" data-rfenabled="ISNULL" data-rftabindex="8" size="5"
            data-rfvalidationset="GREATEROREQUAL" data-rfvalidation-greaterorequal="1" data-rfvalidation-isbetween="1,999999"
            id="Units" onchange="QuantityInputPanel_ShowChangeUnits()">
            <div class="clearfix"></div>
            <span class="amf-form-number-input-display-value amf-datacard-QuantityInputPanel-ShowChange hidden"
            data-rfname="InitialUnits"
            data-rfjsname="ChangeUnits" data-rfvalue=""></span>
          </div>
        </div>
      </div>
    </div>
    <div class="amf-mb-10"></div>
  </div>
  <div class="amf-datacard-QuantityInputPanel-Eaches hidden">
    <div class="row">
      <div class="col-md-5 col-sm-5 col-xs-5 amf-datacard-QIP-Eaches-UnitsPerInnerPack amf-border-separate">
        <label>[FIELDCAPTION_UnitsPerInnerPack]</label>
        <div class="clearfix"></div>
        <div class="amf-form-number-input-container" data-rfnumberinputhandler="QuantityInputPanel_ChangeInUnitsPerIP1_OnClick">
          <span class="amf-form-number-input-decrement">-</span>
          <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
          data-rfname="NewUnitsPerInnerPack1" data-displaycaption="[FIELDCAPTION_NewUnitsPerInnerPack]"
          value="" data-rftabindex="9" size="5"
          id="NewUnitsPerInnerPack1" onchange="QuantityInputPanel_OnChangeUnitsPerIP1()">
          <span class="amf-form-number-input-increment">+</span>
          <div class="clearfix"></div>
          <span class="amf-form-number-input-display-value amf-datacard-QuantityInputPanel-ShowChange hidden" data-rfname="InitialUnitsPerInnerPack1"
          data-rfjsname="ChangeUnitsPerInnerPack1" data-rfvalue=""></span>
        </div>
      </div>
      <div class="col-md-5 col-sm-5 col-xs-5 amf-datacard-QIP-Eaches-Units">
        <label>[FIELDCAPTION_Units]</label>
        <div class="clearfix"></div>
        <div class="amf-form-number-input-container" data-rfnumberinputhandler="QuantityInputPanel_ChangeInUnits1_OnClick">
          <span class="amf-form-number-input-decrement">-</span>
          <input class="amf-form-number-input amf-form-number-input-width" type="text" inputmode="numeric"
          data-rfname="NewUnits1" data-displaycaption="[FIELDCAPTION_Units]"
          value="" data-rftabindex="10" size="5" [FORMATTR_NewUnits1RFValidateOn] [FORMATTR_NewUnits1RFValidationHandler]
          data-rfvalidationset="GREATEROREQUAL" data-rfvalidation-greaterorequal="1" data-rfvalidation-isbetween="1,999999"
          id="Units1" onchange="QuantityInputPanel_ShowChangeUnits1()" [FORMATTR_NewUnits1RFSubmitForm]>
          <span class="amf-form-number-input-increment">+</span>
          <div class="clearfix"></div>
          <span class="amf-form-number-input-display-value amf-datacard-QuantityInputPanel-ShowChange hidden" data-rfname="InitialUnits1"
          data-rfjsname="ChangeUnits1" data-rfvalue=""></span>
        </div>
      </div>
    </div>
  </div>
</div>
'
from vwBusinessUnits;
