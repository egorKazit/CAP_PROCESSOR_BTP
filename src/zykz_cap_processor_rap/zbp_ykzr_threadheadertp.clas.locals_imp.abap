CLASS lhc_ThreadHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.


*-----------------------------------Authorizations-----------------------------------
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ThreadHeader RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ThreadHeader RESULT result.


*-----------------------------------Determinations-----------------------------------
    METHODS EarlyNumberingOnCreate FOR NUMBERING
      IMPORTING entities_header FOR CREATE ThreadHeader
                entities_item   FOR CREATE ThreadHeader\_ThreadItemTP.
    METHODS SetInitialStatus FOR DETERMINE ON SAVE
      IMPORTING keys FOR ThreadHeader~SetInitialStatus.


*--------------------------------------Actions---------------------------------------
    METHODS CreateEntityFromSource FOR MODIFY
      IMPORTING keys FOR ACTION ThreadHeader~CreateEntityFromSource.
    METHODS SubmitForApproval FOR MODIFY
      IMPORTING keys FOR ACTION ThreadHeader~SubmitForApproval RESULT result.
    METHODS Abandon FOR MODIFY
      IMPORTING keys FOR ACTION ThreadHeader~Abandon RESULT result.
    METHODS Approve FOR MODIFY
      IMPORTING keys FOR ACTION ThreadHeader~Approve RESULT result.
    METHODS Reject FOR MODIFY
      IMPORTING keys FOR ACTION ThreadHeader~Reject RESULT result.
    METHODS Complete FOR MODIFY
      IMPORTING keys FOR ACTION ThreadHeader~Complete RESULT result.

*--------------------------------------Internals---------------------------------------
    METHODS processStatus
      IMPORTING keys             TYPE zif_ykz_cap_bdef_const=>header-create
                allowed_statuses TYPE zif_ykz_cap_bdef_const=>header-statuses
                target_status    TYPE zykz_cap_status
      CHANGING  failed           TYPE zif_ykz_cap_bdef_const=>header-failed
                reported         TYPE zif_ykz_cap_bdef_const=>header-reported
                mapped           TYPE zif_ykz_cap_bdef_const=>header-mapped
                result           TYPE STANDARD TABLE.

ENDCLASS.

CLASS lsc_zykzr_threadheadertp DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION .

ENDCLASS.

CLASS lhc_ThreadHeader IMPLEMENTATION.


*-----------------------------------Authorizations-----------------------------------
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.


*-----------------------------------Determinations-----------------------------------
  METHOD EarlyNumberingOnCreate.

    LOOP AT entities_header REFERENCE INTO DATA(entity_header).
      TRY.
          INSERT VALUE #( %cid = entity_header->%cid
                          uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_c32( ) ) INTO TABLE mapped-threadheader.
        CATCH cx_uuid_error INTO DATA(exception).
          INSERT CORRESPONDING #( entity_header->* ) INTO TABLE failed-threadheader.
          INSERT CORRESPONDING #( entity_header->* ) INTO TABLE reported-threadheader REFERENCE INTO DATA(reporeted_header).
          reporeted_header->%msg = new_message_with_text( text = exception->get_longtext( ) ).
      ENDTRY.
    ENDLOOP.

    LOOP AT entities_item REFERENCE INTO DATA(entity_item_root).
      LOOP AT entity_item_root->%target REFERENCE INTO DATA(entity_item).
        TRY.
            INSERT VALUE #( %cid = entity_item->%cid
                            uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_c32( ) ) INTO TABLE mapped-threaditem.
          CATCH cx_uuid_error INTO exception.
            INSERT CORRESPONDING #( entity_item->* ) INTO TABLE failed-threaditem.
            INSERT CORRESPONDING #( entity_item->* ) INTO TABLE reported-threaditem REFERENCE INTO DATA(reporeted_item).
            reporeted_item->%msg = new_message_with_text( text = exception->get_longtext( ) ).
        ENDTRY.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD SetInitialStatus.

    READ ENTITIES OF ZYKZR_ThreadHeaderTP IN LOCAL MODE
      ENTITY ThreadHeader
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(headers).

    MODIFY ENTITIES OF ZYKZR_ThreadHeaderTP IN LOCAL MODE
      ENTITY ThreadHeader
        UPDATE FIELDS ( Status ) WITH
          VALUE #( FOR header IN headers ( %tky = header-%tky Status = zif_ykz_cap_vdm_const=>status-initial ) )
    REPORTED DATA(update_reported).

    reported-threadheader = CORRESPONDING #( DEEP update_reported-threadheader ).

  ENDMETHOD.


