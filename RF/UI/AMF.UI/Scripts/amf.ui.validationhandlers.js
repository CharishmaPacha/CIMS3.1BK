//-----------------------------------------------------------------------------
// Method invoked to clear the input value on the form
function Utility_ClearControlValue(evt)
{
  var controlselector = $(evt.target).attr("data-rfcontrolselector");
  if ((controlselector == undefined) || (controlselector == null))
  {
    controlselector = $(evt.target.parentElement).attr("data-rfcontrolselector");
  }

  if ((controlselector == undefined) || (controlselector == null))
  {
    return;
  }

  $(document).find(controlselector).val(null);
  $(document).find(controlselector).first().focus();
}

//-----------------------------------------------------------------------------
// This method is used to search the user entered/scanned entity in the given table
// Returns a boolean value true - if search value exists in controlselector, else false
function CheckTableEntry(controlselector, searchvalue)
{
    return Boolean($($(controlselector).find("tr td").filter(function()
                                                      {
                                                        return ($(this).text() === searchvalue);
                                                      })).length > 0);
} // CheckTableEntry

//*****************************************************************************
//*********************** DataTable SKU Details *******************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// clears the highlighted row in the data table
function DataTableSKUDetails_ClearHighlightedRow()
{
  $(".amf-form-datatable-row-highlight-tablet").removeClass();
} // DataTableSKUDetails_ClearHighlightedRow

//-----------------------------------------------------------------------------
// SKU Details data table is commonly used in many forms. This method is
// used to get the quantity values of selected SKU (tablerow)
function DataTableSKUDetails_GetQtyValues(tablerow)
{

  var quantity      = $($(tablerow).find("td")[3]).text();
  var quantity1     = $($(tablerow).find("td")[4]).text();
  var quantity2     = $($(tablerow).find("td")[5]).text();
  var availableqty  = $($(tablerow).find("td")[25]).text();
  var reservedqty   = $($(tablerow).find("td")[26]).text();
  var qtyordered    = $($(tablerow).find("td")[27]).text();
  var qtyreserved   = $($(tablerow).find("td")[28]).text();
  var minqty        = $($(tablerow).find("td")[34]).text();
  var maxqty        = $($(tablerow).find("td")[35]).text();

  return [quantity, quantity1, quantity2, availableqty, reservedqty, qtyordered, qtyreserved, minqty, maxqty];
} // DataTableSKUDetails_GetQtyValues

//-----------------------------------------------------------------------------
// SKU Details data table is commonly used in many forms. This method is
// used to get the display values of selected SKU (tablerow)
function DataTableSKUDetails_GetSKUDisplayInfo(tablerow)
{

  var displaySKU        = $($(tablerow).find("td")[0]).text();
  var displaySKUDesc    = $($(tablerow).find("td")[1]).text();

  return [displaySKU, displaySKUDesc];
} // DataTableSKUDetails_GetSKUDisplayInfo

//-----------------------------------------------------------------------------
// SKU Details data table is commonly used in many forms. This method is
// used to get the values of selected SKU (tablerow)
function DataTableSKUDetails_GetSKUValues(tablerow)
{

  var totalunits        = $($(tablerow).find("td")[3]).text();
  var innerpacksperlpn  = $($(tablerow).find("td")[11]).text();
  var unitsperinnerpack = $($(tablerow).find("td")[12]).text();
  var unitsperlpn       = $($(tablerow).find("td")[13]).text();
  var inventoryuom      = $($(tablerow).find("td")[16]).text();

  return [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn];
} // DataTableSKUDetails_GetSKUValues

//-----------------------------------------------------------------------------
// SKUDetails data table has a list of SKUs. The particular SKU can be identified
// by SKU, UPC, AlternateSKU or Barcode. This method checks for all those
// entities and returns the table row when there is match.
function DataTableSKUDetails_GetTableRow(scannedentity)
{
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
    // get the scanned entity
    var scannedentity = $("[data-rfname='SKU']").val();
  }

  var tablerow = $(document).find('.js-datatable-content-details tr').filter(function () {
  return ($(this).find('td').eq(7).text() === scannedentity); }).closest("tr"); // check if user scanned SKU

  if ($(tablerow).length == 0) // check if user scanned UPC
    {
      tablerow = $(document).find('.js-datatable-content-details tr').filter(function () {
      return ($(this).find('td').eq(8).text() === scannedentity); }).closest("tr");
    }

  if ($(tablerow).length == 0) // check if user scanned AlternateSKU
    {
      tablerow = $(document).find('.js-datatable-content-details tr').filter(function () {
      return ($(this).find('td').eq(9).text() === scannedentity); }).closest("tr");
    }

  if ($(tablerow).length == 0) // check if user scanned Barcode
    {
      tablerow = $(document).find('.js-datatable-content-details tr').filter(function () {
      return ($(this).find('td').eq(10).text() === scannedentity); }).closest("tr");
    }

  return tablerow;
} // DataTableSKUDetails_GetTableRow

//-----------------------------------------------------------------------------
// This method searches for the value entered/scanned by the user and returns the
// table row.
function DataTableSKUDetails_GetTableRowForFilteredValue(searchvalue)
{
  var tablerow = $(document).find(".js-datatable-content-details tr td:contains(" + searchvalue + ")").closest("tr");

  return tablerow;
} // DataTableSKUDetails_GetTableRowForFilteredValue

