CLASS lhc__SOHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION.

    CLASS-DATA : mt_root_to_create TYPE STANDARD TABLE OF zso_header_mfb,
                 ms_root_to_create TYPE zso_header_mfb.
    CLASS-DATA : lt_root_update    TYPE STANDARD TABLE OF zso_header_mfb,
                 ls_root_update    TYPE zso_header_mfb,
                 mt_root_to_update TYPE STANDARD TABLE OF zso_header_mfb,
                 mt_action         TYPE STANDARD TABLE OF zso_header_mfb.
    CLASS-DATA : Ls_item TYPE zso_item_mfb.
    CLASS-DATA : ls_whse TYPE zso_whse_mfb.

    CLASS-DATA : lt_whse_create TYPE STANDARD TABLE OF zso_whse_mfb.
    CLASS-METHODS : get_next_salesOrderNo RETURNING VALUE(r_docno_val) TYPE ztorder_no.

    CLASS-DATA : lt_head_delete TYPE STANDARD TABLE OF zso_header_mfb,
                 ls_head_delete TYPE zso_header_mfb.

    CLASS-DATA :mt_item TYPE STANDARD TABLE OF zso_item_mfb.

    CLASS-METHODS : checkField IMPORTING fieldValue TYPE string RETURNING VALUE(result) TYPE abap_boolean.

  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF salesOrderStatus,
        approve    TYPE c LENGTH 10  VALUE 'Approve', " Approve
        Reject     TYPE c LENGTH 10  VALUE 'Reject', " Reject
        InProgress TYPE c LENGTH 14 VALUE 'In Progress',
      END OF salesOrderStatus.


    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR _SOHeader RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR _SOHeader RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE _SOHeader.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE _SOHeader.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE _SOHeader.

    METHODS read FOR READ
      IMPORTING keys FOR READ _SOHeader RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK _SOHeader.

    METHODS rba_Soitem FOR READ
      IMPORTING keys_rba FOR READ _SOHeader\_Soitem FULL result_requested RESULT result LINK association_links.

    METHODS cba_Soitem FOR MODIFY
      IMPORTING entities_cba FOR CREATE _SOHeader\_Soitem.

    METHODS approveSalesOrderStatus FOR MODIFY
      IMPORTING keys FOR ACTION _SOHeader~approveSalesOrderStatus RESULT result.

    METHODS rejectSalesOrderStatus FOR MODIFY
      IMPORTING keys FOR ACTION _SOHeader~rejectSalesOrderStatus RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR _SOHeader RESULT result.

   METHODS is_update_allowed
   RETURNING VALUE(update_allowed) TYPE abap_boolean.

ENDCLASS.

CLASS lhc__SOHeader IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF zi_header_so IN LOCAL MODE
  ENTITY _SOHeader
 ALL FIELDS WITH CORRESPONDING #( keys )
  RESULT DATA(Orders)
  FAILED failed.

    result =
    VALUE #(
    FOR order IN orders
    LET


        is_disableStatus = COND #( WHEN order-OrderStatus = salesorderstatus-approve OR
                                        order-OrderStatus = salesorderstatus-reject
                                    THEN if_abap_behv=>fc-o-disabled
                                    ELSE if_abap_behv=>fc-o-enabled
                                         )
     IN
              ( %tky                 = order-%tky
                %action-approveSalesOrderStatus = is_disablestatus
                %action-rejectSalesOrderStatus = is_disablestatus

               )
     ).



  ENDMETHOD.

  METHOD get_instance_authorizations.



  ENDMETHOD.

  METHOD create.

    IF entities IS NOT INITIAL.
      "--Get the Document No. Value

      DATA(lv_docnum) = get_next_salesOrderNo(  ).

      GET TIME STAMP FIELD DATA(lv_timestamp).

      LOOP AT entities ASSIGNING FIELD-SYMBOL(<lfs_head_data>).

        MOVE-CORRESPONDING <LFS_HEAD_dATA> TO ms_root_to_create.

        DATA(lv_result) = checkField( CONV String( <lfs_head_data>-CustDesc ) ).

        IF lv_result EQ abap_false  .

          APPEND VALUE #( %tky = <lfs_head_data>-%key
                          %state_area = 'VALIDATE_CUSTOMERDESC'
                          %msg = new_message(
                                        id = 'ZUM_RAP_MESSAGES'
                                        number = '001'
                                        severity = if_abap_behv_message=>severity-error
                                        )
                          )

          TO reported-_soheader.

        ELSEIF   <lfs_head_data>-OrderDate NE cl_abap_context_info=>get_system_date(  ).

          APPEND VALUE #( %tky = <lfs_head_data>-%key
                         %state_area = 'VALIDATE_CUSTOMERDATE'
                         %msg = new_message(
                                       id = 'ZUM_RAP_MESSAGES'
                                       number = '003'
                                       severity = if_abap_behv_message=>severity-error
                                       )
                         )

         TO reported-_soheader.

