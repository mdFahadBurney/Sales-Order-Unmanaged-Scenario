@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Item Consumption View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_ITEM_SO as projection on ZI_ITEM_SO
{
    key OrderNo,
    key ItemNo,
    MaterialNo,
    MaterialDesc,
    @Semantics.amount.currencyCode: 'Currency'
    ItemAmt,
    @Consumption.valueHelpDefinition: [{ entity:{name: 'I_CurrencyStdVH', element: 'Currency' } }]
    Currency,
    
    /* Associations */
    _SOHeader : redirected to parent ZC_HEADER_SO,
    _SOWhse : redirected to composition child ZC_WHSE_SO
}
