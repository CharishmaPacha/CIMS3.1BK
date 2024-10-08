//-----------------------------------------------------------------------------
$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

  $(document).on("click", ".js-datatable-content-details tbody tr", function(evt) {
    var row           = $(this).closest("tr");
    // Changes to table structure needs a change here
    var clickedentity = row.find("td:eq(7)").text();

    // Currently calling a Validate, after moving the code to individual methods,
    // this gets addressed(This is temp but not proper method of doing)
    $("[data-rfname='SKU']").val(clickedentity);
    Receiving_ValidateAndCallOperation();
  });

  // Added the key down event to lpn input for ReceiveToLPN and to quantity in eaches and cases panel for ReceiveToLocation
  $(document).on("keydown", ".js-receivetolpn-lpn, .js-receivetolocation-NewUnits, .js-receivetolocation-NewUnits1", function(evt) {
    // The Unicode character of js keycode for enter is 13. So if user clicks on enter
    // we will call the following method
    if (evt.which === 13)
       Receiving_ValidateAndSubmit(evt);
  });

});

//-----------------------------------------------------------------------------
// function to pause receiving and return back to the receiving menu
function Receiving_PauseReceiving(evt)
{
  // Assign value as Pause
  $("[data-rfname='RFFormAction']").val("Pause");
  SkipInputValidationsAndSubmit();
} // Receiving_PauseReceiving

//*****************************************************************************
//************************ Receive ASN LPN ********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
//custom handler to check data and submit form
function Receiving_ReceiveASN_OnShow()
{
  // Get values for LPN and submit form
  var ispalletizationrequired = $(document).find("[data-rfname='m_LPNInfo_IsPalletizationRequired']").val();
  if (ispalletizationrequired == 'N')
  {
    SkipInputValidationsAndSubmit();
  }
} // Receiving_ReceiveASN_OnShow