ELSEIF <lfs_head_data>-CustNumber CP '^[0-9]+$'.

 APPEND VALUE #( %tky = <lfs_head_data>-%key
                         %state_area = 'VALIDATE_CUSTOMERNUMBER'
                         %msg = new_message(
                                       id = 'ZUM_RAP_MESSAGES'
                                       number = '005'
                                       v1 = <lfs_head_data>-CustNumber
                                       severity = if_abap_behv_message=>severity-error
                                       )
                         ) TO reported-_soheader.

        ELSE.

          ms_root_to_create-so_number = lv_docnum.
          ms_root_to_create-cust_desc = <lfs_head_data>-CustDesc.
          ms_root_to_create-order_status = salesorderstatus-inprogress.
          ms_root_to_create-so_date = <lfs_head_data>-OrderDate.
          ms_root_to_create-cust_number = <lfs_head_data>-CustNumber.
          ms_root_to_create-locallastchangedat = lv_timestamp.


          INSERT CORRESPONDING #( ms_root_to_create ) INTO TABLE mapped-_soheader.
          INSERT CORRESPONDING #( ms_root_to_create ) INTO TABLE mt_root_to_create.
        ENDIF.


      ENDLOOP.
    ENDIF.

*MODIFY ENTITIES
" Set the new overall status
    MODIFY ENTITIES OF ZI_HEADER_SO IN LOCAL MODE
      ENTITY _SOHeader
      UPDATE
        FIELDS ( CustNumber OrderDate CustDesc )
           WITH VALUE #( FOR key IN entities
                           ( %key        = key-OrderNo
                           CustNumber = key-CustNumber
                           CustDesc = key-CustDesc
                           OrderDate = key-OrderDate
                       ) )
      FAILED failed
      REPORTED reported.

  ENDMETHOD.

  METHOD update.

    "--Update Method
    "--Update at HEADER LEVEL
    DATA : lt_ui_header_update TYPE STANDARD TABLE OF zso_header_mfb,
           ls_ui_header_update TYPE zso_header_mfb.

    lt_UI_header_update = CORRESPONDING #( entities MAPPING FROM ENTITY ).

    GET TIME STAMP FIELD DATA(current_timestamp).
    IF lt_UI_header_update IS NOT INITIAL.

      SELECT * FROM zso_header_mfb
      FOR ALL ENTRIES IN @lt_UI_header_update
      WHERE so_number = @lt_UI_header_update-so_number
      INTO TABLE @DATA(lt_header_update_db).

      "--Now PUT DATA in lt_header_update

      LOOP AT lt_header_update_db ASSIGNING FIELD-SYMBOL(<lfs_update>).

        LOOP AT entities ASSIGNING FIELD-SYMBOL(<lfs_entities>) WHERE %tky-%key = <lfs_update>-so_number.

          DATA(ls_control) = <lfs_entities>-%control.
          IF ls_control-OrderDate IS NOT INITIAL.
            <lfs_update>-so_date = <lfs_entities>-OrderDate.
          ENDIF.

          IF ls_control-CustDesc IS NOT INITIAL.
            <lfs_update>-cust_desc = <lfs_entities>-CustDesc.
          ENDIF.

          IF ls_control-CustNumber IS NOT INITIAL.
            <lfs_update>-cust_number = <lfs_entities>-CustNumber.
          ENDIF.

          <lfs_update>-locallastchangedat = current_timestamp.
          INSERT CORRESPONDING #( <lfs_update> ) INTO TABLE lt_root_update.
        ENDLOOP.


      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD delete.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_delete>).
      ls_head_delete-so_number = <fs_delete>-OrderNo.
      INSERT CORRESPONDING #( ls_head_delete ) INTO TABLE lt_head_delete.
    ENDLOOP.

  ENDMETHOD.

  METHOD read.

    SELECT * FROM zi_header_so
            FOR ALL ENTRIES IN @keys
            WHERE OrderNo = @keys-OrderNo
            INTO CORRESPONDING FIELDS OF TABLE @result.


  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Soitem.
  ENDMETHOD.

  METHOD cba_Soitem.

    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<lfs_entity>).
      LOOP AT <lfs_entity>-%target ASSIGNING FIELD-SYMBOL(<lfs_item>).

        DATA(lv_result) = checkField( CONV String( <lfs_item>-MaterialDesc ) ).
        IF lv_result EQ abap_false.
          APPEND VALUE #( %tky = <lfs_item>-%key
                          %state_area = 'VALIDATE_MATERIALDESC'
                          %msg = new_message(
                                        id = 'ZUM_RAP_MESSAGES'
                                        number = '002'
                                        severity = if_abap_behv_message=>severity-error
                                        ) ) TO reported-_soitem.

        ELSE.
          ls_item-item_no = <lfs_item>-ItemNo.
          ls_item-material_no = <lfs_item>-MaterialNo.

          "---Validation that Material Description cannot have Digits
          ls_item-material_desc = <lfs_item>-MaterialDesc.
          ls_item-item_amt = <lfs_item>-ItemAmt.
          ls_item-so_number = <lfs_item>-OrderNo.
          ls_item-currency = <lfs_item>-Currency.

          MOVE-CORRESPONDING <lfs_item> TO ls_item.
          INSERT CORRESPONDING #( ls_item ) INTO TABLE mt_item.


        ENDIF.




      ENDLOOP.
    ENDLOOP.


  ENDMETHOD.

  METHOD approveSalesOrderStatus.

    "--Update
    "--Instance Features 2
    DATA(lv_docnum) = keys[ 1 ]-OrderNo.
    SELECT * FROM zso_header_mfb WHERE so_number EQ @lv_docnum INTO TABLE @DATA(lt_Data).


    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      MOVE-CORRESPONDING <ls_data> TO ms_root_to_create.
      ms_root_to_create-order_status = 'Approve'.
      INSERT CORRESPONDING #( ms_root_to_create ) INTO TABLE mt_action.

    ENDLOOP.


  ENDMETHOD.

  METHOD rejectSalesOrderStatus.

    DATA(lv_docnum) = keys[ 1 ]-OrderNo.
    SELECT * FROM zso_header_mfb WHERE so_number EQ @lv_docnum INTO TABLE @DATA(lt_Data).

    LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      MOVE-CORRESPONDING <ls_data> TO ms_root_to_create.
      ms_root_to_create-order_status = 'Reject'.
      INSERT CORRESPONDING #( ms_root_to_create ) INTO TABLE mt_action.

    ENDLOOP.

  ENDMETHOD.

  METHOD checkfield.

    "--FieldValue
    "--CustomerDescription--->If CustomerDescription is Number then 'Put the Message it is Incorrect'
    "--data lv_pattern type string value '[^\d+(\.\d+)?$ ]' .
    DATA(regex) =    '^[A-Za-z]+$'.
    FIND PCRE regex IN fieldvalue.
    DATA lv_result TYPE abap_bool.

    IF sy-subrc EQ 0.
      result = abap_true."--String Contains A-Z,a-z and No Digits
    ELSE.
      result = abap_false."--String contains Digits Also
    ENDIF.


    RETURN result.


  ENDMETHOD.

  METHOD get_next_salesorderno.

    "--Getting Next Sales Order
    SELECT MAX( so_number  ) FROM zso_header_mfb INTO @DATA(lv_max_docnoid).
    r_docno_val = lv_max_docnoid + 1.
    r_docno_val = |{ r_docno_val ALPHA = IN }|.





  ENDMETHOD.

  METHOD get_global_authorizations.
  "--Check If Authorized then You can Approve the Order,Reject the Order
  "--Else both are disabled for you.

  if requested_authorizations-%action-approveSalesOrderStatus = if_abap_behv=>mk-on
               or requested_authorizations-%action-rejectSalesOrderStatus = if_abap_behv=>mk-on.

               if is_update_allowed(  ) = abap_true.


               result-%action-approveSalesOrderStatus = if_abap_behv=>auth-allowed.
              result-%action-rejectSalesOrderStatus = if_abap_behv=>auth-allowed.



               else.
                  result-%action-approveSalesOrderStatus = if_abap_behv=>auth-unauthorized.
              result-%action-rejectSalesOrderStatus = if_abap_behv=>auth-unauthorized.

               endif.
  endif.

  ENDMETHOD.

  METHOD is_update_allowed.