//-----------------------------------------------------------------------------
// To highlight row in the datatable and to bring the highlighted row into the view
function DataTableSKUDetails_HighlightRow(tablerow, scannedentity)
{
  // if tablerow is not given, identify it
  if ((tablerow == null) || (tablerow == undefined) || (tablerow.length == 0))
    tablerow = DataTableSKUDetails_GetTableRowForFilteredValue (scannedentity);

  // Highlights the first/top row which has the scanned Entity
  $(tablerow).first().addClass("amf-form-datatable-row-highlight-tablet");

  // Bring the highlighted row into view
  if ($(document).find(".amf-form-datatable-row-highlight-tablet").length > 0)
  {
    $(document).find(".amf-form-datatable-row-highlight-tablet")[0].scrollIntoView();
  }
} // DataTableSKUDetails_HighlightRow

//-----------------------------------------------------------------------------
//custom handler to perform timer starting
function StartTimer()
{
    setInterval(function ()
    {
        var timerelement = $(document).find(".js-cimsrfc-confirmunitpick-picking-timer");
        if (timerelement.length > 0)
        {
            var timeelapsed = $(timerelement[0]).attr("data-timeelapsed");
            if ((timeelapsed == null) || (timeelapsed == undefined))
            {
                timeelapsed = "00:00:00";
            }
            var timecompoments = timeelapsed.split(":");
            var hours = timecompoments[0];
            var minutes = timecompoments[1];
            var seconds = timecompoments[2];

            // compute the hours, minutes and seconds
            seconds = parseInt(seconds) + 1;
            if (seconds >= 60)
            {
                seconds = 0;
                minutes = parseInt(minutes) + 1;
            }

            if (minutes >= 60)
            {
                minutes = 0;
                hours = parseInt(hours) + 1;
            }


            if (seconds <= 9) {seconds = "0" + parseInt(seconds).toString() };
            if (minutes <= 9) {minutes = "0" + parseInt(minutes).toString() };
            if (hours <= 9) { hours = "0" + parseInt(hours).toString() };
            timeelapsed = hours + ":" + minutes + ":" + seconds;
            $(timerelement[0]).attr("data-timeelapsed", timeelapsed);
            $(timerelement[0]).text(timeelapsed);

        }
    }, 1000);
}

//-----------------------------------------------------------------------------
// function to assign value to RFFormAction and submit the form
function ModifySKU_Confirm(evt)
{
  // Assign value as Modify
  $("[data-rfname='RFFormAction']").val("Modify");
  $('form').submit();
} // ModifySKU_Confirm

//-----------------------------------------------------------------------------
// function to change in cases using increment/decrement buttons and calculate units per lpn
function ModifySKU_ChangeInIPPerLPN_OnClick(evt)
{
   //default handler to increment or decrement the value
   Default_NumberUpDownHandler(evt);

   ModifySKU_ComputeUnitsPerLPN();
} // ModifySKU_ChangeInIPPerLPN_OnClick

//-----------------------------------------------------------------------------
// function to change in units per ip using increment/decrement buttons and calculate units per lpn
function ModifySKU_ChangeInUnitsPerIP_OnClick(evt)
{
   //default handler to increment or decrement the value
   Default_NumberUpDownHandler(evt);

   ModifySKU_ComputeUnitsPerLPN();
} // ModifySKU_ChangeInUnitsPerIP_OnClick

//-----------------------------------------------------------------------------
// when there is change in InnerpacksperLPN or UnitsPerIP we need to calc UnitsPerLPN
function ModifySKU_ComputeUnitsPerLPN()
{

  var ipsperlpn   = $("[data-rfname='InnerPacksPerLPN']").val();
  var unitsperip  = $("[data-rfname='UnitsPerInnerPack']").val();
  //var unitsperlpn = $("[data-rfname='UnitsPerLPN']").val();

  var unitsperlpn = (parseInt(ipsperlpn) * parseInt(unitsperip));
  $("[data-rfname='UnitsPerLPN']").val(unitsperlpn);

} // ModifySKU_ComputeUnitsPerLPN

//-----------------------------------------------------------------------------
// custom handler to perform form related updates on show
function Picking_ConfirmUnitPick_OnShow()
{
  StartTimer();
  /* Highlight current pick task's row in the data table */
  var currentpicklocation = $(document).find("[data-rfname='m_BATCHPICKINFODisplayLPN']").val();
  if ((currentpicklocation != null) && (currentpicklocation != undefined))
  {
    $(document).find(".js-datatable-confirmunitpick-picklist tr td:contains(" + currentpicklocation + ")").closest("tr").addClass("amf-form-datatable-row-highlight-tablet");
    if ($(document).find(".amf-form-datatable-row-highlight-tablet").length > 0)
    {
      $(document).find(".amf-form-datatable-row-highlight-tablet")[0].scrollIntoView();
    }
  }

  // set the pickmode as TaskDetail for consolidated and call the button click event,
  // where we handled the updates. For each pick it is already set so we will not make any changes.
  if ($("[data-rfname='SelectedPickMode']").val() == "Consolidated")
  {
    $("[data-rfname='SelectedPickMode']").val("TaskDetail");
    $(document).find(".js-confirmpick-selectpickmode").trigger("click");
  }

    //DisplaySuccessMessage("Form Show Performed");
}

