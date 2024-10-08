//-----------------------------------------------------------------------------
$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

  // Currently this is written here, once we get the option to write methods for
  // table cell on click then this piece of code can be moved there
  $(document).on("click", ".js-datatable-content-details tbody tr", function(evt) {
    var row  = $(this).closest("tr");
    // Changes to table structure needs a change here
    var clickedentity = row.find("td:eq(7)").text();

    // Currently calling a Validate, after moving the code to individual methods,
    // this gets addressed(This is temp but not proper method of doing)
    $("[data-rfname='SKU']").val(clickedentity);

    // Set the focus in SKU for triggering the focus out methods
    $("[data-rfname='SKU']").focus();
    $(document).find(".js-misc-completerework-sku").trigger("blur");
  });

});

//*****************************************************************************
//************************ Complete Rework ********************************
//*****************************************************************************

// Complete Rework can be done in two modes - scan mode where user scans
// the SKU to receive or a suggested mode where system suggests the SKU to
// receive. Default mode is determined by a control var and user can switch
// between the modes using the submenu

//-----------------------------------------------------------------------------
// When user wants to switch to the scan mode, they click on the submenu that
// invokes this method.
function Misc_CompleteRework_OnScanModeClick(evt)
{
  // Remove the previous highlighted row in the data table
  DataTableSKUDetails_ClearHighlightedRow();

  // Hide the QIP - it will be enabled later based upon the SKU scanned
  QuantityInputPanel_HideInputs('N');

  // clear the inputs under input panel and hide the radio group
  QuantityInputPanel_ClearForm();
  QuantityInputPanel_HideUoMRadioGroup();

  // Set value and focus for SKU
  $("[data-rfname='SKU']").val('');
  $("[data-rfname='SKU']").focus();

} // Misc_CompleteRework_OnScanModeClick

//-----------------------------------------------------------------------------
// When the form is shown, based on the mode sent from db on form show do the
// necessary updates in form
function Misc_CompleteRework_OnShow()
{
  /* Fetch the suggested entity and mode */
  var sku  = $("[data-rfname='m_SuggestedSKU']").val();
  var mode = $("[data-rfname='m_Mode']").val();

  // if the mode is not defined or scan mode then the next set of function is not needed
  if (((mode == null) || (mode == undefined) || (mode == "") || (mode == "ScanMode")) ||
      (((sku == null) || (sku == undefined) || (sku == "")) && (mode == "Suggested")))
  {
    return;
  }

  // Setup for suggested mode
  $(document).find(".js-misc-completerework-suggestedmode").trigger("click");

  // set the focus flag to true, to indicate the focus is already set by this method
  // further methods called by base framework for focus setting will verify this flag and skip setting focus
  SetFocusFlagValue(true);
} // Misc_CompleteRework_OnShow

//-----------------------------------------------------------------------------
// When a SKU has been entered (scan or key entry by the user) or automatically
// based upon the mode, we need to initialize the form to facilitate order
// of the SKU and this method does that.
// Validate the scanned entity, highlight the SKU in the data table and set up QIP with input values(Quantity Input Panel)
function Misc_CompleteRework_OnSKUEnter(evt)
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
  QuantityInputPanel_HideInputs('N');

  // get the table row information
  var tablerow = DataTableSKUDetails_GetTableRow(scannedentity);

  if ($(tablerow).length == 0)
  {
    DisplayErrorMessage("Scanned SKU is not associated with the order");
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
  DataTableSKUDetails_HighlightRow(tablerow, scannedentity);

  var [totalunits, inventoryuom, unitsperinnerpack, innerpacksperlpn, unitsperlpn] = DataTableSKUDetails_GetSKUValues(tablerow);

  // Qty -- UnitsAuthorizedToShip, Qty1 -- UnitsAssigned, Qty2 -- UnitsToAllocate
  var [quantity, quantity1, quantity2, availableqty, reservedqty, qtyordered, qtyreserved] = DataTableSKUDetails_GetQtyValues(tablerow);

  var selecteduom = inventoryuom.substring(0, 2);
  var storagetype;
  var allownonstdcases;

  // Initialize the quantity input panel and set the focus
  Misc_CompleteRework_SetQty(quantity2, inventoryuom, selecteduom, storagetype, allownonstdcases, unitsperinnerpack, innerpacksperlpn, unitsperlpn, mode)

  // Get the value of SKUId and SortOrder of scanned/suggested SKU
  $("[data-rfname='SKUId']").val($($(tablerow).find("td")[32]).text());
  $("[data-rfname='SortOrder']").val($($(tablerow).find("td")[33]).text());

} // Misc_CompleteRework_OnSKUEnter