if cl_abap_context_info=>get_user_technical_name(  ) = 'CB9980002600'.
update_allowed = abap_true.
endif.



  ENDMETHOD.

ENDCLASS.

CLASS lhc__SOItem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION.

    CLASS-DATA : ls_whse TYPE zso_whse_mfb.
    CLASS-DATA : lt_whse_create TYPE STANDARD TABLE OF zso_whse_mfb .

    CLASS-DATA : lt_item_update TYPE STANDARD TABLE OF zso_item_mfb,
                 lt_item_delete TYPE STANDARD TABLE OF zso_item_mfb,
                 ls_item_delete TYPE zso_item_mfb.

  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE _SOItem.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE _SOItem.

    METHODS read FOR READ
      IMPORTING keys FOR READ _SOItem RESULT result.

    METHODS rba_Soheader FOR READ
      IMPORTING keys_rba FOR READ _SOItem\_Soheader FULL result_requested RESULT result LINK association_links.

    METHODS rba_Sowhse FOR READ
      IMPORTING keys_rba FOR READ _SOItem\_Sowhse FULL result_requested RESULT result LINK association_links.

    METHODS cba_Sowhse FOR MODIFY
      IMPORTING entities_cba FOR CREATE _SOItem\_Sowhse.

ENDCLASS.