//-----------------------------------------------------------------------------
// custom handler to validate the picked entity
function Picking_ConfirmUnitPick_ValidatePickedEntity(evt)
{
    var inputvalue = $(evt.target).val();

    // if the user has skipped entering the value, then assume that the user wishes to
    // skip entering the value and return later
    if ((inputvalue == null) || (inputvalue == undefined) || (inputvalue == ""))
    {
        return;
    }

    var pickedentity = inputvalue; // this will be changed to SKU and sent to the backend
    var pickingconfirmscanoption = $(document).find("[data-rfname='m_BATCHPICKINFOConfirmScanOption']").val();
    var picktype = $(document).find("[data-rfname='m_BATCHPICKINFOPickType']").val();
    var picklocationtype = $(document).find("[data-rfname='m_BATCHPICKINFOLocationType']").val();

    // Convert inputvalue to upper case to compare later, as user might type the entity(inputvalue) instead of scanning.
    inputvalue = inputvalue.toUpperCase();

    // Validate scanned entity only when it is a picklane, when picking from
    // reseve or bulk as user may substitue a different LPN than suggested one
    if ((pickingconfirmscanoption != null) && (pickingconfirmscanoption != undefined) && (picklocationtype == "K"))
    {
        var isvalidvalue = false;

        // If the scanoption consists of "L", and scanned entity is LPN then set isvalidvalue to true.
        if ((pickingconfirmscanoption.indexOf("L") >= 0 /* LPN */) &&
            ($(document).find("[data-rfname='m_BATCHPICKINFOLPN']").length > 0) && (inputvalue == $(document).find("[data-rfname='m_BATCHPICKINFOLPN']").val().toUpperCase()))
        {
            isvalidvalue = true;
        }
        else // If the scanoption consists of "S", and scanned entity is SKU then set isvalidvalue to true.
            if ((pickingconfirmscanoption.indexOf("S") >= 0 /* SKU */) &&
                ($(document).find("[data-rfname='m_BATCHPICKINFOSKU']").length > 0) && (inputvalue == $(document).find("[data-rfname='m_BATCHPICKINFOSKU']").val().toUpperCase()))
            {
                isvalidvalue = true;
            }
        else // If the scanoption consists of "U", and scanned entity is UPC then set isvalidvalue to true.
            if ((pickingconfirmscanoption.indexOf("U") >= 0 /* UPC */) &&
                ($(document).find("[data-rfname='m_BATCHPICKINFOUPC']").length > 0) && (inputvalue == $(document).find("[data-rfname='m_BATCHPICKINFOUPC']").val().toUpperCase()))
            {
                isvalidvalue = true;
            }
        else // If the scanoption consists of "C", and scanned entity is CaseUPC then set isvalidvalue to true.
            if ((pickingconfirmscanoption.indexOf("C") >= 0 /* Case UPC */) &&
                ($(document).find("[data-rfname='m_BATCHPICKINFOCaseUPC']").length > 0) && (inputvalue == $(document).find("[data-rfname='m_BATCHPICKINFOCaseUPC']").val().toUpperCase()))
            {
                isvalidvalue = true;
            }
        else // If the scanoption consists of "A", and scanned entity is AlternateSKU then set isvalidvalue to true.
            if ((pickingconfirmscanoption.indexOf("A") >= 0 /* Alternate SKU */) &&
                ($(document).find("[data-rfname='m_BATCHPICKINFOAlternateSKU']").length > 0) && (inputvalue == $(document).find("[data-rfname='m_BATCHPICKINFOAlternateSKU']").val().toUpperCase()))
            {
                isvalidvalue = true;
            }
        else // If the scanoption consists of "O", and scanned entity is Location then set isvalidvalue to true.
            if ((pickingconfirmscanoption.indexOf("O") >= 0 /* Location */) &&
                ($(document).find("[data-rfname='m_BATCHPICKINFOLocation']").length > 0) && (inputvalue == $(document).find("[data-rfname='m_BATCHPICKINFOLocation']").val().toUpperCase()))
            {
                pickedentity = $(document).find("[data-rfname='m_BATCHPICKINFOSKU']").val();
                isvalidvalue = true;
            }
        else // If the scanoption consists of "*", it means that any of the entities can be scanned, then set isvalidvalue to true.
            if (pickingconfirmscanoption.indexOf("*") >= 0 /* Any ..data is validated on the SQL End */ )
            {
                isvalidvalue = true;
            }

        if (isvalidvalue == false)
        {
            DisplayErrorMessage("Please scan valid Entity");
            $(evt.target).focus();
            // do not process any further
            evt.stopPropagation();
            evt.preventDefault();
            return;
        }

        var pickingmode = $(document).find("[data-rfname='m_OPTIONSPickingMode']").val();

        if (pickingmode == 'MultiScanPick')
        {
            // save the value of the scanned input
            if ($("[name='TEMPVAR_ScannedEntity']").length <= 0)
            {
                $("form").append('<input type="hidden" name="TEMPVAR_ScannedEntity" value="0" />');
            }
            $("[name='TEMPVAR_ScannedEntity']").val(pickedentity)
            // increment the value for the scanned count
            var TEMPVAR_PickedCount = $("#TEMPVAR_PickedCount").val();
            if ($("[name='TEMPVAR_PickedCount']").length <= 0)
            {
                $("form").append('<input type="hidden" name="TEMPVAR_PickedCount" value="0" />');
            }
            var TEMPVAR_PickedCount = $("[name='TEMPVAR_PickedCount']").val();
            TEMPVAR_PickedCount = parseInt(TEMPVAR_PickedCount) + 1;
            $("[name='TEMPVAR_PickedCount']").val(TEMPVAR_PickedCount);
            $("[data-rfname='PickedUnits']").val(TEMPVAR_PickedCount);
            // reset the value in the input control
            if (parseInt(TEMPVAR_PickedCount) >= parseInt($("[data-rfname='m_BATCHPICKINFOTotalUnitsToPick']").val()))
            {
               // skip to next control
            }
            else
            {
                // there are some more to pick..so clear the input and set focus for user to scan next
                $(evt.target).val(null);
                $(evt.target).focus();
            }
        }
        else
            if (pickingmode == 'UnitScanPick')
            {
                // do nothing..let the progress move on
            }
        return isvalidvalue;
    }
}

