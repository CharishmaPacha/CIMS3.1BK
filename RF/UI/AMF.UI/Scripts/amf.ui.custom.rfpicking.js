$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

  $(document).on("click", ".js-datatable-content-details tbody tr", function(evt) {
    var row           = $(this).closest("tr");
    var clickedentity = row.find("td:eq(7)").text(); // This will be SKU value
    var invclass1     = row.find("td:eq(21)").text();
    var invclass2     = row.find("td:eq(22)").text();
    var invclass3     = row.find("td:eq(23)").text();

    // when the user taps on a SKU to get the available lpns
    //$("#RFSkipInputValidation").val(true);
    //$("[data-rfname='RFFormAction']").val("GetAvailableLPNs");
    //$("[data-rfname='SelectedSKU']").val(clickedentity);
    //$("[data-rfname='InventoryClass1']").val(invclass1);
    //$("[data-rfname='InventoryClass2']").val(invclass2);
    //$("[data-rfname='InventoryClass3']").val(invclass3);

    // Clear the previously highlighted row if any and highlight the row on which user clicked
    DataTableSKUDetails_ClearHighlightedRow();
    DataTableSKUDetails_HighlightRow(row);

    // below method invokes a different workflow
    Picking_LPNReservation_StyleInquiryForSelectedSKU(clickedentity, invclass1);
    //$("form").submit(); -- Not needed
  });

  // This is a key press event to filter value in LPN Reservation
  $("[data-rfname='FilterValue']").on("keyup", function() {
    var searchvalue = $(this).val().toLowerCase();
    Picking_LPNReservation_FilterValueEntered(searchvalue);
  });

});
//*****************************************************************************
//************************** LPN Activation ***********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// Activate the LPN when user clicks on Confirm button
function Picking_LPNActivation_OnConfirm()
{
  $("form").submit();
}

//-----------------------------------------------------------------------------
// User can pick all units From the location for the To LPN or each individual
// TaskDetail. Using this button, user can toggle between the two pick modes
// When the mode is changed, we have to setup the UnitsToPick and other fields
// appropriate for the mode
function Picking_ConfirmUnitPick_SetPickMode(evt)
{
  // fetch the current picking mode
  var pickingmode = $("[data-rfname='SelectedPickMode']").val();

  if (pickingmode == "Consolidated") // currently Consolidated, switching to TaskDetail
  {
    // switch to TaskDetail mode
    $("[data-rfname='SelectedPickMode']").val("TaskDetail");
    var taskdetailqty = $("[data-rfname='m_BATCHPICKINFOTotalUnitsToPick']").val();

    // change the caption of the button to show new mode
    $("#CurrentPickMode").text("PickMode: Individual Pick");

    // set the DisplayUnitsToPick, UnitsToConfirm and validation to be approrpriate for this mode
    $("[data-rfjsname='ToPickQty']").text($("[data-rfname='m_BATCHPICKINFODisplayToPickQty']").val());
    $("[data-rfname='PickedUnits']").val($("[data-rfname='m_OPTIONSDefaultQuantity']").val());
    $(document).find("[data-rfname='PickedUnits']").attr("data-rfvalidation-lesserorequal", taskdetailqty);
  }
  else
  if (pickingmode == "TaskDetail") // currently TaskDetail, switching to Consolidated
  {
    // switch mode to Consolidated
    $("[data-rfname='SelectedPickMode']").val("Consolidated");
    var consolidatedqty = $("[data-rfname='m_BATCHPICKINFOConsolidatedUnitsToPick']").val();

    // change the caption of the button to show new mode
    $("#CurrentPickMode").text("PickMode: Consolidated");

    // set the DisplayUnitsToPick, UnitsToConfirm and validation to be approrpriate for this mode
    $("[data-rfjsname='ToPickQty']").text($("[data-rfname='m_BATCHPICKINFOConsolidatedUnitsToPickDisplay']").val());
    $("[data-rfname='PickedUnits']").val($("[data-rfname='m_BATCHPICKINFOConsolidatedUnitsToPick']").val());
    $(document).find("[data-rfname='PickedUnits']").attr("data-rfvalidation-lesserorequal", consolidatedqty);
  }

}// Picking_ConfirmUnitPick_SetPickMode