CLASS lhc__SOItem IMPLEMENTATION.

  METHOD update.


    "--Update at ITEM LEVEL
    DATA : LT_ui_items_UPDATE TYPE STANDARD TABLE OF zso_item_mfb,
           LS_ui_items_UPDATE TYPE zso_item_mfb.

    lt_ui_items_update = CORRESPONDING #( entities MAPPING FROM ENTITY ).

    IF lt_ui_items_update IS NOT INITIAL.

      SELECT * FROM zso_item_mfb
      FOR ALL ENTRIES IN @lt_ui_items_update
      WHERE so_number = @lt_ui_items_update-so_number AND item_no = @lt_ui_items_update-item_no
      INTO TABLE @DATA(lt_item_update_db). "--Reference Record to be checked with


      "--Item Table Update
      LOOP AT lt_item_update_db ASSIGNING FIELD-SYMBOL(<lfs_update>).
        LOOP AT entities ASSIGNING FIELD-SYMBOL(<lfs_entities>) WHERE
         %tky-%key-OrderNo = <lfs_update>-so_number
         AND %tky-%key-ItemNo = <lfs_update>-item_no.
          DATA(ls_control) = <lfs_entities>-%control.
          IF ls_control-MaterialNo IS NOT INITIAL.
            <lfs_update>-material_no = <lfs_entities>-MaterialNo.
          ENDIF.

          IF ls_control-MaterialDesc IS NOT INITIAL.
            <lfs_update>-material_desc = <lfs_entities>-MaterialDesc.
          ENDIF.

          IF ls_control-ItemAmt IS NOT INITIAL.
            <lfs_update>-item_amt = <lfs_entities>-ItemAmt.
          ENDIF.

          IF ls_control-Currency IS NOT INITIAL.
            <lfs_update>-currency = <lfs_entities>-Currency.
          ENDIF.

          INSERT CORRESPONDING #( <lfs_update> ) INTO TABLE lt_item_update.
        ENDLOOP.


      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD delete.

    "--DELETE ITEM
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_delete>).
      ls_item_delete-so_number = <fs_delete>-OrderNo.
      ls_item_delete-item_no = <fs_delete>-ItemNo.
      INSERT CORRESPONDING #( ls_item_delete ) INTO TABLE lt_item_delete.

    ENDLOOP.

  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD rba_Soheader.
  ENDMETHOD.

  METHOD rba_Sowhse.
  ENDMETHOD.

  METHOD cba_Sowhse.

    TYPES : BEGIN OF ty_whse_list,
              whse_value TYPE    domvalue_l,
            END OF ty_whse_list.
    DATA : warehouses TYPE SORTED TABLE OF ty_whse_list WITH UNIQUE KEY whse_value.

    SELECT value FROM zi_whse_number_vh INTO TABLE @warehouses.

    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<lfs_entity>).
      LOOP AT <lfs_entity>-%target ASSIGNING FIELD-SYMBOL(<lfs_whse>).



        "---Pick Values Only from Warehouse VALUE HELP