//-----------------------------------------------------------------------------
//custom handler to execute pause picking call
function Picking_ConfirmUnitPick_PausePicking(evt)
{
    ConfirmYesNo("Are you sure you want to Pause/Stop Picking?",
        function ()
        {
            // when the user clicks yes button, do pause picking related updates
            $("#RFSkipInputValidation").val(true);
            $("[data-rfname='RFFormAction']").val("PAUSEPICKING");
            $("form").submit();
        },
        function ()
        {
            // do nothing, when the user clicks no
        });
}

//-----------------------------------------------------------------------------
//custom handler to execute skip pick call
function Picking_ConfirmUnitPick_SkipPick(evt)
{
    ConfirmYesNo("Are you sure you want to Skip Pick?",
        function ()
        {
            // do skip  picking related updates
            $("#RFSkipInputValidation").val(true);
            $("[data-rfname='RFFormAction']").val("SKIPCURRENTPICK");
            $("form").submit();
        },
        function ()
        {
            // do nothing, when the user clicks no
        });
}

//-----------------------------------------------------------------------------
//custom handler to execute short pick call
function Picking_ConfirmUnitPick_ShortPick(evt)
{
    ConfirmYesNo("Are you sure you want to Short Pick?",
        function ()
        {
            // do short pick related updates
            $("#RFSkipInputValidation").val(true);
            $("[data-rfname='ShortPick']").val("Y");
            $("form").submit();
        },
        function ()
        {
            // do nothing, when the user clicks no
        });
}

//-----------------------------------------------------------------------------
// custom handler to process the values in the form, and finalize what values to send as final values
function Picking_ConfirmUnitPick_ProcessInputs()
{
    var pickedto = $("[data-rfname='PickedTo']").val();
    if (((pickedto == null) || (pickedto == undefined)) && ($("[data-rfname='m_OPTIONSEnablePickToLPN']").val() == "N"))
    {
        $("[data-rfname='PickedTo']").val("LocationLPN");
    }
}

//-----------------------------------------------------------------------------
// custom method to validate CoO on Submit.
function Picking_ConfirmUnitPick_Submit_Request(evt)
{
    var coO = $("[data-rfname='CoO']").val();
    if (((coO == null) || (coO == "") || (coO == undefined)) && ($("[data-rfname='m_OPTIONSIsCoORequired']").val() == "Y"))
    {
        DisplayErrorMessage("CoO is required");
        $("[data-rfname='CoO']").focus();

        // do not process any further
        evt.stopPropagation();
        evt.preventDefault();
        return;
    }
    else
    {
        $('form').submit();
    }
}

//-----------------------------------------------------------------------------
//custom handler..to process the pallet validation for Drop Cart, and populate the pallet information
function Picking_DropPallet_ValidatePallet()
{
    // if we already have Pallet Id, then skip the input validation and submit the form
    var inputpalletid = $("[data-rfname='Pallet']").val();
    if ((inputpalletid != null) && (inputpalletid != undefined) && (inputpalletid != ""))
    {
        $("#RFSkipInputValidation").val(true);
        $("form").submit();
    }
}

//-----------------------------------------------------------------------------
// custom handler..to process the task validation for build cart, and populate the task inforamation
function Picking_BuildCart_ValidateTask()
{
    /* Default validations are performed on Task Id control */
    var validationresults = ValidateInputs($("[data-rfname='TaskId']"));
    if (validationresults.Root.Errors.Messages.length > 0)
    {
        DisplayMessages(validationresults.Root.Errors.Messages, Constant_MessageType_Error);
        document.body.style.cursor = "default"; // sets the cursor to default icon
        $(".amf-application-busy").addClass('hidden');
        return;
    }

    var inputtaskid = $("[data-rfname='TaskId']").val();
    if ((inputtaskid != null) && (inputtaskid != undefined) && (inputtaskid != ""))
    {
        $("#RFSkipInputValidation").val(true);
        $("form").submit();
    }
}

// custom handler..to process the validation for move LPN, and populate the inforamation
function Picking_BuildCart_ValidateTask()
{
    /* Default validations are performed on Task Id control */
    var validationresults = ValidateInputs($("[data-rfname='TaskId']"));
    if (validationresults.Root.Errors.Messages.length > 0)
    {
        DisplayMessages(validationresults.Root.Errors.Messages, Constant_MessageType_Error);
        document.body.style.cursor = "default"; // sets the cursor to default icon
        $(".amf-application-busy").addClass('hidden');
        return;
    }

    var inputtaskid = $("[data-rfname='TaskId']").val();
    if ((inputtaskid != null) && (inputtaskid != undefined) && (inputtaskid != ""))
    {
        $("#RFSkipInputValidation").val(true);
        $("form").submit();
    }

}

//custom handler to execute complete function call
function InquiryVAS_Complete(evt)
{
    // when the user clicks complete button, do VAS Complete operation
    $("#RFSkipInputValidation").val(true);
    $("[data-rfname='RFFormAction']").val("VASCOMPLETE");
    $("form").submit();
}

//*****************************************************************************
//*********************** Quantity Input Panel ********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
//custom handler to add attributes for a selector
function QuantityInputPanel_AddAttributes(selector, values)
{
  // Set values for attribute passed
  $(document).find(selector).attr(values);

} // QuantityInputPanel_AddAttributes

//-----------------------------------------------------------------------------
//custom handler to execute change in cases using increment/decrement buttons
function QuantityInputPanel_ChangeInCases_OnClick(evt)
{
   //default handler to increment or decrement the value
   Default_NumberUpDownHandler(evt);

   QuantityInputPanel_OnChangeCases();
} // QuantityInputPanel_ChangeInCases_OnClick

//-----------------------------------------------------------------------------
//custom handler to execute change in units using increment/decrement buttons
function QuantityInputPanel_ChangeInUnits1_OnClick(evt)
{
   //default handler to increment or decrement the value
   Default_NumberUpDownHandler(evt);

   QuantityInputPanel_ShowChangeUnits1();
} // QuantityInputPanel_ChangeInUnits1_OnClick