//*****************************************************************************
//************************** LPN Activation ***********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// Method to verify and automatically confirm the validated LPN
function Picking_LPNActivation_InfoOnShow()
{
  // For some waves, we need to confirm directly without having the user to click confirm button
  if ($("[data-rfname='m_AutoConfirm']").val() == "Y")
  {
    $("form").submit();
  }
}

//-----------------------------------------------------------------------------
// We will fetch the LPN value, if it is previously scanned and a valid one then
// same value will be returned and in that case we will set focus to LPN. Rest all
// cases focus will be set to Pallet.
function Picking_LPNActivation_InputOnShow()
{
  // Fetch lpn value if scanned along with autoconfirmed value
  var lpnvalue       = $("[data-rfname='m_LPNInfo_LPN']").val();
  var islpnconfirmed = $("[data-rfname='m_LPNAutoConfirmed']").val();
  var promptpallet   = $("[data-rfname='m_PromptPallet']").val();
  var prevlpn        = $("[data-rfname='m_PrevLPN']").val();

  // clear the value in LPN input
  if (islpnconfirmed == "Y")
  {
    $("[data-rfname='LPN']").val(null);
  }

  if (promptpallet == "Y")
  {
    $("[data-rfname='Pallet']").focus();
  }
  // Set focus on LPN
  else
  if ((promptpallet == "N") || ((prevlpn != undefined) && (prevlpn != "")))
  {
    $("[data-rfname='LPN']").focus();
  }
  else
    $("[data-rfname='Pallet']").focus();

  SetFocusFlagValue(true);
}

//-----------------------------------------------------------------------------
// Function after pallet is scanned
function Picking_LPNActivation_OnPalletScan()
{
  var palletscanned = $("[data-rfname='Pallet']").val();

  if ((palletscanned != undefined) && (palletscanned != ""))
    $("[data-rfname='LPN']").focus();
}

//-----------------------------------------------------------------------------
// Validate the inputs when user has clicked on submit button
function Picking_LPNActivation_OnSubmit()
{
  var prevpallet     = $("[data-rfname='m_PalletInfo_Pallet']").val();
  var currentpallet  = $("[data-rfname='Pallet']").val();

  // Raise warning if
  // same lpn is scanned with the same Pallet Info
  if (($("[data-rfname='LPN']").val() == $("[data-rfname='m_PrevLPN']").val()) &&
      (prevpallet != undefined) && (prevpallet != "") && (prevpallet == currentpallet))
  {
    DisplayWarningMessage("LPN & Pallet combination already scanned!");
  }
  // Normally, submit the form
  else
  {
    $("[data-rfname='RFFormAction']").val("Validate");
    $("form").submit();
  }
}

//*****************************************************************************
//**************************** LPN Picking ************************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// custom handler to perform form related updates on show
function Picking_LPNPickConfirm_OnShow()
{
    StartTimer();
    /* Highlight current pick task's row in the data table */
    var currentpicklocation = $(document).find("[data-rfname='m_LPNPickInfo_LPN']").val();
    if ((currentpicklocation != null) && (currentpicklocation != undefined))
    {
        $(document).find(".js-datatable-confirmlpnpick-picklist tr td:contains(" + currentpicklocation + ")").closest("tr").addClass("amf-form-datatable-row-highlight-tablet");
        if ($(document).find(".amf-form-datatable-row-highlight-tablet").length > 0)
        {
            $(document).find(".amf-form-datatable-row-highlight-tablet")[0].scrollIntoView();
        }
    }

    //DisplaySuccessMessage("Form Show Performed");
}