*        select fields from
        DATA(whse_value) = <lfs_whse>-WarehouseNo.
        TRANSLATE whse_value TO UPPER CASE.
        DATA(valid_whse) = FILTER #( warehouses WHERE whse_value =  CONV domvalue_l( whse_value )  ).

        IF valid_whse IS NOT INITIAL.
          ls_whse-whse_no = <lfs_whse>-WarehouseNo.
          ls_whse-whse_address = <lfs_whse>-WarehouseAddress.
          ls_whse-quantity = <lfs_whse>-Quantity.
          ls_whse-comments = <lfs_whse>-Comments.
          ls_whse-unit_of_measure = <lfs_whse>-UnitOfMeasure.
          ls_whse-item_no = <lfs_whse>-ItemNo.
          ls_whse-so_number = <lfs_whse>-SoNumber.


        ELSE.
*"--Now Give Error if Warehouse Number is NOT Coming upto
          APPEND VALUE #( %tky = <lfs_whse>-%key
                                   %state_area = 'VALIDATE_WHSENUMBER'
                                   %msg = new_message(
                                                 id = 'ZUM_RAP_MESSAGES'
                                                 number = '004'
                                                 v1 = <lfs_whse>-WarehouseNo
                                                 severity = if_abap_behv_message=>severity-error
                                                 ) ) TO reported-_sowhse.
*
        ENDIF.
*


        MOVE-CORRESPONDING <lfs_whse> TO ls_whse.
        INSERT CORRESPONDING #( ls_whse ) INTO TABLE lt_whse_create.

      ENDLOOP.
    ENDLOOP.


  ENDMETHOD.

ENDCLASS.