//-----------------------------------------------------------------------------
// function to check for values and set focus for ReceiveASNLPN functionality
function Receiving_ReceiveASNLPN_OnShow()
{
  // Get value of location
  var location   = $("[data-rfname='m_ReceivingLocation']").val();
  var pallet     = $("[data-rfname='m_ReceivingPallet']").val();
  var scanpallet = $("[data-rfname='m_ScanPallet']").val();

  // If location is not scanned by user set focus to location
  if ((location == null) || (location == undefined) || (location == ""))
    $("[data-rfname='Location']").focus();
  else
  // If pallet has to be scanned and not given earlier set focus
  if ((scanpallet =='Y') && ((pallet == null) || (pallet == undefined) || (pallet == "")))
    $("[data-rfname='Pallet']").focus();
  else
    $("[data-rfname='LPN']").focus();

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // Receiving_ReceiveASNLPN_OnShow

//*****************************************************************************
//************************ Receive To Location ********************************
//*****************************************************************************

// Receive To Location can be done in two modes - scan mode where user scans
// the SKU to receive or a suggested mode where system suggests the SKU to
// receive. Default mode is determined by a control var and user can switch
// between the modes using the submenu

//-----------------------------------------------------------------------------
// When user wants to switch to the scan mode, they click on the submenu that
// invokes this method.
function Receiving_ReceiveToLocation_OnScanModeClick(evt)
{
  // Remove the previous highlighted row in the data table
  DataTableSKUDetails_ClearHighlightedRow();

  // Hide the QIP - it will be enabled later based upon the SKU scanned
  QuantityInputPanel_HideInputs();

  // clear the inputs under input panel and hide the radio group
  QuantityInputPanel_ClearForm();
  QuantityInputPanel_HideUoMRadioGroup();
  $('.amf-datacard-Location-input').addClass('hidden');

  // Set value and focus for SKU
  $("[data-rfname='SKU']").val('');
  $("[data-rfname='SKU']").focus();

} // Receiving_ReceiveToLocation_OnScanModeClick

//-----------------------------------------------------------------------------
// When the form is shown, based on the mode sent from db on form show do the
// necessary updates in form
function Receiving_ReceiveToLocation_OnShow()
{
  /* Fetch the suggested entity and mode */
  var sku  = $("[data-rfname='m_SuggestedSKU']").val();
  var mode = $("[data-rfname='m_Mode']").val();

  // if the mode is not defined or scan mode then the next set of function is not needed
  if (((mode == null) || (mode == undefined) || (mode == "") || (mode == "ScanMode")) ||
      (((sku == null) || (sku == undefined) || (sku == "")) && (mode == "SuggestedMode")))
  {
    return;
  }

  // Setup for suggested mode
  $(document).find(".js-receivetoloc-suggestedmode").trigger("click");

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // Receiving_ReceiveToLocation_OnShow

//-----------------------------------------------------------------------------
// When a SKU has been entered (scan or key entry by the user) or automatically
// based upon the mode, we need to initialize the form to facilitate receipt
// of the SKU and this method does that.
// Validate the scanned entity, highlight the SKU in the data table and set up QIP with input values(Quantity Input Panel)
function Receiving_ReceiveToLocation_OnSKUEnter(evt)
{
  /* Fetch the scanned entity and mode */
  var scannedentity = $("[data-rfname='SKU']").val();
  var mode = $("[data-rfname='m_Mode']").val();

  // if the user has skipped entering the value, then assume that the user wishes to
  // skip entering the value and return later
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
    return;
  }

  // Remove the previous highlighted row and hide all the inputs
  DataTableSKUDetails_ClearHighlightedRow();
  QuantityInputPanel_HideInputs();
  $('.amf-datacard-Location-input').addClass('hidden');

  // get the table row information
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  if ($(tablerow).length == 0)
  {
    DisplayErrorMessage("Scanned SKU is not associated with the receipt");
    $("[data-rfname='SKU']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // clear the inputs under input panel and hide the radio group
  QuantityInputPanel_ClearForm();
  QuantityInputPanel_HideUoMRadioGroup();

  // Highlight the row which has the scanned entity
  DataTableSKUDetails_HighlightRow(tablerow,scannedentity);

  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  var selecteduom = inventoryuom.substring(0, 2);
  var storagetype;
  var allownonstdcases;
  $('.amf-datacard-Location-input').removeClass('hidden');

  // Initialize the quantity input panel and set the focus
  Receiving_SetQtyToReceive(totalunits, inventoryuom, selecteduom, storagetype, allownonstdcases, unitsperinnerpack, innerpacksperlpn, unitsperlpn, mode)

  // Get the value of SortOrder
  $("[data-rfname='SortOrder']").val($($(tablerow).find("td")[33]).text());

} // Receiving_ReceiveToLocation_OnSKUEnter

//-----------------------------------------------------------------------------
// When user intends to switch to suggested mode, user would click on the
// sub-menu and it invokes this method.
// In suggested mode, we set the SKU to the suggested value from SQL and setup
// the form to behave as if the user entered that SKU.
function Receiving_ReceiveToLocation_OnSuggestedModeClick(evt)
{
  /* Fetch the suggested entity and mode */
  var suggestedentity = $("[data-rfname='m_SuggestedSKU']").val();
  var mode = $("[data-rfname='m_Mode']").val();

  // Update value of SKU, set focus and ....
  $("[data-rfname='SKU']").val(suggestedentity);
  $("[data-rfname='SKU']").focus();
  $(document).find(".js-receivetoloc-sku").trigger("blur");

} // Receiving_ReceiveToLocation_OnSuggestedModeClick

//*****************************************************************************
//*************************** Receive To LPN **********************************
//*****************************************************************************

//-----------------------------------------------------------------------------
// when user enters the SKU, we need to valid it and highlight the row in the
// datatable and set up the QuantityInputPanel
function Receiving_ReceiveToLPN_OnSKUEnter(evt)
{
  /* Fetch the scanned entity */
  var scannedentity = $("[data-rfname='SKU']").val();

  // if the user has skipped entering the value, then assume that the user wishes to
  // skip entering the value and return later
  if ((scannedentity == null) || (scannedentity == undefined) || (scannedentity == ""))
  {
      return;
  }

  // Remove the previous highlighted row and hide all the inputs
  DataTableSKUDetails_ClearHighlightedRow();
  QuantityInputPanel_HideInputs();
  $('.amf-datacard-LPN-input').addClass('hidden');

  // Validates the scanned SKU and returns the table row if it is a valid SKU.
  // if it is not in the list, tablerow is not returned
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  if ($(tablerow).length == 0)
  {
    DisplayErrorMessage("Scanned SKU is not associated with the receipt");
    $("[data-rfname='SKU']").focus();

    // do not process any further
    evt.stopPropagation();
    evt.preventDefault();
    return;
  }

  // clear the inputs under input panel and show the lpn input
  QuantityInputPanel_ClearForm();

  // show the lpn input
  $('.amf-datacard-LPN-input').removeClass('hidden');

  // Highlight the row which has the scanned entity
  DataTableSKUDetails_HighlightRow(tablerow, scannedentity);

  // get all the values of the scanned SKU from the details table
  // any changes to the table structure would require changes here
  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  var selecteduom      = inventoryuom.substring(0, 2);
  var allownonstdcases = 'N';
  var storagetype;
  var mode;// For future use

  // Initialize the quantity input panel and set the focus
  Receiving_SetQtyToReceive(totalunits, inventoryuom, selecteduom, storagetype, allownonstdcases, unitsperinnerpack, innerpacksperlpn, unitsperlpn, mode)

} // Receiving_ReceiveToLPN_OnSKUEnter

//-----------------------------------------------------------------------------
//custom handler to change input controls from eaches to cases
function Receiving_ReceiveToLPN_SelectCases_Onchange()
{
  // get the table row information
  var scannedentity;
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  var selecteduom = 'CS';
  var storagetype;

  QuantityInputPanel_SetupInnerPacks (inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)

} // Receiving_ReceiveToLPN_SelectCases_Onchange

//-----------------------------------------------------------------------------
//custom handler to change input controls from cases to eaches
function Receiving_ReceiveToLPN_SelectEaches_Onchange()
{
  // get the table row information
  var scannedentity;
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  var selecteduom = 'EA';
  var storagetype;

  QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn);

} // Receiving_ReceiveToLPN_SelectEaches_Onchange

//-----------------------------------------------------------------------------
// In Receiving, after the SKU is scanned we have to prompt the user to receive
// IPs or Eaches based upon the selecteduom and other conditions. This method
// determines the appropriate qty to receive and calls QIP functions to setup
// with the suggested qty to receive. totalunits is the total units to be received
// for the SKU under consideration
function Receiving_SetQtyToReceive(totalunits, inventoryuom, selecteduom, storagetype, allownonstdcases, unitsperinnerpack, innerpacksperlpn, unitsperlpn, mode)
{
  // update the values of cases/unitsperip and units
  if (selecteduom == 'CS')
  {
    // By default we always initialize the InnerPacks and UnitsPerInnerPack as
    // defined by SKU definition - which are retreived above. However, if
    // the qty to receive is less than that but greater than 1 Innnerpack,
    // then receive as many cases as we can.
    if (((innerpacksperlpn * unitsperinnerpack) > totalunits) &&
         (totalunits >= (1 * unitsperinnerpack)))
    {
      innerpacksperlpn = Math.trunc(totalunits/unitsperinnerpack);

      // function to show/update InnerPacks panel
      QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)
    }
    else
    // if total units is less than an innerpack, then receive it as 1 case if non std cases are allowed
    if ((totalunits < unitsperinnerpack) && (inventoryuom == 'CS') && (allownonstdcases == 'Y'))
    {
      innerpacksperlpn = 1;
      unitsperinnerpack = totalunits;

      // function to show/update InnerPacks panel
      QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)
    }
    // if total units is less than an innerpack and non std cases are not allowed, it is not possible to receive
    if ((totalunits < unitsperinnerpack) && (inventoryuom == 'CS') && (allownonstdcases == 'N'))
    {
      innerpacksperlpn = 0;
      unitsperinnerpack = 0;

      // function to show/update InnerPacks panel
      QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)
    }
    else
    // if total units is less than an innerpack, then receive it as eaches
    if ((totalunits < unitsperinnerpack) && (inventoryuom == 'EA'))
    {
      // function to show/update Eaches panel
      QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)
    }
    else
    {
      // function to show/update InnerPacks panel
      QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)
    }
  }
  else
  // update the values of unitsperip and units
  if (selecteduom == 'EA')
  {
    // For Suggested mode we need to default to Total Qty
    if (mode == 'SuggestedMode')
    {
      QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, totalunits)
    }
    else
    {
      QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)
    }
  }
} // Receiving_SetQtyToReceive

