//-----------------------------------------------------------------------------
$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

});

//-----------------------------------------------------------------------------
//custom handler to go back to scan location screen
function Putaway_PAByLocation_Complete(evt)
{
    // when the user clicks complete button, do VAS Complete operation
    $("#RFSkipInputValidation").val(true);
    $("[data-rfname='RFFormAction']").val("Completed");
    $("form").submit();
}

//-----------------------------------------------------------------------------
//custom handler to set focus to next input
function Putaway_PALPN_ConfirmQtyCheckBox_Onchange()
{
   //This is used to set focus to Location when user checks or unchecks confirms qty
   $("[data-rfname='ScannedLocation']").focus();
}

//-----------------------------------------------------------------------------
//custom handler to execute complete function call
function Putaway_PALPN_ConfirmQtyValidation()
{
   var message = null;
   var QtyConfirmed = $("[data-rfname='ConfirmQty']").prop('checked');

   if (((QtyConfirmed == null) || (QtyConfirmed == "") || (QtyConfirmed == false) || (QtyConfirmed == undefined)) &&
      ($("[data-rfname='m_ConfirmQtyRequired']").val() == "Y"))
   {
     message = {};
     message.Message = {};
     message.Message.DisplayText = "Please confirm the quantity of the LPN being Putaway";
   }

   return message;
}

//-----------------------------------------------------------------------------
//This is used to set focus to Location when user enters value for Qty
function Putaway_PALPN_OnChangePAQty()
{
    $("[data-rfname='ScannedLocation']").focus();
}

//-----------------------------------------------------------------------------
//This is used to set focus to Location when user clicks on increment or decrement of Qty
function Putaway_PALPN_OnClickPAQty(evt)
{
    //default handler to increment or decrement the value
    Default_NumberUpDownHandler(evt);

    $("[data-rfname='ScannedLocation']").focus();
}

//-----------------------------------------------------------------------------
// custom handler to perform form related updates on show
function Putaway_PAToPicklane_OnShow()
{
    StartTimer();
    /* Highlight current putaway lpn row in the data table */
    var currentputawaysku = $(document).find("[data-rfname='m_PADetails_SKU']").val();
    if ((currentputawaysku != null) && (currentputawaysku != undefined))
    {
        $(document).find('.js-datatable-confirmputawaylpn-palist tr td').filter(function () { return ($(this).text() === currentputawaysku); }).closest("tr").addClass("amf-form-datatable-row-highlight-tablet");
        $(document).find(".amf-form-datatable-row-highlight-tablet")[0].scrollIntoView();
    }

    //DisplaySuccessMessage("Form Show Performed");
}

//-----------------------------------------------------------------------------
//custom handler to go back to scan pallet screen
function Putaway_PAToPickLane_PausePA(evt)
{
    ConfirmYesNo("Are you sure you want to Pause/Stop Putaway?",
        function ()
        {
          // when the user clicks cancel button, navigate back to scan pallet screen
          $("[data-rfname='RFFormAction']").val("PAUSEPUTAWAY");
          $("#RFSkipInputValidation").val(true);
          $("form").submit();
        },
        function ()
        {
            // do nothing, when the user clicks no
        });
}

//-----------------------------------------------------------------------------
//custom handler to execute skip pick call
function Putaway_PAToPickLane_SkipSKU(evt)
{
    ConfirmYesNo("Are you sure you want to Skip SKU?",
        function ()
        {
            // do skip  picking related updates
            $("#RFSkipInputValidation").val(true);
            $("[data-rfname='RFFormAction']").val("SKIPCURRENTSKU");
            $("form").submit();
        },
        function ()
        {
            // do nothing, when the user clicks no
        });
}

//-----------------------------------------------------------------------------
// custom handler to validate the scanned SKU
function Putaway_PAToPicklane_ValidateSKU(evt)
{
  var inputvalue = $(evt.target).val();

  var scannedsku = inputvalue;

    // if the user has skipped entering the value, then assume that the user wishes to
    // skip entering the value and return later
    if ((inputvalue == null) || (inputvalue == undefined) || (inputvalue == ""))
    {
        return;
    }

  // Convert inputvalue to upper case to compare later, as user might type the entity(inputvalue) instead of scanning.
  inputvalue = inputvalue.toUpperCase();

  if ((inputvalue != null) && (inputvalue != undefined))
  {
    var isvalidvalue = false;

    if ((inputvalue == $("[data-rfjsname='SKU']").attr("data-rfvalue").toUpperCase()) || (inputvalue == $("[data-rfjsname='UPC']").attr("data-rfvalue").toUpperCase()))
    {
      isvalidvalue = true;
    }
    else
    if (isvalidvalue == false)
    {
      DisplayErrorMessage("Please scan valid SKU/UPC");
      $(evt.target).val(null);
      $(evt.target).focus();
      // do not process any further
      evt.stopPropagation();
      evt.preventDefault();
      return;
    }
    return isvalidvalue;
  }
}
