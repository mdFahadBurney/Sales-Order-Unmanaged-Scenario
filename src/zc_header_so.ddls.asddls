@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Header Consumption View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_HEADER_SO as projection on ZI_HEADER_SO
{
        @Consumption.valueHelpDefinition: [{ entity:{name: 'ZI_ORDER_NUMBER_VH', element: 'Value' } }]

    key OrderNo,
        @Consumption.valueHelpDefinition: [{ entity:{name: 'Z_I_STATUS_DOM_11563', element: 'Value' } }]
    OrderStatus,
    Criticality,
    OrderDate,
    
    CustNumber,
    CustDesc,
    /* Associations */
    _SOItem : redirected to composition child ZC_ITEM_SO,
    LocalLastChangedAt
    
  //  ,    _SOWhse : redirected to composition child ZC_WHSE_SO
}
