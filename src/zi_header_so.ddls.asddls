@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales Order Interface View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_HEADER_SO as select from zso_header_mfb
composition[0..*] of ZI_ITEM_SO as _SOItem
//composition[0..*] of ZI_WHSE_SO as _SOWhse
{
    key so_number as OrderNo,
    order_status as OrderStatus,
        case order_status
    when 'In Progress' then 2
    when 'Approve' then 3
    when 'Reject' then  1 
    else 2
    end as Criticality,
    so_date as OrderDate,
    cust_number as CustNumber,
    cust_desc as CustDesc,
    @Semantics.systemDateTime.localInstanceLastChangedAt: true
    locallastchangedat as LocalLastChangedAt,
    /* Associations */
    _SOItem //,
  //  _SOWhse
}