//-----------------------------------------------------------------------------
// custom handler to change input controls on clicking on table row/cell based on
// the operation
function Receiving_ValidateAndCallOperation()
{
  var currentoperation = $("[data-rfname='Operation']").val();

  if (currentoperation == 'ReceiveASNLPN')
  {
    return;
  }

  // Set the focus in SKU for triggering the focus out methods
  $("[data-rfname='SKU']").focus();

  // based on the operation call the method to set the values
  if (currentoperation == 'ReceiveToLocation')
  {
    $(document).find(".js-receivetoloc-sku").trigger("blur");
  }
  else
  if (currentoperation == 'ReceiveToLPN')
  {
    $(document).find(".js-receivetolpn-sku").trigger("blur");
  }

} // Receiving_ValidateAndCallOperation

//-----------------------------------------------------------------------------
//custom handler to validate whether user scanned value or not
function Receiving_ValidateInputs(evt)
{
  // when the form gets submitted this will be invoked
  var receivernumber = $("[data-rfname='ReceiverNumber']").val();
  var receiptnumber = $("[data-rfname='ReceiptNumber']").val();

  var message = {};
  message.Message = {};
  message.Message.DisplayText = null;

  // Check whether user scanned receiver or receipt
  if (((receivernumber == null) || (receivernumber == "") || (receivernumber == undefined)) &&
      ((receiptnumber == null) || (receiptnumber == "") || (receiptnumber == undefined)))
  {
    message.Message.DisplayText = "Please scan either a Receiver/Receipt Number";
  }

  if (message.Message.DisplayText == null)
    return null; // caller expects null when there are no validation messages
  else
    return message;
} // Receiving_ValidateInputs

