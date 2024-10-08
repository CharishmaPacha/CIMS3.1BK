//-----------------------------------------------------------------------------
$(document).ready(function ()
{
    // Add any code which needs to happen for all functionality
    // Be very careful in adding code here, as this will impact all the screens and features
    // where this js file gets loaded

});

//-----------------------------------------------------------------------------
// custom handler to perform form related updates on show
function Replenishment_LPNPickConfirm_OnShow()
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
function Replenishment_LPNPick_SkipPick(evt)
{
    ConfirmYesNo("Are you sure you want to Skip Pick?",
        function ()
        {
            // do skip picking related updates
            $("[data-rfname='RFFormAction']").val("SKIPCURRENTPICK");
            SkipInputValidationsAndSubmit();
        },
        function ()
        {
            // do nothing, when the user clicks no
        });
}

//-----------------------------------------------------------------------------
//custom handler to execute pause pick call
function Replenishment_LPNPick_PausePicking(evt)
{
    ConfirmYesNo("Are you sure you want to Pause/Stop Picking??",
        function ()
        {
            // do pause picking related updates
            $("[data-rfname='RFFormAction']").val("PAUSEPICKING");
            SkipInputValidationsAndSubmit();
        },
        function ()
        {
            // do nothing, when the user clicks no
        });
}

//-----------------------------------------------------------------------------
//This is used to set focus to Location when user clicks on increment or decrement of Qty
function Putaway_PutawayLPN_OnClickPAQty(evt)
{
    //default handler to increment or decrement the value
    Default_NumberUpDownHandler(evt);

    $("[data-rfname='ScannedLocation']").focus();
}

//-----------------------------------------------------------------------------
//This is used to set focus to Location when user enters value for Qty
function Putaway_PutawayLPN_OnChangePAQty()
{
    $("[data-rfname='ScannedLocation']").focus();
}
