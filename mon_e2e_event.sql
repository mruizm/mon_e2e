#SQL script to check events within OMLs active messages
#using as search patterns event message object and/or nodename
#Usage: call_sqlplus.sh "<msg_obj> <nodename>"


column node_name format a64 WORD_WRAPPED fold_after
column local_creation_time format a24 WORD_WRAPPED fold_after
column local_receiving_time format a24 WORD_WRAPPED fold_after
column message_number format a36 WORD_WRAPPED fold_after
column event_separator format a50 WORD_WRAPPED fold_after
column text_part format a235 WORD_WRAPPED fold_after
column object format a50 WORD_WRAPPED fold_after
column severity format a3 WORD_WRAPPED fold_after
column source_policy format a50 WORD_WRAPPED fold_after
column trouble_ticket format a3 WORD_WRAPPED fold_after
set heading off
set echo off
set linesize 250
set pagesize 0
set feedback off
set newpage 0
Set Verify off
set arraysize 5
ttitle off
define MSG_OBJ = &1
define NODE_NAME = &2
select 'node_name:', a.node_name as node_name,
'local_creation_time:', substr(TO_CHAR(b.local_creation_time,'MM/DD/YY HH24:MI:SS'),1,17) as local_creation_time,
'local_receiving_time:', substr(TO_CHAR(b.local_receiving_time,'MM/DD/YY HH24:MI:SS'),1,17) as local_receiving_time,
'message_id:', b.message_number as message_number,
'severity:', TO_CHAR(b.severity) as severity,
'text_part:', c.text_part as text_part,
'object:', b.object as object,
'source_policy:', b.msg_source_name as source_policy,
'trouble_ticket:', TO_CHAR(b.trouble_tick_flag) as trouble_ticket
from opc_msg_text c, opc_act_messages b, opc_node_names a
where c.message_number = b.message_number and b.node_id = a.node_id and b.object like '%&MSG_OBJ%' and a.node_name like '%&NODE_NAME%';
exit;
