CREATE OR REPLACE PACKAGE api_assignment AS

PRAGMA SERIALLY_REUSABLE;  -- Don't save state between calls
   
PROCEDURE add_assignment( 
     i_prospect_id      IN NUMBER
    ,i_proposal_id      IN NUMBER
    ,i_staff_id         IN VARCHAR2
    ,i_assignment_type  IN VARCHAR2
    ,i_effective_date   IN DATE
    ,i_operator_name    IN VARCHAR2
);

PROCEDURE deactivate_assignment( i_assignment_id     IN NUMBER
                               , i_effective_date    IN DATE
                               , i_operator_name     IN VARCHAR2
);

END api_assignment;
/
CREATE OR REPLACE PACKAGE BODY api_assignment AS

   PRAGMA SERIALLY_REUSABLE;  -- Don't save state between calls
     
   /**  Global variable to specify adding/modding  */
   g_operation                    VARCHAR2(10);
    
   /** Operation string for adding proposals used in error messages.  */
   C_OP_ADD                       CONSTANT VARCHAR2(10)     := 'adding'; 
     
   /** Operation string for modifying proposals used in error messages.  */
   C_OP_MOD                       CONSTANT VARCHAR2(10)     := 'modifying';

   /** Indicator for "Active"  */
   C_ACTIVE_IND                   CONSTANT VARCHAR2(1)      := 'Y';
   
   /** Indicator for "Inactive".  */
   C_INACTIVE_IND                 CONSTANT VARCHAR2(1)      := 'N';

   /** Form ID used to validate prospect assignments data (from DataLoader Form)
   *   @see Advance_Web_DataLoader_User_Guide.pdf   */
   c_prospect_assignment_form   CONSTANT NUMBER           := 80283;
     
   /** <code>w_</code> table for assignments */
   C_WORKTABLE         CONSTANT VARCHAR2(32)     := 'w_assignment';  

   /** Site ID level for table validation, as defined in Advance Config Tool */
   C_SITE_ID                      CONSTANT VARCHAR2(5)      := '0';
     
   /** Sourcecode used for DataLoader.  */
   C_DATALOADER_SOURCE            CONSTANT VARCHAR2(5)      := 'DL';
     
   /** Username used for validation security */
   C_DEFAULT_VALIDATE_USER        CONSTANT VARCHAR2(32)     := 'salter';
     
   /** Username used when adding/modding data. 
   *   Will be stamped on audit (<code>operator_name</code>) for additions and changes.
   *  <i>Note: Does not need to be a valid Advance user.</i>  */
   C_OPERATOR_USERNAME            CONSTANT VARCHAR2(32)     := 'assignment_api';
     
   /** User group used when adding new data. 
   *   Will be stamped on audit (<code>user_group</code>) for additions and changes. */
   C_OPERATOR_USERGROUP           CONSTANT VARCHAR2(6)      := 'AP';
     
   /** Code for adds used in <code>w_*</code> tables and <code>do_update</code> calls. */
   C_ADD                          CONSTANT CHAR(1)          := 'A';
     
   /** Code for mods used in <code>w_*</code> tables and <code>do_update</code> calls. */
   C_MOD                          CONSTANT CHAR(1)          := 'M';
     
   /** <code>assignment_type</code> code for lead solicitor assignments */
   C_LEAD_SOLICITOR               CONSTANT VARCHAR2(2)      := 'A1';
     
   /** Assignment type code for team member (secondary solicitor) assignments */
   C_TEAM_MEMBER                  CONSTANT VARCHAR2(2)      := 'A2';
     
   /** Used in <code>ud_log</code> procedures to specify ID type of an Advance ID(<code>id_number</code>) */
   C_ERR_ID_NUMBER_TYPE           CONSTANT VARCHAR2(100)    := 'id_number';
     


/**********************************************************
* <b>[Private]</b> Insert a row into <code>w_assignment</code> table.
* <p>
* Deletes all rows and inserts a single row into 
* <code>advance.w_assignment</code> table.
* <p>
* All parameters are defaulted appropriately; only pass in
* what is necessary.
**********************************************************/ 

