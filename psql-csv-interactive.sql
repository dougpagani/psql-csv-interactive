---------------------
-- CSV_INTERACTIVE --
---------------------
:s cie :csv_interactive_exec

----------------------------
-- HEREDOC FOR PSQL STUFF --
----------------------------
SELECT $$
---------------
-- Constants --
---------------
\set TMP_FILE '/tmp/tmp.csv'
\set ORIG_FILE '/tmp/tmpo.csv'
\set CSV_CONFIG ''' WITH DELIMITER '','' CSV HEADER NULL ''NULL'''
\set COMPARE_FILE '/tmp/tmp-about-to-overwrite.csv'
\set DEFAULT_EDITOR_FOR_EVAN 'libreoffice --nologo --nolockcheck --quickstart --norestore'
-- Add this to debug complications cmd-constructions
\set ecmd ':e :cmd \\prompt ''[pause]'' pause' \\ -- comments work after \\ for meta-commands
    /* :e :cmd */
    /* \prompt '[pause]' pause */


BEGIN; -- We are doing a transaction since we'll want to rollback

-----------------------------------------------------------------------
-- Dynamic Table-of-Interest Selection: Select, Display, Prompt & Check
-----------------------------------------------------------------------
SELECT table_name
FROM information_schema.tables
WHERE table_schema='public'
AND table_type='BASE TABLE';

\prompt 'Please select the table you would like to query: ' csv_interactive_table_name
\set quoted '''' :csv_interactive_table_name ''''

SELECT
EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = :quoted ) as is_table \gset

\if :is_table
    \echo \\ -- do nothing
\else
    -- Prompt that the user should exit
    \set p '\\prompt ''[^C to exit -- ' :quoted ' is not a table]'' _var' \\ :p
\endif

------------------------------------
-- Copy the Table & make a backup --
------------------------------------
-- Copy the table to a buffer to be edited
\set copy_table_to_buffer '\\copy "' :csv_interactive_table_name '" to ''' :TMP_FILE :CSV_CONFIG
    :copy_table_to_buffer
-- ... And take the backup of the original to compare later
\set shell_copy '\\! cp ' :TMP_FILE ' ' :ORIG_FILE ';' \\ :shell_copy


----------
-- EDIT --
----------
\set edit '\\! ${EDITOR-':DEFAULT_EDITOR_FOR_EVAN '}' ' ' :TMP_FILE \\ :edit

---------------------------------
-- FINISHED: No longer editing --
---------------------------------
\set diff_edits '\\! git diff --color ' :ORIG_FILE ' ' :TMP_FILE ';' \\ :diff_edits
    \echo '(^^^ changes you intend to make)'
    \prompt 'Is this good? [CTRL-C to abort, continue otherwise]' answer 

-----------------------------
-- CHECK FOR ASYNC CHANGES --
-----------------------------
LOCK :csv_interactive_table_name IN EXCLUSIVE MODE; -- will prevent writes while we review what we are about to overwrite

\set copy_table_to_buffer '\\copy "' :csv_interactive_table_name '" to ''' :COMPARE_FILE :CSV_CONFIG
    :copy_table_to_buffer

-- Check differences, and prompt if they are different
\set diff_async_changes '\\! git diff --color ' :ORIG_FILE ' ' :COMPARE_FILE \\ :diff_async_changes

\set MSG '(^^^ SOMEONE ELSE CHANGED THE DATABASE SINCE YOU FIRST STARTED EDITING)'
\set ASK '\n********** OVERWRITE THEIR CHANGES???\n\n********** ARE YOU THAT HEARTLESS???\n\n[CTRL-C TWICE to halt (losing your own changes), enter to nuke & pave (accept your edited version and delete their changes)]'
\set check_overwrites '\\! bash -c '' diff &>/dev/null ' :ORIG_FILE ' ' :COMPARE_FILE ' || { mkdir -f /tmp/csvsqledits; cp -f ' :COMPARE_FILE ' ' :ORIG_FILE ' ' :TMP_FILE ' /tmp/csvsqledits; ' ' echo "' :MSG '" && echo -e "' :ASK '"; };'' ' 
    :check_overwrites
    -- We need to prompt here because ^C'ing out of bash does not have an
    -- ... effect on execution of the rest of psql stuff.
    \prompt '[CTRL-C to abort, enter to proceed]' asdf

----------------------------------------------
-- OVERWRITE (IF WE HAVE NOT CANCELLED YET) --
----------------------------------------------
TRUNCATE TABLE :csv_interactive_table_name;
\set copy_buffer_to_table '\\copy "' :csv_interactive_table_name '" from ''' :TMP_FILE :CSV_CONFIG \\ :copy_buffer_to_table

-- COPY :csv_interactive_table_name FROM STDOUT WITH (FORMAT CSV, HEADER);
/* ^ wont work because stdout wont respect \o when going in the from-direction,
   will actually block and wait for user input.
 
  Input form of this now-deprecated use of COPY:
    \o |tee /tmp/tmp.csv > /tmp/tmpo.csv
    COPY :csv_interactive_table_name TO STDOUT WITH (FORMAT CSV, HEADER);
    \o /dev/stdout
    --make sure the pipe is closed & buffers flush
*/

\echo 'FINISHED UPLOAD FROM CSV'

END;
$$ as csv_interactive_exec_scriptbody \gset 
-- ^^^ This looks f'd up but we're adding this layer of indirection to protect
-- ... our psql-stuff.
-- Set output, Write to output, Reset output so no subsequent weirdness, then source the psql-script
\set csv_interactive_exec '\\o /tmp/ciscript \\\\ \\qecho :csv_interactive_exec_scriptbody \\\\ \\o /dev/stdout \\\\ \\i /tmp/ciscript'
-- ... or \g /tmp/ciscript after the sql cmd, but then that needlessly writes even if you dont use this script