//-----------------------------------------------------------------------------
// When user intends to switch to suggested mode, user would click on the
// sub-menu and it invokes this method.
// In suggested mode, we set the SKU to the suggested value from SQL and setup
// the form to behave as if the user entered that SKU.
function Misc_CompleteRework_OnSuggestedModeClick(evt)
{
  /* Fetch the suggested entity and mode */
  var suggestedentity = $("[data-rfname='m_SuggestedSKU']").val();
  var mode = $("[data-rfname='m_Mode']").val();

  // Update value of SKU, set focus and ....
  $("[data-rfname='SKU']").val(suggestedentity);
  $("[data-rfname='SKU']").focus();
  $(document).find(".js-misc-completerework-sku").trigger("blur");

} // Misc_CompleteRework_OnSuggestedModeClick

//-----------------------------------------------------------------------------
//custom handler to execute Pause function call
function Misc_CompleteRework_Pause(evt)
{
  // when the user clicks complete button, assign value to RFFormAction
  $("#RFSkipInputValidation").val(true);
  $("[data-rfname='RFFormAction']").val("Pause");
  $("form").submit();
} // Misc_CompleteRework_Pause

//-----------------------------------------------------------------------------
// In Receiving, after the SKU is scanned we have to prompt the user to get
// IPs or Eaches based upon the selecteduom and other conditions. This method
// determines the appropriate qty and calls QIP functions to setup with the
// suggested mode. totalunits is the total units to be allocated for the SKU
// under consideration
function Misc_CompleteRework_SetQty(quantity2, inventoryuom, selecteduom, storagetype, allownonstdcases, unitsperinnerpack, innerpacksperlpn, unitsperlpn, mode)
{
  // update the values of cases/unitsperip and units
  if (selecteduom == 'CS')
  {
    // By default we always initialize the InnerPacks and UnitsPerInnerPack as
    // defined by SKU definition - which are retreived above. However, if
    // the qty to receive is less than that but greater than 1 Innnerpack,
    // then receive as many cases as we can.
    if (((innerpacksperlpn * unitsperinnerpack) > quantity2) &&
         (quantity2 >= (1 * unitsperinnerpack)))
    {
      innerpacksperlpn = Math.trunc(quantity2/unitsperinnerpack);

      // function to show/update InnerPacks panel
      QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)
    }
    else
    // if total units is less than an innerpack, then receive it as 1 case if non std cases are allowed
    if ((quantity2 < unitsperinnerpack) && (inventoryuom == 'CS') && (allownonstdcases == 'Y'))
    {
      innerpacksperlpn = 1;
      unitsperinnerpack = quantity2;

      // function to show/update InnerPacks panel
      QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)
    }
    // if total units is less than an innerpack and non std cases are not allowed, it is not possible to receive
    if ((quantity2 < unitsperinnerpack) && (inventoryuom == 'CS') && (allownonstdcases == 'N'))
    {
      innerpacksperlpn = 0;
      unitsperinnerpack = 0;

      // function to show/update InnerPacks panel
      QuantityInputPanel_SetupInnerPacks(inventoryuom, selecteduom, storagetype, innerpacksperlpn, unitsperinnerpack)
    }
    else
    // if total units is less than an innerpack, then receive it as eaches
    if ((quantity2 < unitsperinnerpack) && (inventoryuom == 'EA'))
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
    if (mode == 'Suggested')
    {
      QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, quantity2)
    }
    else
    {
      QuantityInputPanel_SetupEaches(inventoryuom, selecteduom, storagetype, unitsperinnerpack, unitsperlpn)
    }
  }
} // Misc_CompleteRework_SetQty