*--------------------------------------Actions---------------------------------------
  METHOD CreateEntityFromSource.

    CHECK keys IS NOT INITIAL.

    SELECT uuid, sourceuuid
      FROM ZYKZR_ThreadHeader
      FOR ALL ENTRIES IN @keys
      WHERE SourceUUID = @keys-%param-SourceUUID
        AND ( Status     = @zif_ykz_cap_vdm_const=>status-initial OR
              Status     = @zif_ykz_cap_vdm_const=>status-inapproval )
      INTO TABLE @DATA(noncompleted_headers).

    DATA(headers_2_create) = NEW zif_ykz_cap_bdef_const=>header-create( ).
    DATA(items_2_create) = NEW zif_ykz_cap_bdef_const=>item-create_by( ).

    LOOP AT keys REFERENCE INTO DATA(key).
      IF line_exists( noncompleted_headers[ SourceUUID = key->%param-SourceUUID ] ).
        INSERT CORRESPONDING #( key->* ) INTO TABLE failed-threadheader.
      ELSE.
        INSERT VALUE #( %cid       = key->%param-SourceUUID
                        Name       = key->%param-Name
                        Thread     = key->%param-Thread
                        SourceUUID = key->%param-SourceUUID
                        %control-Name       = if_abap_behv=>mk-on
                        %control-Thread     = if_abap_behv=>mk-on
                        %control-SourceUUID = if_abap_behv=>mk-on ) INTO TABLE headers_2_create->*.
        INSERT VALUE #( %cid_ref = key->%param-SourceUUID
                        %target  = VALUE #( FOR item IN key->%param-_items
                                   ( %cid          = |{ key->%param-SourceUUID }-{ item-ItemUUID }|
                                     Item          = item-Item
                                     Type          = item-Type
                                     NameOrContent = item-NameOrContent
                                     %control-Item          = if_abap_behv=>mk-on
                                     %control-Type          = if_abap_behv=>mk-on
                                     %control-NameOrContent = if_abap_behv=>mk-on ) ) ) INTO TABLE items_2_create->*.
      ENDIF.
    ENDLOOP.

    CHECK headers_2_create->* IS NOT INITIAL.

    MODIFY ENTITIES OF ZYKZR_ThreadHeaderTP IN LOCAL MODE
      ENTITY ThreadHeader
        CREATE FROM headers_2_create->*
      ENTITY ThreadHeader
        CREATE BY \_ThreadItemTP FROM items_2_create->*
      MAPPED DATA(created_mapped)
      FAILED failed
      REPORTED reported.

    LOOP AT created_mapped-threadheader REFERENCE INTO DATA(threadheader).
      READ TABLE keys REFERENCE INTO key
        WITH KEY %param-SourceUUID = threadheader->%cid.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      INSERT VALUE #( %cid = key->%cid
                      uuid = threadheader->uuid ) INTO TABLE mapped-threadheader.
    ENDLOOP.

  ENDMETHOD.

  METHOD SubmitForApproval.


    processstatus( EXPORTING keys             =  CORRESPONDING #( keys )
                             allowed_statuses = VALUE #( ( zif_ykz_cap_vdm_const=>status-initial ) )
                             target_status    = zif_ykz_cap_vdm_const=>status-inapproval
                   CHANGING  failed           = failed
                             reported         = reported
                             mapped           = mapped
                             result           = result ).

  ENDMETHOD.

  METHOD Abandon.

    processstatus( EXPORTING keys             =  CORRESPONDING #( keys )
                             allowed_statuses = VALUE #( ( zif_ykz_cap_vdm_const=>status-initial )
                                                         ( zif_ykz_cap_vdm_const=>status-inapproval ) )
                             target_status    = zif_ykz_cap_vdm_const=>status-abandoned
                   CHANGING  failed           = failed
                             reported         = reported
                             mapped           = mapped
                             result           = result ).

  ENDMETHOD.

  METHOD Approve.

    processstatus( EXPORTING keys             =  CORRESPONDING #( keys )
                             allowed_statuses = VALUE #( ( zif_ykz_cap_vdm_const=>status-inapproval ) )
                             target_status    = zif_ykz_cap_vdm_const=>status-approved
                   CHANGING  failed           = failed
                             reported         = reported
                             mapped           = mapped
                             result           = result ).

  ENDMETHOD.

  METHOD Reject.

    processstatus( EXPORTING keys             =  CORRESPONDING #( keys )
                             allowed_statuses = VALUE #( ( zif_ykz_cap_vdm_const=>status-inapproval ) )
                             target_status    = zif_ykz_cap_vdm_const=>status-rejected
                   CHANGING  failed           = failed
                             reported         = reported
                             mapped           = mapped
                             result           = result ).

  ENDMETHOD.

  METHOD Complete.

    READ ENTITIES OF ZYKZR_ThreadHeaderTP IN LOCAL MODE
      ENTITY ThreadHeader
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(headers).


    DATA(update) = NEW zif_ykz_cap_bdef_const=>header-update( ).

    LOOP AT headers REFERENCE INTO DATA(header).

      IF header->Status = zif_ykz_cap_vdm_const=>status-approved OR
        header->Status = zif_ykz_cap_vdm_const=>status-rejected.
        INSERT VALUE #( %tky          = header->%tky
                        ProcessedFlag = abap_true
                        %control-ProcessedFlag = if_abap_behv=>mk-on ) INTO TABLE update->*.
      ELSE.
        INSERT VALUE #( %tky   = header->%tky ) INTO TABLE failed-threadheader.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF ZYKZR_ThreadHeaderTP IN LOCAL MODE
      ENTITY ThreadHeader
        UPDATE FROM update->*
    FAILED failed
    REPORTED reported
    MAPPED mapped.

    LOOP AT update->* REFERENCE INTO DATA(update_ref).
      IF line_exists( failed-threadheader[ KEY id %tky = update_ref->%tky ] ).
        CONTINUE.
      ENDIF.
      INSERT VALUE #( %tky   = update_ref->%tky
                      %param = headers[ KEY id %tky = update_ref->%tky ] ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.