//-----------------------------------------------------------------------------
//custom handler to execute change in unitsperip using increment/decrement buttons
function QuantityInputPanel_ChangeInUnitsPerIP_OnClick(evt)
{
   //default handler to increment or decrement the value
   Default_NumberUpDownHandler(evt);

   QuantityInputPanel_OnChangeUnitsPerIP();
} // QuantityInputPanel_ChangeInUnitsPerIP_OnClick

//-----------------------------------------------------------------------------
//custom handler to execute change in units using increment/decrement buttons
function QuantityInputPanel_ChangeInUnitsPerIP1_OnClick(evt)
{
   //default handler to increment or decrement the value
   Default_NumberUpDownHandler(evt);

   QuantityInputPanel_OnChangeUnitsPerIP1();
} // QuantityInputPanel_ChangeInUnitsPerIP1_OnClick

//-----------------------------------------------------------------------------
// clear all the inputs under Input panel and set defaults for radio buttons
function QuantityInputPanel_ClearForm()
{
  // Uncheck and disable the SelectUoM options
  $("#SelectUoMInnerPacks").prop("disabled", true);
  $("#SelectUoMEaches").prop("disabled", true);
  $("#SelectUoMInnerPacks").prop("checked", false);
  $("#SelectUoMEaches").prop("checked", false);

  // Clear the input texts
  $("[data-rfname='NewInnerPacks']").val('');
  $("[data-rfname='NewUnitsPerInnerPack']").val('');
  $("[data-rfname='NewUnits']").val('');
  $("[data-rfname='NewUnitsPerInnerPack1']").val('');
  $("[data-rfname='NewUnits1']").val('');

  // show the radio group and Inputs
  $('.amf-datacard-Radiobuttons-SelectUoM').removeClass('hidden');

  // Clear the change values
  $("[data-rfjsname='ChangeInnerPacks']").text('');
  $("[data-rfjsname='ChangeUnitsPerInnerPack']").text('');
  $("[data-rfjsname='ChangeUnits']").text('');
  $("[data-rfjsname='ChangeUnitsPerInnerPack1']").text('');
  $("[data-rfjsname='ChangeUnits1']").text('');

} // QuantityInputPanel_ClearForm

//-----------------------------------------------------------------------------
// clear all the inputs under Input panel and set defaults for radio buttons
function QuantityInputPanel_ClearInputs()
{
  // Uncheck and disable the SelectUoM options
  $("#SelectUoMInnerPacks").prop("disabled", true);
  $("#SelectUoMEaches").prop("disabled", true);
  $("#SelectUoMInnerPacks").prop("checked", false);
  $("#SelectUoMEaches").prop("checked", false);

  // Clear the input texts
  $("[data-rfname='NewInnerPacks']").val('');
  $("[data-rfname='NewUnitsPerInnerPack']").val('');
  $("[data-rfname='NewUnits']").val('');
  $("[data-rfname='NewUnitsPerInnerPack1']").val('');
  $("[data-rfname='NewUnits1']").val('');

  // show the radio group and Inputs
  $('.amf-datacard-Radiobuttons-SelectUoM').removeClass('hidden');

} // QuantityInputPanel_ClearInputs

//-----------------------------------------------------------------------------
// when there is change in InnerpacksperLPN or UnitsPerIP we need to calc UnitsPerLPN
function QuantityInputPanel_ComputeUnitsPerLPN()
{

  var currentcases = $("[data-rfname='NewInnerPacks']").val();
  var currentunitsperip = $("[data-rfname='NewUnitsPerInnerPack']").val();
  var currentqty = $("[data-rfname='NewUnits']").val();

  var currentqty = (currentcases * currentunitsperip);
  $("[data-rfname='NewUnits']").val(currentqty);

  // show the change in units
  QuantityInputPanel_ShowChangeUnits();

} // QuantityInputPanel_ComputeUnitsPerLPN

//-----------------------------------------------------------------------------
// hide the radio buttons and both the input panels i.e. for InnerPacks & Eaches panels
function QuantityInputPanel_HideInputs(showunitsperip)
{

  // hide the radio buttons and eaches/innerpacks inputs
  $('.amf-datacard-Radiobuttons-SelectUoM').addClass('hidden');
  $('.amf-datacard-QuantityInputPanel-InnerPacks').addClass('hidden');
  $('.amf-datacard-QuantityInputPanel-Eaches').addClass('hidden');

  if (showunitsperip == 'N')
  {
    $('.amf-datacard-QIP-Eaches-UnitsPerInnerPack').addClass('hidden');
  }
} // QuantityInputPanel_HideInputs

//-----------------------------------------------------------------------------
// hide the radio group in quantity input panel
function QuantityInputPanel_HideUoMRadioGroup()
{
  // hide the radio group
  $('.amf-datacard-Radiobuttons-SelectUoM').addClass('hidden');

} // QuantityInputPanel_HideUoMRadioGroup

//-----------------------------------------------------------------------------
// the mininum value for InnerPacks or Units controls in QIP is 1, however, for adjustment
// we would want to allow minimum value of 0 and hence this method to initialze
function QuantityInputPanel_InitializeMin(min)
{

  // set data-rfvalidation set value for inputs
  $(document).find("[data-rfname='NewInnerPacks']").attr("data-rfvalidation-greaterorequal", min);
  //$(document).find("[data-rfname='NewUnitsPerInnerPack']").attr("data-rfvalidation-greaterorequal", min);
  //$(document).find("[data-rfname='NewUnits']").attr("data-rfvalidation-greaterorequal", min);
  //$(document).find("[data-rfname='NewUnitsPerInnerPack1']").attr("data-rfvalidation-greaterorequal", min);
  $(document).find("[data-rfname='NewUnits1']").attr("data-rfvalidation-greaterorequal", min);
} // QuantityInputPanel_InitializeMin