//-----------------------------------------------------------------------------
//custom handler to execute skip pick call
function Picking_LPNPick_SkipPick(evt)
{
    ConfirmYesNo("Are you sure you want to Skip Pick?",
        function ()
        {
            // do skip picking related updates
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
//custom handler to execute pause pick call
function Picking_LPNPick_PausePicking(evt)
{
    ConfirmYesNo("Are you sure you want to Pause/Stop Picking??",
        function ()
        {
            // do skip picking related updates
            $("#RFSkipInputValidation").val(true);
            $("[data-rfname='RFFormAction']").val("PAUSEPICKING");
            $("form").submit();
        },
        function ()
        {
            // do nothing, when the user clicks no
        });
}

//*****************************************************************************
//************************** LPN Reservation **********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
//custom handler to execute Complete/Pause Reservation function call
function Picking_LPNReservation_CompleteOrPause(evt)
{
  // when the user clicks complete button, assign value to RFFormAction
  $("[data-rfname='RFFormAction']").val("CompleteReservation");
  SkipInputValidationsAndSubmit();
} // Picking_LPNReservation_CompleteOrPause

//-----------------------------------------------------------------------------
// This method filters the value and shows rows with value entered by the
// user. If no matches are found then nothing will get displayed in table
function Picking_LPNReservation_FilterValueEntered(searchvalue)
{
  $(".js-datatable-content-details tbody tr").filter(function() {
    $(this).toggle($(this).text().toLowerCase().indexOf(searchvalue) > -1)
  });

} // Picking_LPNReservation_FilterValueEntered

//-----------------------------------------------------------------------------
function Picking_LPNReservation_StyleInquiryForSelectedSKU(selectedentity, invclass1)
{
  // do the part which needs to invoke the Style Inquiry to a new window

  // save current work flow details and set work flow information for the new one
  var currentform = $("#CurrentFormName").val();
  var currentworkflowname = $("#CurrentWorkFlowName").val();
  var currentformsequence = $("#CurrentFormSequence").val();
  var currentparentmenu = $("#CurrentParentMenu").val();

  // update the work flow information for the new one to the form vars
  $("#CurrentFormName").val("Inquiry_SKUStyle");
  $("#CurrentWorkFlowName").val("Inquiry_SKUStyle");
  $("#CurrentFormSequence").val("1");
  $("#CurrentParentMenu").val("rfinquiry");

  // process the input passed to this method
  var inputdata = {};
  inputdata["SKU"] = selectedentity;
  inputdata["InventoryClass1"] = invclass1;
  var currentActionInput = {};
  currentActionInput.Data = inputdata;
  // set form target to a new window
  var newwindowname = selectedentity + "Inquiry";
  var newwindow = window.open("", newwindowname); // creates a new tab with blank page
  $("form").attr("target", newwindowname);

  // prevent the input validation
  $("#RFSkipInputValidation").val(true);
  // prevent the input data collection, and assign the input value
  $("#RFSkipInputCollection").val(true);

  // save input value list into hidden input controls
  $("#RFFormInputData").val(JSON.stringify(currentActionInput));

  // submit form to deliver the user input, and perform action
  $("form").submit();
  // reset form target back to earlier, from new window
  $("form").removeAttr("target"); // clear target attribute, for further calls

  // restore current work flow information from which this method is
  // invoked
  $("#CurrentFormName").val(currentform);
  $("#CurrentWorkFlowName").val(currentworkflowname);
  $("#CurrentFormSequence").val(currentformsequence);
  $("#CurrentParentMenu").val(currentparentmenu);

  // reset the flags for input collection and validation
  ResetInputCollectionFlag();
  ResetInputValidationFlag();

  // hide busy indicator
  $(".amf-application-busy").addClass('hidden');
  document.body.style.cursor = "default"; // sets the cursor to default icon
} // Picking_LPNReservation_StyleInquiryForSelectedSKU

//-----------------------------------------------------------------------------
// Validate the scanned lpn from the list and set input values for QIP(Quantity Input Panel)
function Picking_LPNReservation_OnLPNEnter(evt)
{
  var lpn    = $("[data-rfname='LPN']").val();
  var option = $("[data-rfname='AllocateOption']").val();

  // user is yet to scan lpn
  if ((lpn == null) || (lpn == undefined) || (lpn == ""))
  {
    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // when the user scans lpn, assign value to RFFormAction
  $("#RFSkipInputValidation").val(true);

  if (option == 'A')
  {
    $("[data-rfname='RFFormAction']").val("ValidateLPN");
  }
  else
  if (option == 'U')
  {
    $("[data-rfname='RFFormAction']").val("UnallocateLPN");
  }
  $("form").submit();
} // Picking_LPNReservation_OnLPNEnter

//-----------------------------------------------------------------------------
// Validate the scanned entity, highlight the row and set input  values for QIP(Quantity Input Panel)
function Picking_LPNReservation_OnShow()
{
  // Fetch the scanned wave and other required information
  var waveno            = $("[data-rfname='m_WaveInfo_WaveNo']").val();
  var pickticket        = $("[data-rfname='m_OrderInfo_PickTicket']").val();
  var lpnid             = $("[data-rfname='m_LPNReservationInfo_LPNId']").val();
  var lpn               = $("[data-rfname='m_LPNReservationInfo_LPN']").val();
  var valuetofilter     = $("[data-rfname='m_LPNReservationInfo_FilterValue']").val();
  var promptpallet      = $("[data-rfname='m_PromptPallet']").val();
  lpnid = parseInt(lpnid);

  // user is yet to scan either waveno or pickticket
  if (((waveno == null) || (waveno == undefined) || (waveno == "")) &&
      (pickticket == null) || (pickticket = undefined) || (pickticket == ""))
  {
    return;
  }

  // show the LPN and Pallet input for the user
  $('.amf-datacard-scanlpn-input').removeClass('hidden');
  $('.amf-datacard-scanpallet-input').removeClass('hidden');

  // if filter value is present then call the filter value entered method to filter
  // the data. Currently we will show rows with hidden data as well if matches
  if (valuetofilter)
  {
    var searchvalue  = valuetofilter.toLowerCase();;
    Picking_LPNReservation_FilterValueEntered(searchvalue);
  }

  //  if lpn is scanned and returned a valid lpn
  if (lpnid > 0)
  {
    // Hide the units/case under QIP for LPN Reservation and also clear all inputs
    DataTableSKUDetails_ClearHighlightedRow();
    QuantityInputPanel_HideInputs('N');
    QuantityInputPanel_ClearForm();

    // Get the SKU and highlight the row
    var sku  = $("[data-rfname='m_LPNReservationInfo_SKU']").val();

    // get the table row information
    var tablerow = DataTableSKUDetails_GetTableRow(sku);
    DataTableSKUDetails_HighlightRow(tablerow, sku);

    // set value of LPN
    $("[data-rfname='LPN']").val(lpn);

    // Get the LPN Qty
    var lpnqty = $("[data-rfname='m_LPNReservationInfo_AllocableQty']").val();

    // Get required Qty (quantity1) for the SKU
    var [quantity, quantity1, quantity2, availableqty, reservedqty, qtyordered, qtyreserved] = DataTableSKUDetails_GetQtyValues(tablerow);

    // Set the units per lpn to be minimum of needed qty and LPN qty
    var unitsperlpn  = Math.min(parseInt(quantity2), parseInt(lpnqty));
    var inventoryuom = 'EA';
    var selecteduom  = 'EA';
    var storagetype;
    var unitsperinnerpack;

    // function to show/update Eaches panel
    QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)
  }
  else
  if (promptpallet == "Y")
  {
    $("[data-rfname='Pallet']").focus();
  }
  else
    $("[data-rfname='LPN']").focus();

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // Picking_LPNReservation_OnShow

//-----------------------------------------------------------------------------
// custom handler to validate whether user scanned value or not
// when the form gets submitted after scanning Wave/PT this will be invoked
function Picking_LPNReservation_ValidateInputs(evt)
{
  // Fetch the value of inputs to validate
  var waveno     = $("[data-rfname='WaveNo']").val();
  var pickticket = $("[data-rfname='PickTicket']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  // Check whether user scanned waveno or pickticket
  if (((waveno == null) || (waveno == "") || (waveno == undefined)) &&
      ((pickticket == null) || (pickticket == "") || (pickticket == undefined)))
  {
    message.Message.DisplayText = "Please scan either WaveNo/PickTicket";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Picking_LPNReservation_ValidateInputs