PROCEDURE insert_assignments_wtbl( 
      i_xoption               IN CHAR       := ''
    , i_assignment_id         IN NUMBER     := NULL
    , i_contract_grant_id     IN NUMBER     := NULL
    , i_prospect_id           IN NUMBER     := NULL
    , i_program_code          IN VARCHAR2   := ''
    , i_program_year          IN VARCHAR2   := ' '
    , i_proposal_id           IN NUMBER     := NULL
    , i_allocation_code       IN VARCHAR2   := ''
    , i_id_number             IN VARCHAR2   := ''
    , i_start_date            IN DATE       := SYSDATE
    , i_stop_date             IN DATE       := NULL
    , i_office_code           IN VARCHAR2   := ' '
    , i_assignment_id_number  IN VARCHAR2   := ' '
    , i_assignment_type       IN VARCHAR2   := ' '
    , i_active_ind            IN CHAR       := 'Y'
    , i_xcomment              IN VARCHAR2   := ' '
    , i_committee_code        IN VARCHAR2   := ''
    , i_priority_code         IN VARCHAR2   := ' '
    , i_unit_code             IN VARCHAR2   := ''
    , i_date_added            IN DATE       := SYSDATE
    , i_date_modified         IN DATE       := SYSDATE
    , i_operator_name         IN VARCHAR2   := c_operator_username
    , i_user_group            IN VARCHAR2   := c_operator_usergroup
    , i_loader_row_id         IN NUMBER     := ''
                  
) IS
BEGIN          
    
    api_common.clear_temp_tables(p_w_table_name => c_worktable);
           
    INSERT INTO advance.w_assignment(xoption, assignment_id, contract_grant_id, prospect_id, program_code
                                , program_year, proposal_id, allocation_code, id_number, start_date, stop_date
                                , office_code, assignment_id_number, assignment_type, active_ind, xcomment
                                , committee_code, priority_code, unit_code, date_added, date_modified
                                , operator_name, user_group, loader_row_id
              ) VALUES (
                i_xoption               
              , i_assignment_id
              , i_contract_grant_id
              , i_prospect_id
              , i_program_code
              , i_program_year
              , i_proposal_id
              , i_allocation_code
              , i_id_number
              , i_start_date
              , i_stop_date
              , i_office_code
              , i_assignment_id_number
              , i_assignment_type
              , i_active_ind
              , i_xcomment
              , i_committee_code
              , i_priority_code
              , i_unit_code
              , i_date_added
              , i_date_modified
              , i_operator_name
              , i_user_group
              , i_loader_row_id
    );
END insert_assignments_wtbl;



/*-------------------------------------------
 add_assignment
-------------------------------------------*/ 
PROCEDURE add_assignment( 
    i_prospect_id        IN NUMBER
    , i_proposal_id      IN NUMBER
    , i_staff_id         IN VARCHAR2
    , i_assignment_type  IN VARCHAR2
    , i_effective_date   IN DATE
    , i_operator_name    IN VARCHAR2
) IS

    return_code       INTEGER;
    validate_status   INTEGER;
    error_row_cnt     INTEGER;
    error_msg         VARCHAR2(1000);
    v_out             INTEGER;
    v_error_msg       VARCHAR2(2000);
    v_error_row_cnt   INTEGER;
    validate_status   INTEGER;
    v_operation       VARCHAR2(10);
    v_operation_desc  VARCHAR2(20);
    v_return_code     INTEGER;