//-----------------------------------------------------------------------------
// set min and max value for rfvalidation-isbetween set
function QuantityInputPanel_InitializeIsBetween(totalunits, unitsperinnerpack, innerpacksperlpn, unitsperlpn, min)
{

  // set the min value as 1 if not passed
  if ((min == null) || (min == undefined) || (min == ""))
    min = 1;

  // set data-rfvalidation set value for inputs
  $(document).find("[data-rfname='NewInnerPacks']").attr("data-rfvalidation-isbetween", [min, innerpacksperlpn]);
  $(document).find("[data-rfname='NewUnitsPerInnerPack']").attr("data-rfvalidation-isbetween", [min, unitsperinnerpack]);
  $(document).find("[data-rfname='NewUnits']").attr("data-rfvalidation-isbetween", [min, totalunits]);
  $(document).find("[data-rfname='NewUnitsPerInnerPack1']").attr("data-rfvalidation-isbetween", [min, unitsperinnerpack]);
  $(document).find("[data-rfname='NewUnits1']").attr("data-rfvalidation-isbetween", [min, totalunits]);
} // QuantityInputPanel_InitializeIsBetween

//-----------------------------------------------------------------------------
// On selection of SKU, we need to initialize QIP with the values from the SKU
function QuantityInputPanel_InitializeForSKU(inventoryuom, selecteduom, storagetype, unitsperinnerpack, innerpacksperlpn, unitsperlpn)
{

  // set the selecteduom as InventoryUoM value if not passed
  if (((selecteduom == null) || (selecteduom == undefined) || (selecteduom == "")) &&
      ((storagetype == null) || (storagetype == undefined) || (storagetype == "")))
    selecteduom = inventoryuom.substring(0, 2);

  // update the values of cases/unitsperip and units
  if ((selecteduom == 'CS') || (storagetype == 'P'))
  {
    // By default we always initialize the InnerPacks and UnitsPerInnerPack as
    // defined by SKU definition - which are retreived/passed above.
      QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)
  }
  else
  // based on the Inventory UoM show the qty input panel
  // match verifies the value in storagetype having value U and is case sensitive, made these changes as some picklanes have UF as storagetype
  if ((selecteduom == 'EA') || (storagetype.match(/U/g)))
  {
    // function to show/update Eaches panel
    QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)
  }

} // QuantityInputPanel_InitializeForSKU

//-----------------------------------------------------------------------------
//custom handler to execute change in cases function call
function QuantityInputPanel_OnChangeCases()
{

  var currentcases = $("[data-rfname='NewInnerPacks']").val();
  currentcases = parseInt(currentcases);

  var initialcases = $("[data-rfname='InitialInnerPacks']").val();
  initialcases = parseInt(initialcases);

  $("[data-rfjsname='ChangeInnerPacks']").text(currentcases - initialcases);

  QuantityInputPanel_ComputeUnitsPerLPN();
} // QuantityInputPanel_OnChangeCases

//-----------------------------------------------------------------------------
//custom handler to execute change in unitsperinnerpack function call
function QuantityInputPanel_OnChangeUnitsPerIP()
{
  var currentunitsperip = $("[data-rfname='NewUnitsPerInnerPack']").val();
  currentunitsperip = parseInt(currentunitsperip);

  var initialunitsperip = $("[data-rfname='InitialUnitsPerInnerPack']").val();
  initialunitsperip = parseInt(initialunitsperip);

  $("[data-rfjsname='ChangeUnitsPerInnerPack']").text(currentunitsperip - initialunitsperip);

  QuantityInputPanel_ComputeUnitsPerLPN();

} // QuantityInputPanel_OnChangeUnitsPerIP

//-----------------------------------------------------------------------------
//custom handler to execute change in unitsperinnerpack function call
function QuantityInputPanel_OnChangeUnitsPerIP1()
{
  var currentunitsperip = $("[data-rfname='NewUnitsPerInnerPack1']").val();
  currentunitsperip = parseInt(currentunitsperip);

  var initialunitsperip = $("[data-rfname='InitialUnitsPerInnerPack1']").val();
  initialunitsperip = parseInt(initialunitsperip);

  $("[data-rfjsname='ChangeUnitsPerInnerPack1']").text(currentunitsperip - initialunitsperip);

} // QuantityInputPanel_OnChangeUnitsPerIP1

