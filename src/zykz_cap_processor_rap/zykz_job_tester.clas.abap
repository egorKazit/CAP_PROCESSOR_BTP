CLASS zykz_job_tester DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zykz_job_tester IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA(job_start_info) = NEW cl_apj_rt_api=>ty_start_info( start_immediately = abap_true ).
    DATA(job_parameters) = NEW cl_apj_rt_api=>tt_job_parameter_value( ( name = zcl_ykz_complete_entry_job=>p_thread_id
                                                                        t_value = VALUE #( ( sign   = 'I'
                                                                                             option = 'EQ'
                                                                                             low    = '992AB26D561441868C9F4484BBF5B991' ) ) ) ).


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

*        WHILE 1 = 1.
*
*          cl_apj_rt_api=>get_job_status(
*            EXPORTING
*              iv_jobname  = job_name
*              iv_jobcount = job_count
*            IMPORTING
*              ev_job_status      = DATA(job_status)
*              ev_job_status_text = DATA(job_status_text)
*            ).
*
*
*          IF job_status = 'F'.
*            EXIT.
*          ENDIF.
*
*        ENDWHILE.

      CATCH cx_apj_rt INTO DATA(apj_rt).
        DATA(x) = 1.
        "handle exception
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