CLASS lhc__SOWhse DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    CLASS-DATA : lt_whse_update TYPE STANDARD TABLE OF zso_warehse_db,
                 lt_whse_delete TYPE STANDARD TABLE OF zso_warehse_db,
                 ls_whse_delete TYPE zso_warehse_db.

  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE _SOWhse.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE _SOWhse.

    METHODS read FOR READ
      IMPORTING keys FOR READ _SOWhse RESULT result.

    METHODS rba_Soheader FOR READ
      IMPORTING keys_rba FOR READ _SOWhse\_Soheader FULL result_requested RESULT result LINK association_links.

    METHODS rba_Soitem FOR READ
      IMPORTING keys_rba FOR READ _SOWhse\_Soitem FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc__SOWhse IMPLEMENTATION.

  METHOD update.

    DATA : LT_ui_whse_UPDATE TYPE STANDARD TABLE OF zso_whse_mfb,
           LS_ui_whse_UPDATE TYPE zso_whse_mfb.

    lt_ui_whse_update = CORRESPONDING #( entities MAPPING FROM ENTITY ).

    IF lt_ui_whse_update IS NOT INITIAL.

      SELECT * FROM zso_whse_mfb
      FOR ALL ENTRIES IN @lt_ui_whse_update
      WHERE so_number = @lt_ui_whse_update-so_number AND item_no = @lt_ui_whse_update-item_no
      AND whse_no = @lt_ui_whse_update-whse_no
      INTO TABLE @DATA(lt_whse_update_db). "--Reference Record to be checked with


      "--Item Table Update
      LOOP AT lt_whse_update_db ASSIGNING FIELD-SYMBOL(<lfs_update>).

        LOOP AT entities ASSIGNING FIELD-SYMBOL(<lfs_entities>) WHERE
         %tky-%key-SoNumber = <lfs_update>-so_number
         AND %tky-%key-ItemNo = <lfs_update>-item_no
         AND %tky-%key-WarehouseNo = <lfs_update>-whse_no.

          DATA(ls_control) = <lfs_entities>-%control.

          IF ls_control-WarehouseAddress IS NOT INITIAL.
            <lfs_update>-whse_address = <lfs_entities>-WarehouseAddress.
          ENDIF.

          IF ls_control-Comments IS NOT INITIAL.
            <lfs_update>-comments = <lfs_entities>-Comments.
          ENDIF.

          IF ls_control-Quantity IS NOT INITIAL.
            <lfs_update>-quantity = <lfs_entities>-Quantity.
          ENDIF.

          IF ls_control-UnitOfMeasure IS NOT INITIAL.
            <lfs_update>-unit_of_measure = <lfs_entities>-UnitOfMeasure.
          ENDIF.

          INSERT CORRESPONDING #( <lfs_update> ) INTO TABLE lt_whse_update.
        ENDLOOP.


      ENDLOOP.
    ENDIF.


  ENDMETHOD.

  METHOD delete.

    "--DELETE Warehouse
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_delete>).
      ls_WHSE_delete-so_number = <fs_delete>-SoNumber.
      ls_whse_delete-item_no = <fs_delete>-ItemNo.
      ls_whse_delete-whse_no = <fs_delete>-WarehouseNo.
      INSERT CORRESPONDING #( ls_whse_delete ) INTO TABLE lt_whse_delete.

    ENDLOOP.

  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD rba_Soheader.
  ENDMETHOD.

  METHOD rba_Soitem.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_HEADER_SO DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_HEADER_SO IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.

    TRY.
        IF lhc__SOheader=>mt_root_to_create IS NOT INITIAL.
          INSERT zso_header_mfb FROM TABLE @lhc__SOheader=>mt_root_to_create.
        ENDIF.
      CATCH cx_root.
        reported-_soheader =  VALUE #( ( %msg =  new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = 'Same Key Already Exist, Insert not Possible'
                              ) ) ).
    ENDTRY.


    IF lhc__soheader=>lt_root_update IS NOT INITIAL.
      MODIFY zso_header_mfb FROM TABLE  @lhc__soheader=>lt_root_update.
    ENDIF.

    IF lhc__soheader=>mt_action IS NOT INITIAL.
      MODIFY zso_header_mfb FROM TABLE @lhc__soheader=>mt_action.
    ENDIF.

    IF lhc__soheader=>lt_head_delete IS NOT INITIAL.
      DELETE zso_header_mfb FROM TABLE @lhc__soheader=>lt_head_delete.
      DELETE zso_whse_mfb FROM TABLE @lhc__soheader=>lt_head_delete.
      DELETE zso_item_mfb FROM TABLE @lhc__soheader=>lt_head_delete.
    ENDIF.
    TRY.
        IF lhc__soHEADER=>mt_item IS NOT INITIAL.
          INSERT zso_item_mfb FROM TABLE @lhc__soheader=>mt_item.
        ENDIF.
      CATCH cx_root.
        reported-_soitem =  VALUE #( ( %msg =  new_message_with_text(
                               severity = if_abap_behv_message=>severity-error
                               text     = 'Same Key Already Exist,Insert not Possible'
                              ) ) ).
    ENDTRY.


    IF lhc__soitem=>lt_whse_create IS NOT INITIAL.
      INSERT zso_whse_mfb FROM TABLE @lhc__soitem=>lt_whse_create.
    ENDIF.


    IF lhc__soitem=>lt_item_update IS NOT INITIAL.
      MODIFY zso_item_mfb FROM TABLE @lhc__soitem=>lt_item_update.
    ENDIF.

    IF lhc__soitem=>lt_item_delete IS NOT INITIAL.
      DELETE zso_item_mfb FROM TABLE @lhc__soitem=>lt_item_delete.
      DELETE zso_whse_mfb FROM TABLE @lhc__soitem=>lt_item_delete.
    ENDIF.

    IF lhc__sowhse=>lt_whse_update IS NOT INITIAL.
      MODIFY zso_whse_mfb FROM TABLE @lhc__sowhse=>lt_whse_update.
    ENDIF.

    IF lhc__sowhse=>lt_whse_delete IS NOT INITIAL.
      DELETE zso_whse_mfb FROM TABLE @lhc__sowhse=>lt_whse_delete.
    ENDIF.



  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