//-----------------------------------------------------------------------------
// set min and max values for rfvalidation-isbetween.
// If UoM = CS then we would use MinIPs, MaxIPs, MaxU/IP
// if UoM = EA then we would use MinUnits,MaxUnits
// Notes: When UoM = EA - we may allow UnitsPerInnerPack defined - which could be zero,
//        but never greater than maxunits itself
//        When UoM = IP - we would never have UnitsPerInnerpack as zero, so min would be 1 always
function QuantityInputPanel_SetRange(minunits, maxunits, mininnerpacks, maxinnerpacks, maxunitsperinnerpack)
{
  // if minunits is not given, default to 1
  if ((minunits == null) || (minunits == undefined) || (minunits == ""))
    minunits = 1;

  // if maxunits is not given, default to maxinnerpacks * maxunitsperinnerpack
  if (((maxunits == null) || (maxunits == undefined) || (maxunits == "")) &&
     ((maxinnerpacks > 0) && (maxunitsperinnerpack > 0)))
    maxunits = maxinnerpacks * maxunitsperinnerpack;

  // default if not given to a large realistic value
  if ((maxunits == null) || (maxunits == undefined) || (maxunits == ""))
    maxunits = 99999;

  // if mininnerpacks is not given, default to minunits
  if ((mininnerpacks == null) || (mininnerpacks == undefined) || (mininnerpacks == ""))
    mininnerpacks = minunits;

  // if maxinnerpacks is not given, default to maxunits
  if ((maxinnerpacks == null) || (maxinnerpacks == undefined) || (maxinnerpacks == ""))
    maxinnerpacks = maxunits;

  // if maxunitsperinnerpack is not given, default to maxunits
  if ((maxunitsperinnerpack == null) || (maxunitsperinnerpack == undefined) || (maxunitsperinnerpack == ""))
    maxunitsperinnerpack = maxunits;

  // maxunitsperinnerpack can never be greater than max units itself
  if (maxunitsperinnerpack > maxunits)
    maxunitsperinnerpack = maxunits;

  // set data-rfvalidation range for inputs for UoM = IP
  $(document).find("[data-rfname='NewInnerPacks']").attr("data-rfvalidation-isbetween", [mininnerpacks, maxinnerpacks]);
  $(document).find("[data-rfname='NewUnitsPerInnerPack']").attr("data-rfvalidation-isbetween", [1, maxunitsperinnerpack]);
  $(document).find("[data-rfname='NewUnits']").attr("data-rfvalidation-isbetween", [minunits, maxunits]);

  // set data-rfvalidation range for inputs for UoM = EA
  $(document).find("[data-rfname='NewUnitsPerInnerPack1']").attr("data-rfvalidation-isbetween", [0, maxunitsperinnerpack]);
  $(document).find("[data-rfname='NewUnits1']").attr("data-rfvalidation-isbetween", [minunits, maxunits]);
} // QuantityInputPanel_SetRange

//-----------------------------------------------------------------------------
// When user clicks on eaches option or it is programatically done, we have
// show the eaches part of panel only and set up the defaults
function QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)
{
  // if inventory uom is cases or location storage type is packages setup the fields
  // match verifies the value in storagetype having value U and is case sensitive, made these changes as some picklanes have UF as storagetype
  if ((selecteduom != 'EA') && (!storagetype.match(/U/g)))
  {
    return;
  }

  // Hide InnerPacks and show Eaches
  $('.amf-datacard-QuantityInputPanel-InnerPacks').addClass('hidden');
  $('.amf-datacard-QuantityInputPanel-Eaches').removeClass('hidden');

  // if inventory uom is only EA and not CS,EA or EA,CS then disable the control so user cannot change it to CS
  // match verifies the value in storagetype having value U and is case sensitive, made these changes as some picklanes have UF as storagetype
  if ((inventoryuom == 'EA') || (storagetype.match(/U/g)))
  {
    $("#SelectUoMInnerPacks").prop("disabled", true);
    $("#SelectUoMEaches").prop("disabled", false);
  }
  else
  {
    $("#SelectUoMInnerPacks").prop("disabled", false);
    $("#SelectUoMEaches").prop("disabled", false);
  }

  // check EA
  $("#SelectUoMInnerPacks").prop("checked", false);
  $("#SelectUoMEaches").prop("checked", true);

  // clear the values for Cases and setup values for eaches
  $("[data-rfname='NewInnerPacks']").val('');
  $("[data-rfname='NewUnitsPerInnerPack']").val('');
  $("[data-rfname='NewUnits']").val('');

  $("[data-rfname='NewUnitsPerInnerPack1']").val(unitsperinnerpack);
  $("[data-rfname='NewUnits1']").val(unitsperlpn);

  // For showing change
  $("[data-rfname='InitialUnitsPerInnerPack1']").val(unitsperinnerpack);
  $("[data-rfname='InitialUnits1']").val(unitsperlpn);

  // Focus on new units i.e. the total units per lpn
  $("[data-rfname='NewUnits1']").focus();

} // QuantityInputPanel_SetupEaches

//-----------------------------------------------------------------------------
// When user clicks on InnerPacks option or it is programatically done, we have
// show the InnerPacks part of panel only and set up the defaults
function QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)
{
  // if inventory uom is cases or location storage type is packages setup the fields
  if ((selecteduom != 'CS') && (storagetype != 'P'))
  {
    return;
  }

  // Show InnerPacks and hide Eaches
  $('.amf-datacard-QuantityInputPanel-InnerPacks').removeClass('hidden');
  $('.amf-datacard-QuantityInputPanel-Eaches').addClass('hidden');

  // if inventory uom is only CS and not CS,EA or EA,CS then disable the control so user cannot change it to EA
  if ((inventoryuom == 'CS') || (storagetype == 'P'))
  {
    $("#SelectUoMInnerPacks").prop("disabled", false);
    $("#SelectUoMEaches").prop("disabled", true);
  }
  else
  {
    $("#SelectUoMInnerPacks").prop("disabled", false);
    $("#SelectUoMEaches").prop("disabled", false);
  }

  // check IPs as selecteduom is CS
  $("#SelectUoMInnerPacks").prop("checked", true);
  $("#SelectUoMEaches").prop("checked", false);

  // Setup defaults for Case and clear the ones for eaches
  $("[data-rfname='NewInnerPacks']").val(innerpacksperlpn);
  $("[data-rfname='NewUnitsPerInnerPack']").val(unitsperinnerpack);
  $("[data-rfname='NewUnits']").val(innerpacksperlpn * unitsperinnerpack);

  $("[data-rfname='NewUnitsPerInnerPack1']").val('');
  $("[data-rfname='NewUnits1']").val('');

  // For showing change
  $("[data-rfname='InitialInnerPacks']").val(innerpacksperlpn);
  $("[data-rfname='InitialUnitsPerInnerPack']").val(unitsperinnerpack);
  $("[data-rfname='InitialUnits']").val(innerpacksperlpn * unitsperinnerpack);

  // Focus on new cases
  $("[data-rfname='NewInnerPacks']").focus();

} // QuantityInputPanel_SetupInnerPacks