//-----------------------------------------------------------------------------
// Before form is submitted, if receiving more than the remaining quantity, we
// would need to do check with user so see if the user intends to over receive
// and submit only on confirmation
function Receiving_ValidateAndSubmit(evt)
{
  var scannedentity = $("[data-rfname='SKU']").val();

  // Get the Table Row based on scanned entity
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  // Get the quantity values
  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  var scannedunitstoreceive = 0;
  var selecteduom = inventoryuom.substring(0, 2);

    // Fetch the scanned/entered quantity to receive based upon the UOM
  if (selecteduom == 'EA')
    scannedunitstoreceive = parseInt($("[data-rfname='NewUnits1']").val());
  else
  if (selecteduom == 'CS')
    scannedunitstoreceive = parseInt($("[data-rfname='NewUnits']").val());

  var [quantity, quantity1, qtytoreceive, availableqty, reservedqty, qtyordered, qtyreserved] = DataTableSKUDetails_GetQtyValues(tablerow);

  // If newly receiving qty is more than the remaining qty to receive, we acknowledge
  // the user and ask for a confirmation
  if (scannedunitstoreceive > qtytoreceive)
  {
    // This prevents form from submitting when over receiving and on user confirmation
    evt.preventDefault();

    ConfirmYesNo("Are you sure you want to over receive?",
        function ()
        {
            // submit form with quantity entered by user
            $('form').submit();
        },
        function ()
        {
            // When user clicked no, set the focus to Units input
            if (selecteduom == 'EA')
              $("[data-rfname='NewUnits1']").focus();
            else
            if (selecteduom == 'CS')
              $("[data-rfname='NewUnits']").focus();
        });
  }
  else
    // If receiving qty is less than the remaning qty to receive, submit the form
    $('form').submit();
} // Receiving_ValidateAndSubmit