BEGIN
    
    v_operation := api_common.c_op_add_code;
    v_operation_desc := api_common.c_op_add_description;

    insert_assignments_wtbl( i_xoption              => v_operation
                         , i_prospect_id          => i_prospect_id
                         , i_proposal_id          => i_proposal_id
                         , i_assignment_id_number => i_staff_id 
                         , i_assignment_type      => i_assignment_type
                         , i_start_date           => i_effective_date
                         , i_operator_name        => i_operator_name
                       );
                             
    advance.adv_assignment.do_update(return_code);

    IF v_out <> 1 THEN 
        v_error_msg := api_common.get_validation_errors;    
        v_error_row_cnt := api_common.get_validation_error_count;     
        ud_log.log_error( p_custom_msg_1 => 'Error ' || v_operation_desc || ' note: '
                                    || 'do_update return: ' || v_return_code || '; '
                                     || 'ErrCnt: ' || v_error_row_cnt     
                                     || ' Msg: ' || v_error_msg
               );
    END IF;
      
END add_assignment;



/*-------------------------------------------
 deactivate_assignment
-------------------------------------------*/ 
PROCEDURE deactivate_assignment( i_assignment_id     IN NUMBER
                               , i_effective_date    IN DATE
                               , i_operator_name     IN VARCHAR2
) IS
   
    return_code       INTEGER;
    validate_status   INTEGER;
    error_row_cnt     INTEGER;
    error_msg         VARCHAR2(1000);
    v_out             INTEGER;
    v_error_msg       VARCHAR2(2000);
    v_error_row_cnt   INTEGER;
    validate_status   INTEGER;
    v_operation       VARCHAR2(10);
    v_operation_desc  VARCHAR2(20);
    v_return_code     INTEGER;
    r_assignment      assignment%ROWTYPE;
   
   
   -- Though by business rule, we don't have multiple A1 solicitors, the system doesn't seem to enforce this.
   -- Need to check both code and ID number.
   CURSOR assign_q(p_assignment_id NUMBER) IS
       SELECT a.*
       FROM assignment a
       WHERE a.assignment_id = p_assignment_id;

BEGIN

    v_operation := api_common.c_op_mod_code;
    v_operation_desc := api_common.c_op_mod_description;

    OPEN assign_q(i_assignment_id);
    FETCH assign_q INTO r_assignment;
          
    IF assign_q%NOTFOUND THEN 
        ud_log.log_warning( p_custom_msg_1 => 'Warning ' || g_operation || ' proposal'
                          , p_custom_msg_2 => 'No active assignments found.'
                          , p_id_type => 'assignment_id'
                          , p_id_value => i_assignment_id
                        );
        RETURN;
    END IF;
    
    insert_assignments_wtbl(  i_xoption              => v_operation
                              , i_assignment_id        => r_assignment.assignment_id
                              , i_contract_grant_id    => r_assignment.contract_grant_id
                              , i_prospect_id          => r_assignment.prospect_id
                              , i_program_code         => r_assignment.program_code
                              , i_program_year         => r_assignment.program_year
                              , i_proposal_id          => r_assignment.proposal_id
                              , i_allocation_code      => r_assignment.allocation_code
                              , i_id_number            => r_assignment.id_number
                              , i_start_date           => r_assignment.start_date
                              , i_stop_date            => i_effective_date
                              , i_office_code          => r_assignment.office_code
                              , i_assignment_id_number => r_assignment.assignment_id_number
                              , i_assignment_type      => r_assignment.assignment_type
                              , i_active_ind           => c_inactive_ind
                              , i_xcomment             => r_assignment.xcomment
                              , i_committee_code       => r_assignment.committee_code
                              , i_priority_code        => r_assignment.priority_code
                              , i_unit_code            => r_assignment.unit_code
                              , i_date_added           => r_assignment.date_added
                              , i_date_modified        => SYSDATE
                              , i_operator_name        => i_operator_name
                             );        
          
    advance.adv_assignment.do_update(return_code);
                                  
    IF v_out <> 1 THEN 
        v_error_msg := api_common.get_validation_errors;    
        v_error_row_cnt := api_common.get_validation_error_count;     
        ud_log.log_error( p_custom_msg_1 => 'Error ' || v_operation_desc || ' note: '
                                    || 'do_update return: ' || v_return_code || '; '
                                     || 'ErrCnt: ' || v_error_row_cnt     
                                     || ' Msg: ' || v_error_msg
               );
    END IF;
    
END deactivate_assignment;


END api_assignment;
/