//-----------------------------------------------------------------------------
// in some cases we need to show the difference between original values and new
// values and this method is to show or hide the changes panel
function QuantityInputPanel_ShowChangedValues(showchange)
{

  if (showchange == 'Y')
  {
    // show the on change panel
    $('.amf-datacard-QuantityInputPanel-ShowChange').removeClass('hidden');
  }
} // QuantityInputPanel_ShowChangedValues

//-----------------------------------------------------------------------------
// when Units changes, show the difference ie ChangeQty
function QuantityInputPanel_ShowChangeUnits()
{
  var currentqty = $("[data-rfname='NewUnits']").val();
  currentqty = parseInt(currentqty);

  var initialqty = $("[data-rfname='InitialUnits']").val();
  initialqty = parseInt(initialqty);

  $("[data-rfjsname='ChangeUnits']").text(currentqty - initialqty);
} // QuantityInputPanel_ShowChangeUnits

//-----------------------------------------------------------------------------
// when Units changes, show the difference ie ChangeQty
function QuantityInputPanel_ShowChangeUnits1()
{
  var currentqty = $("[data-rfname='NewUnits1']").val();
  currentqty = parseInt(currentqty);

  var initialqty = $("[data-rfname='InitialUnits1']").val();
  initialqty = parseInt(initialqty);

  $("[data-rfjsname='ChangeUnits1']").text(currentqty - initialqty);
} // QuantityInputPanel_ShowChangeUnits1

//-----------------------------------------------------------------------------
// this method checks whether user entered a valid number or not and throws an
// error if entered value is not a valid one
function QuantityInputPanel_ValidateInput(entity, value)
{

  var message = null;

  // check if user entered other than integer or not entered any value
  if ((isNaN(value)) || (value == ""))
    message = "Please enter a valid number";

  // as negative quantity is not allowed check for it
  if (value < 0)
    message = "Please enter a valid value. Negative value is not valid";

  // prevent users to scan invalid quantity. quantity above this threshold is generally considered as invalid
  if (value > 9999)
    message = "Quantity may be invalid, Maximum threshold value(9999) crossed";

  if (message != null)
  {
    DisplayErrorMessage(message);
    $(entity).focus();
    return false;
  }
  else
    return true;
} // QuantityInputPanel_ValidateInput

//-----------------------------------------------------------------------------
// this method is used to skip all the validations for inputs in the screen and
// submits the form
function SkipInputValidationsAndSubmit()
{
  $("#RFSkipInputValidation").val(true);
  $('form').submit();
} // SkipInputValidationsAndSubmit

//-----------------------------------------------------------------------------
// SKU Details data table is commonly used in many forms. This method is
// used to show the SKU and SKUDesc of selected SKU (tablerow)
function SKUInfo_SetDisplayValuesFromDT(tablerow)
{

  var [displaySKU, displaySKUDesc] = DataTableSKUDetails_GetSKUDisplayInfo (tablerow);

  // Set DisplaySKU and DisplaySKUDesc values
  $("[data-rfjsname='DisplaySKU']").text(displaySKU);
  $("[data-rfjsname='DisplaySKUDesc']").text(displaySKUDesc);

} // SKUInfo_SetDisplayValuesFromDT

//-----------------------------------------------------------------------------
// Function used to initialize SKU info panel
// Input is json object array of form elements and their values
//  If any of the values are not sent, that attribute is hidden
// Hide is a flag to hide or unhide SIP form completely
function SKUInfoPanel_Initialize(formclass, skuinput)
{
  // flag to show or hide the panel
  var show = false;

  // fetch values
  var sku             = skuinput["SKU"];
  var displaysku      = skuinput["DISPLAYSKU"];
  var displayskudesc  = skuinput["DISPLAYSKUDESC"];
  var skuimg          = skuinput["SKUIMG"];

  // Determine if the panel has to be shown or not
  if (((sku != "") && (sku != undefined)) ||
      ((displaysku != "") && (displaysku != undefined)) ||
      ((displayskudesc != "") && (displayskudesc != undefined)) ||
      ((skuimg != "") && (skuimg != undefined)))
  {
    show = true;
  }

  // Hide the entire SKU Input form
  if (!show)
  {
    $(formclass).addClass('hidden');
  }
  // Set different elements of the form
  else
  {
    // unhide the entire form
    $(formclass).removeClass('hidden');

    // SKU
    if ((sku == undefined) || (sku == ""))
    {
      $("[data-rfjsname='SIP_SKU']").addClass('hidden');
    }
    else
    {
      $("[data-rfjsname='SIP_SKU']").text(sku);
    }

    // DISPLAY SKU
    if ((displaysku == undefined) || (displaysku == ""))
    {
      $("[data-rfjsname='SIP_DisplaySKU']").addClass('hidden');
    }
    else
    {
      $("[data-rfjsname='SIP_DisplaySKU']").text(displaysku);
    }

    // DISPLAY SKU DESC
    if ((displayskudesc == undefined) || (displayskudesc == ""))
    {
      $("[data-rfjsname='SIP_DisplaySKUDesc']").addClass('hidden');
    }
    else
    {
      $("[data-rfjsname='SIP_DisplaySKUDesc']").text(displayskudesc);
    }

    // SKU IMAGE
    if ((skuimg == undefined) || (skuimg == ""))
    {
      $("[data-rfjsname='SIP_SKUIMG']").addClass('hidden');
    }
    else
    {
      $("[data-rfjsname='SIP_SKUIMG']").text(skuimg);
    }
  }
} // SKUInfoPanel_Initialize