*--------------------------------------Internals---------------------------------------
  METHOD processstatus.

    READ ENTITIES OF ZYKZR_ThreadHeaderTP IN LOCAL MODE
          ENTITY ThreadHeader
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(headers).

    DATA(update) = NEW zif_ykz_cap_bdef_const=>header-update( ).

    LOOP AT headers REFERENCE INTO DATA(header).

      IF line_exists( allowed_statuses[ table_line = header->Status ] ) OR allowed_statuses IS INITIAL.
        INSERT VALUE #( %tky   = header->%tky
                        Status = target_status
                        %control-Status = if_abap_behv=>mk-on ) INTO TABLE update->*.
      ELSE.
        INSERT VALUE #( %tky   = header->%tky ) INTO TABLE failed-threadheader.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF ZYKZR_ThreadHeaderTP IN LOCAL MODE
      ENTITY ThreadHeader
        UPDATE FROM update->*
    FAILED failed
    REPORTED reported
    MAPPED mapped.

    LOOP AT update->* REFERENCE INTO DATA(update_ref).
      IF line_exists( failed-threadheader[ KEY id %tky = update_ref->%tky ] ).
        CONTINUE.
      ENDIF.
      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<result_fs>).
      ASSIGN COMPONENT '%cid_ref' OF STRUCTURE <result_fs> TO FIELD-SYMBOL(<cid_ref>).
      IF sy-subrc = 0.
        <cid_ref> = update_ref->%cid_ref.
      ENDIF.
      ASSIGN COMPONENT 'uuid' OF STRUCTURE <result_fs> TO FIELD-SYMBOL(<uuid>).
      IF sy-subrc = 0.
        <uuid> = update_ref->uuid.
      ENDIF.
      ASSIGN COMPONENT '%param' OF STRUCTURE <result_fs> TO FIELD-SYMBOL(<param>).
      IF sy-subrc = 0.
        <param> = headers[ KEY id %tky = update_ref->%tky ].
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zykzr_threadheadertp IMPLEMENTATION.

  METHOD save_modified.

    DATA completed_threads TYPE STANDARD TABLE OF ZYKZR_ThreadHeaderTP.

    IF update-threadheader IS NOT INITIAL.

      completed_threads = VALUE #( FOR incomming_thread IN update-threadheader WHERE ( ProcessedFlag = abap_true ) ( CORRESPONDING #( incomming_thread ) ) ).

      CHECK completed_threads IS NOT INITIAL.

      SELECT uuid, status, processedflag
        FROM zykz_cap_thread
        FOR ALL ENTRIES IN @completed_threads
        WHERE uuid          = @completed_threads-uuid
          AND processedflag = @abap_false
        INTO TABLE @DATA(non_completed_threads).

      LOOP AT completed_threads REFERENCE INTO DATA(completed_thread).
        CHECK line_exists( non_completed_threads[ uuid = completed_thread->uuid ] )
          AND non_completed_threads[ uuid = completed_thread->uuid ]-processedflag <> completed_thread->ProcessedFlag.

        DATA(job_start_info) = NEW cl_apj_rt_api=>ty_start_info( start_immediately = abap_true ).
        DATA(job_parameters) = NEW cl_apj_rt_api=>tt_job_parameter_value( ( name = zcl_ykz_complete_entry_job=>p_thread_id
                                                                            t_value = VALUE #( ( sign   = 'I'
                                                                                                 option = 'EQ'
                                                                                                 low    = completed_thread->uuid ) ) ) ).

        TRY.
            cl_apj_rt_api=>schedule_job(
                EXPORTING
                iv_job_template_name = 'ZTHREAD_COMPLETE_ENTRY_JOB_TMP'
                iv_job_text = |Run completion|
                is_start_info = job_start_info->*
                it_job_parameter_value = job_parameters->*
                IMPORTING
                ev_jobname  = DATA(job_name)
                ev_jobcount = DATA(job_count)
                ).

            cl_apj_rt_api=>get_job_status( EXPORTING iv_jobname  = job_name
                                                     iv_jobcount = job_count
                                           IMPORTING ev_job_status = DATA(status) ).

          CATCH cx_apj_rt INTO DATA(apj_rt).
            "handle exception
        ENDTRY.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
