       >>source format free
identification division.
program-id. myaccounting.
environment division.
input-output section.
file-control.
    select optional store-file assign to data-path
        organization indexed access dynamic
        record key disk-key
        lock mode exclusive
        file status io-status.
    select export-file assign to export-path
        organization line sequential file status export-status.
    select sql-view-file assign to sql-view-path
        organization line sequential file status sql-view-status.
data division.
file section.
fd store-file.
01 disk-record.
   05 disk-key pic x(10).
   05 disk-payload pic x(5184).
fd export-file.
01 export-row pic x(512).
fd sql-view-file.
01 sql-view-row pic x(16384).
working-storage section.
01 sql-directory pic x(512).
01 sql-view-path pic x(640).
01 sql-view-name pic x(80).
01 sql-view-status pic xx.
01 sql-invoice-id pic Z(9)9.
01 data-path pic x(512) value 'data/myaccounting.dat'.
01 export-path pic x(512) value 'exports/accountant.csv'.
01 env-value pic x(512).
01 io-status pic xx.
01 export-status pic xx.
01 store-open binary-char value 0.
01 lock-held binary-char value 0.
01 lock-path pic x(520).
01 lock-result usage binary-long.
01 row-buffer.
   copy 'record.cpy'.
01 saved-row pic x(5194).
01 cache-table.
   02 cache-row occurs 2000 pic x(5194).
01 row-count binary-long value 0.
01 current-index binary-long.
01 found-index binary-long.
01 doc-index binary-long.
01 config-index binary-long.
01 i binary-long.
01 j binary-long.
01 k binary-long.
01 n binary-long.
01 line-no binary-long.
01 picked-id pic 9(8).
01 picked-kind pic xx.
01 next-id pic 9(8).
01 key-value pic x(10).
01 table-key.
   02 table-kind pic xx.
   02 table-id pic 9(8).
01 menu-choice pic x(8).
01 sub-choice pic x(8).
01 input-text pic x(256).
01 prompt-text pic x(100).
01 finished binary-char value 0.
01 valid-input binary-char.
01 valid-operation binary-char.
01 eof-input binary-char value 0.
01 numeric-value pic s9(12)v9999.
01 numeric-min pic s9(12)v9999.
01 numeric-max pic s9(12)v9999.
01 numeric-scale binary-long.
01 digit-count binary-long.
01 dot-count binary-long.
01 fraction-count binary-long.
01 input-length binary-long.
01 date-value pic 9(8).
01 date-input pic x(10).
01 report-start pic 9(8).
01 report-end pic 9(8).
01 fiscal-start pic 9(8).
01 fiscal-end pic 9(8).
01 company-name pic x(80).
01 currency-code pic xxx.
01 tax-rate pic 9(3)v99.
01 total-debits pic s9(15)v99.
01 total-credits pic s9(15)v99.
01 amount-value pic s9(15)v99.
01 paid-value pic s9(15)v99.
01 due-value pic s9(15)v99.
01 revenue-value pic s9(15)v99.
01 expense-value pic s9(15)v99.
01 asset-value pic s9(15)v99.
01 liability-value pic s9(15)v99.
01 equity-value pic s9(15)v99.
01 profit-value pic s9(15)v99.
01 amount-display pic -(15)9.99.
01 quantity-display pic ZZZZ9.99.
01 id-display pic ZZZZZZZ9.
01 date-display pic 9999/99/99.
01 account-code pic 9(4).
01 account-name pic x(80).
01 account-class pic x.
01 balance-table.
   02 account-balance occurs 2000 pic s9(15)v99.
01 posting-account pic 9(4).
01 posting-value pic s9(15)v99.
01 lookup-name pic x(80).
01 lookup-class pic x.
01 target-state pic x.
01 total-minutes binary-long.
01 shift-start binary-long.
01 shift-end binary-long.
01 clock-value binary-long.
01 last-end binary-long.
01 selected-staff pic 9(8).
01 selected-date pic 9(8).
01 csv-debit pic -(15)9.99.
01 csv-credit pic -(15)9.99.
01 csv-name pic x(160).
01 csv-position binary-long.
procedure division.
main.
    accept sql-directory from environment 'MYACCOUNT_SQL_DIR'
        on exception move spaces to sql-directory
    end-accept
    if sql-directory not = spaces
        perform sql-browser
        goback
    end-if
    accept env-value from environment 'MYACCOUNT_FILE'
        on exception move spaces to env-value
    end-accept
    if env-value not = spaces move env-value to data-path end-if
    accept env-value from environment 'MYACCOUNT_EXPORT'
        on exception move spaces to env-value
    end-accept
    if env-value not = spaces move env-value to export-path end-if
    move function concatenate(function trim(data-path), '.lock', x'00')
        to lock-path
    call 'CBL_CREATE_DIR' using lock-path returning lock-result
    if lock-result not = 0
        display 'Cannot open data file: another session may be running.'
        display 'Check the parent directory and the .lock directory.'
        move 1 to return-code goback
    end-if
    move 1 to lock-held
    open i-o store-file
    if io-status not = '00' and not = '05'
        display 'Cannot open data file: ' function trim(data-path)
        display 'File status ' io-status
            '. Create the directory and close any other session.'
        perform release-lock
        move 1 to return-code
        goback
    end-if
    move 1 to store-open
    perform load-store
    if row-count = 0 perform initialize-store end-if
    perform load-config
    display 'MYACCOUNTING - COBOL terminal edition 0.1'
    display 'Local single-user prototype. Currency: ' currency-code
    perform until finished = 1
        display ' '
        display function trim(company-name)
        display '1 Dashboard       2 Configuration     3 Invoices'
        display '4 Cash receipts   5 Journal           6 Accounts'
        display '7 Reports         8 Timesheets        9 CSV export'
        display '0 Exit'
        move 'Choice: ' to prompt-text perform ask
        move function trim(input-text) to menu-choice
        if eof-input = 1 move '0' to menu-choice end-if
        evaluate menu-choice
            when '1' perform dashboard
            when '2' perform configuration-menu
            when '3' perform invoice-menu
            when '4' perform receipt-menu
            when '5' perform journal-menu
            when '6' perform accounts-menu
            when '7' perform reports-menu
            when '8' perform timesheet-menu
            when '9' perform export-ledger
            when '0' move 1 to finished
            when other display 'Choose a listed option.'
        end-evaluate
    end-perform
    close store-file
    perform release-lock
    display 'Records saved. Goodbye.'
    move 0 to return-code
    goback.

sql-browser.
    move 'company.txt' to sql-view-name
    perform sql-open-view
    if sql-view-status not = '00'
        display 'SQL Server division data is missing. Restart the launcher.'
        move 1 to return-code exit paragraph
    end-if
    read sql-view-file
    if sql-view-status not = '00' or sql-view-row = spaces
        close sql-view-file
        display 'SQL Server division data is invalid. Restart the launcher.'
        move 1 to return-code exit paragraph
    end-if
    move sql-view-row to company-name
    close sql-view-file
    display 'MYACCOUNTING - SQL Server browser'
    move 'overview.txt' to sql-view-name perform sql-display-view
    perform until finished = 1
        display ' '
        display function trim(company-name)
        display 'Read-only SQL Server data; restart to refresh.'
        display '1 Overview        2 Related records    3 Invoices'
        display '4 Cash receipts   5 Journals           6 Accounts'
        display '7 General ledger  8 Timesheets         0 Exit'
        move 'Choice: ' to prompt-text perform ask
        evaluate function trim(input-text)
            when '1'
                move 'overview.txt' to sql-view-name
                perform sql-display-view
            when '2' perform sql-related-menu
            when '3' perform sql-invoice-menu
            when '4'
                move 'receipts.txt' to sql-view-name
                perform sql-display-view
            when '5'
                move 'journals.txt' to sql-view-name
                perform sql-display-view
                move 'journal_lines.txt' to sql-view-name
                perform sql-display-view
            when '6'
                move 'accounts.txt' to sql-view-name
                perform sql-display-view
            when '7'
                move 'ledger.txt' to sql-view-name
                perform sql-display-view
            when '8' perform sql-timesheet-menu
            when '0' move 1 to finished
            when other
                if eof-input = 0 display 'Choose a listed option.' end-if
        end-evaluate
    end-perform
    display 'Goodbye.'
    move 0 to return-code.

sql-open-view.
    move spaces to sql-view-path
    string function trim(sql-directory) '/'
        function trim(sql-view-name) into sql-view-path
    end-string
    open input sql-view-file.

sql-display-view.
    perform sql-open-view
    if sql-view-status = '35'
        display 'No record found for this division.' exit paragraph
    end-if
    if sql-view-status not = '00'
        display 'Cannot read SQL Server records: ' sql-view-status
        exit paragraph
    end-if
    perform until exit
        read sql-view-file
        evaluate sql-view-status
            when '10' exit perform
            when '00' display function trim(sql-view-row trailing)
            when other
                display 'SQL Server display read error: ' sql-view-status
                exit perform
        end-evaluate
    end-perform
    close sql-view-file.

sql-invoice-menu.
    *> Show existing invoices immediately on entering the invoice option.
    move 'invoices.txt' to sql-view-name perform sql-display-view
    perform until finished = 1
        display '2 List  3 View invoice and related lines/receipts  0 Back'
        move 'Invoice choice: ' to prompt-text perform ask
        evaluate function trim(input-text)
            when '2'
                move 'invoices.txt' to sql-view-name
                perform sql-display-view
            when '3'
                move 'Invoice ID from the list: ' to prompt-text
                move 0 to numeric-scale move 1 to numeric-min
                move 2147483647 to numeric-max perform read-number
                move numeric-value to sql-invoice-id
                move spaces to sql-view-name
                string 'invoice-' function trim(sql-invoice-id) '.txt'
                    into sql-view-name end-string
                perform sql-display-view
            when '0' exit perform
            when other
                if eof-input = 0 display 'Choose a listed option.' end-if
        end-evaluate
    end-perform.

sql-related-menu.
    display '1 Customers  2 Projects  3 Consultants  4 Services  5 Taxes'
    move 'Related records choice (0 back): ' to prompt-text perform ask
    move spaces to sql-view-name
    evaluate function trim(input-text)
        when '1' move 'customers.txt' to sql-view-name
        when '2' move 'projects.txt' to sql-view-name
        when '3' move 'consultants.txt' to sql-view-name
        when '4' move 'services.txt' to sql-view-name
        when '5' move 'taxes.txt' to sql-view-name
        when '0' continue
        when other
            if eof-input = 0 display 'Choose a listed option.' end-if
    end-evaluate
    if sql-view-name not = spaces perform sql-display-view end-if.

sql-timesheet-menu.
    display '1 Timesheets  2 Daily entries  3 Work items'
    move 'Timesheet choice (0 back): ' to prompt-text perform ask
    move spaces to sql-view-name
    evaluate function trim(input-text)
        when '1' move 'timesheets.txt' to sql-view-name
        when '2' move 'days.txt' to sql-view-name
        when '3' move 'work.txt' to sql-view-name
        when '0' continue
        when other
            if eof-input = 0 display 'Choose a listed option.' end-if
    end-evaluate
    if sql-view-name not = spaces perform sql-display-view end-if.

ask.
    move spaces to input-text
    display function trim(prompt-text trailing) with no advancing
    accept input-text
        on exception move 1 to eof-input finished
    end-accept
    *> Accept piped Windows CRLF input as well as terminal/Linux input.
    inspect input-text replacing all x'0d' by space.

required-text.
    perform until exit
        perform ask
        if eof-input = 1 perform abort-input end-if
        if function trim(input-text) not = spaces exit perform end-if
        display 'A value is required.'
    end-perform.

abort-input.
    if store-open = 1 close store-file end-if
    perform release-lock
    display 'Input ended; unfinished work discarded.'
    move 0 to return-code
    stop run.

release-lock.
    if lock-held = 1
        call 'CBL_DELETE_DIR' using lock-path returning lock-result
        if lock-result not = 0
            display 'Could not remove session lock; check .lock directory.'
        end-if
        move 0 to lock-held
    end-if.

read-number.
    perform until exit
        perform ask
        if eof-input = 1 perform abort-input end-if
        move function trim(input-text) to input-text
        move 1 to valid-input
        move 0 to dot-count digit-count fraction-count
        compute input-length = function length(
            function trim(input-text trailing))
        if input-length = 0 move '0' to input-text
            move 1 to input-length end-if
        perform varying k from 1 by 1 until k > input-length
            evaluate true
                when input-text(k:1) >= '0' and <= '9'
                    add 1 to digit-count
                    if dot-count > 0 add 1 to fraction-count end-if
                when input-text(k:1) = '.' add 1 to dot-count
                when other move 0 to valid-input
            end-evaluate
        end-perform
        if dot-count > 1 or digit-count = 0 or digit-count > 12
            or fraction-count > numeric-scale
            move 0 to valid-input
        end-if
        if valid-input = 1
            compute numeric-value = function numval(input-text)
            if numeric-value < numeric-min or > numeric-max
                move 0 to valid-input
            end-if
        end-if
        if valid-input = 1 exit perform end-if
        display 'Invalid number or out of range (no signs/commas).'
    end-perform.

read-money.
    move 2 to numeric-scale
    move 0 to numeric-min
    move 99999999.99 to numeric-max
    perform read-number.

read-date.
    perform until exit
        perform required-text
        move 0 to valid-input
        if function length(function trim(input-text)) = 10
            and input-text(5:1) = '-'
            and input-text(8:1) = '-'
            and input-text(1:4) is numeric
            and input-text(6:2) is numeric
            and input-text(9:2) is numeric
            move function concatenate(input-text(1:4),
                input-text(6:2), input-text(9:2)) to date-input
            move date-input(1:8) to date-value
            if function test-date-yyyymmdd(date-value) = 0
                move 1 to valid-input
            end-if
        end-if
        if valid-input = 1 exit perform end-if
        display 'Enter a real calendar date as YYYY-MM-DD.'
    end-perform.

read-fiscal-date.
    perform until exit
        perform read-date
        if date-value >= fiscal-start and <= fiscal-end
            exit perform
        end-if
        display 'Date must be inside the configured fiscal year.'
    end-perform.

confirm-save.
    move 'Save this record? (Y/N): ' to prompt-text perform ask
    move 0 to valid-operation
    if function upper-case(function trim(input-text)) = 'Y'
        move 1 to valid-operation
    else display 'Cancelled.' end-if.

load-store.
    move low-values to disk-key
    start store-file key >= disk-key
        invalid key continue
        not invalid key
            perform until exit
                read store-file next record
                    at end exit perform
                end-read
                if io-status not = '00' perform storage-error end-if
                if row-count >= 2000
                    display 'Capacity exceeded (2000 records).'
                    close store-file perform release-lock
                    move 1 to return-code stop run
                end-if
                add 1 to row-count
                move disk-record to cache-row(row-count)
            end-perform
    end-start
    if io-status not = '00' and not = '10' and not = '23'
        perform storage-error
    end-if.

storage-error.
    display 'Storage error ' io-status '. Operation stopped.'
    if store-open = 1 close store-file end-if
    perform release-lock
    move 1 to return-code stop run.

find-record.
    move 0 to found-index
    move picked-kind to table-kind move picked-id to table-id
    perform varying j from 1 by 1 until j > row-count
        if cache-row(j)(1:10) = table-key
            move j to found-index exit perform
        end-if
    end-perform.

allocate-id.
    move 0 to next-id
    perform varying j from 1 by 1 until j > row-count
        move cache-row(j)(1:10) to table-key
        if table-kind = picked-kind and table-id > next-id
            move table-id to next-id
        end-if
    end-perform
    if next-id = 99999999
        display 'Number range exhausted.'
        perform abort-input
    end-if
    add 1 to next-id.

save-record.
    move r-key to disk-key
    move r-kind to picked-kind move r-id to picked-id
    perform find-record
    if found-index = 0 and row-count >= 2000
        display 'Capacity reached; record was not saved.'
        exit paragraph
    end-if
    move row-buffer to disk-record
    if found-index = 0
        write disk-record
    else
        rewrite disk-record
    end-if
    if io-status not = '00' perform storage-error end-if
    *> Flush pending output while retaining the exclusive file lock.
    commit
    if io-status not = '00' perform storage-error end-if
    if found-index = 0
        add 1 to row-count move row-count to found-index
    end-if
    move row-buffer to cache-row(found-index).

initialize-store.
    initialize row-buffer
    move 'CF' to r-kind move 1 to r-id
    move '1' to r-state
    move 'My Service Business' to r-name
    move 'CAD' to r-text
    move function current-date(1:4) to input-text
    move function concatenate(input-text(1:4), '0101') to r-date
    move function concatenate(input-text(1:4), '1231') to r-extra
    move 13 to r-rate perform save-record
    move 1000 to account-code move 'Bank' to account-name
    move 'A' to account-class perform seed-account
    move 1100 to account-code
    move 'Accounts receivable' to account-name perform seed-account
    move 2100 to account-code move 'Tax payable' to account-name
    move 'L' to account-class perform seed-account
    move 3000 to account-code move 'Owner equity' to account-name
    move 'E' to account-class perform seed-account
    move 4000 to account-code move 'Service revenue' to account-name
    move 'R' to account-class perform seed-account
    move 5000 to account-code move 'Operating expenses' to account-name
    move 'X' to account-class perform seed-account.

seed-account.
    initialize row-buffer move 'AC' to r-kind
    move account-code to r-id move account-name to r-name
    move account-class to r-class perform save-record.

load-config.
    move 'CF' to picked-kind move 1 to picked-id
    perform find-record
    if found-index = 0
        display 'Missing configuration; data file cannot be used.'
        perform abort-input
    end-if
    move found-index to config-index
    move cache-row(config-index) to row-buffer
    if r-state not = '1'
        display 'Unsupported data schema; stopped.' perform abort-input
    end-if
    move r-name to company-name move r-text(1:3) to currency-code
    move r-rate to tax-rate move r-date to fiscal-start
    move r-extra(1:8) to fiscal-end.

configuration-menu.
    display '1 Company/fiscal settings  2 Add client  3 List clients'
    display '4 Add service  5 List services  6 Add project'
    display '7 List projects  8 Add consultant  9 List consultants'
    move 'Configuration choice (0 back): ' to prompt-text perform ask
    evaluate function trim(input-text)
        when '1' perform edit-settings
        when '2' move 'CL' to picked-kind perform add-master
        when '3' move 'CL' to picked-kind perform list-master
        when '4' move 'SV' to picked-kind perform add-master
        when '5' move 'SV' to picked-kind perform list-master
        when '6' move 'PR' to picked-kind perform add-master
        when '7' move 'PR' to picked-kind perform list-master
        when '8' move 'ST' to picked-kind perform add-master
        when '9' move 'ST' to picked-kind perform list-master
        when '0' continue
        when other display 'Choose a listed option.'
    end-evaluate.

edit-settings.
    move cache-row(config-index) to row-buffer
    move 'Company name: ' to prompt-text perform required-text
    move input-text to r-name
    move 'Currency (3 letters): ' to prompt-text
    perform until exit
        perform required-text
        if function length(function trim(input-text)) = 3
            and input-text(1:3) is alphabetic
            exit perform end-if
        display 'Enter three letters, for example CAD.'
    end-perform
    move function upper-case(input-text(1:3)) to r-text
    move 'Fiscal start (YYYY-MM-DD): ' to prompt-text
    perform read-date move date-value to r-date
    perform until exit
        move 'Fiscal end (YYYY-MM-DD): ' to prompt-text
        perform read-date
        if date-value >= r-date exit perform end-if
        display 'End must follow start.'
    end-perform
    *> Never hide existing posted documents by changing fiscal dates.
    move date-value to r-extra
    move 'Tax percentage (0-100): ' to prompt-text
    move 0 to numeric-min move 100 to numeric-max
    move 2 to numeric-scale perform read-number
    move numeric-value to r-rate
    perform confirm-save
    if valid-operation = 1
        perform save-record perform load-config
        display 'Settings saved. Existing invoice taxes are unchanged.'
    end-if.

add-master.
    perform allocate-id
    initialize row-buffer
    move picked-kind to r-kind move next-id to r-id
    move 'Name / description: ' to prompt-text
    perform required-text move input-text to r-name
    evaluate r-kind
        when 'CL'
            move 'Billing email (optional): ' to prompt-text
            perform ask move input-text to r-text
            move 'Address (optional): ' to prompt-text
            perform ask move input-text to r-extra
        when 'SV'
            move 'Service code: ' to prompt-text
            perform required-text
            move function upper-case(input-text) to r-text
            move 1 to valid-operation
            perform varying i from 1 by 1 until i > row-count
                move cache-row(i)(1:10) to table-key
                if table-kind = 'SV'
                    move row-buffer to saved-row
                    move cache-row(i) to row-buffer
                    if r-text = function upper-case(input-text)
                        move 0 to valid-operation end-if
                    move saved-row to row-buffer
                end-if
            end-perform
            if valid-operation = 0
                display 'Service code already exists.' exit paragraph
            end-if
            move 'Unit price: ' to prompt-text perform read-money
            move numeric-value to r-total
        when 'PR'
            move 'Project reference: ' to prompt-text
            perform required-text move input-text to r-text
        when other continue
    end-evaluate
    perform confirm-save
    if valid-operation = 1
        perform save-record
        move r-id to id-display
        display 'Created ' r-kind '-' function trim(id-display)
    end-if.

list-master.
    display 'ID        Name / description'
    perform varying i from 1 by 1 until i > row-count
        move cache-row(i)(1:10) to table-key
        if table-kind = picked-kind
            move cache-row(i) to row-buffer
            move r-id to id-display
            display function trim(id-display) '  '
                function trim(r-name) '  ' function trim(r-text)
            if r-kind = 'SV'
                move r-total to amount-display
                display '  Unit price: ' function trim(amount-display)
            end-if
        end-if
    end-perform.

pick-master.
    *> Caller sets kind and prompt. Preserve the document under construction.
    move row-buffer to saved-row
    perform until exit
        move 0 to numeric-scale move 1 to numeric-min
        move 99999999 to numeric-max perform read-number
        move numeric-value to picked-id
        perform find-record
        if found-index > 0
            move cache-row(found-index) to row-buffer
            move r-name to lookup-name move r-class to lookup-class
            move saved-row to row-buffer exit perform
        end-if
        display 'Record not found.'
    end-perform.

pick-document.
    move 'Document number: ' to prompt-text
    move 0 to numeric-scale move 1 to numeric-min
    move 99999999 to numeric-max perform read-number
    move numeric-value to picked-id perform find-record
    if found-index = 0
        display 'Document not found.'
    else
        move found-index to doc-index
        move cache-row(doc-index) to row-buffer
    end-if.

invoice-menu.
    display '1 New invoice  2 List  3 View  4 Approve  5 Void'
    display '6 Replace draft'
    move 'Invoice choice (0 back): ' to prompt-text perform ask
    move function trim(input-text) to sub-choice
    evaluate sub-choice
        when '1' perform new-invoice
        when '2' move 'IN' to picked-kind perform list-documents
        when '3' when '4' when '5' when '6'
            move 'IN' to picked-kind perform pick-document
            if found-index > 0
                evaluate sub-choice
                    when '3' perform show-invoice
                    when '4' perform approve-invoice
                    when '5' perform void-invoice
                    when '6'
                        if r-state = 'D'
                            move r-id to next-id
                            initialize row-buffer
                            move 'IN' to r-kind move next-id to r-id
                            move 'D' to r-state
                            move tax-rate to r-rate
                            perform collect-invoice
                        else display 'Only drafts can be replaced.' end-if
                end-evaluate
            end-if
        when '0' continue
        when other display 'Choose a listed option.'
    end-evaluate.

new-invoice.
    move 'IN' to picked-kind perform allocate-id
    initialize row-buffer move 'IN' to r-kind
    move next-id to r-id move 'D' to r-state
    move tax-rate to r-rate
    perform collect-invoice.

collect-invoice.
    move 'CL' to picked-kind move 'Client ID: ' to prompt-text
    perform pick-master move picked-id to r-client
    move lookup-name to r-name
    move 'Invoice date (YYYY-MM-DD): ' to prompt-text
    perform read-fiscal-date move date-value to r-date
    move 'Optional project ID (0 none): ' to prompt-text
    perform optional-project
    move 'Optional consultant ID (0 none): ' to prompt-text
    perform optional-staff
    move 'Invoice note (optional): ' to prompt-text perform ask
    move input-text to r-text
    move 'Number of service lines (1-20): ' to prompt-text
    move 1 to numeric-min move 20 to numeric-max
    move 0 to numeric-scale perform read-number
    move numeric-value to r-count
    perform varying line-no from 1 by 1 until line-no > r-count
        display 'Service line ' line-no
        move 'SV' to picked-kind move 'Service ID: ' to prompt-text
        perform pick-master
        move lookup-name to r-description(line-no)
        *> Read the service without disturbing the invoice.
        move row-buffer to saved-row
        move cache-row(found-index) to row-buffer
        move r-total to amount-value
        move saved-row to row-buffer
        move 'Quantity (0.01-99999.99): ' to prompt-text
        move 0.01 to numeric-min move 99999.99 to numeric-max
        move 2 to numeric-scale perform read-number
        move numeric-value to r-quantity(line-no)
        move amount-value to amount-display
        display 'Default price: ' function trim(amount-display)
        move 'Unit price: ' to prompt-text perform read-money
        move numeric-value to r-price(line-no)
        compute r-debit(line-no) rounded =
            r-quantity(line-no) * r-price(line-no)
            on size error
                display 'Line amount too large; invoice discarded.'
                exit paragraph
        end-compute
        add r-debit(line-no) to r-subtotal
            on size error
                display 'Invoice too large; discarded.' exit paragraph
        end-add
    end-perform
    compute r-tax rounded = r-subtotal * r-rate / 100
        on size error display 'Tax too large.' exit paragraph
    end-compute
    compute r-total = r-subtotal + r-tax
        on size error display 'Invoice total too large.' exit paragraph
    end-compute
    perform show-invoice
    perform confirm-save
    if valid-operation = 1
        perform save-record display 'Draft invoice saved.'
    end-if.

optional-project.
    move 0 to numeric-min move 99999999 to numeric-max
    move 0 to numeric-scale perform read-number
    if numeric-value > 0
        move numeric-value to picked-id move 'PR' to picked-kind
        perform find-record
        if found-index = 0
            display 'Project not found; document discarded.'
            perform abort-input
        end-if
        move picked-id to r-project
    end-if.

optional-staff.
    move 0 to numeric-min move 99999999 to numeric-max
    move 0 to numeric-scale perform read-number
    if numeric-value > 0
        move numeric-value to picked-id move 'ST' to picked-kind
        perform find-record
        if found-index = 0
            display 'Consultant not found; document discarded.'
            perform abort-input
        end-if
        move picked-id to r-staff
    end-if.

show-invoice.
    move r-id to id-display move r-date to date-display
    display 'INVOICE INV-' function trim(id-display) '  '
        date-display '  State: ' r-state
    display function trim(company-name) ' / ' currency-code
    display 'Bill to: ' function trim(r-name)
    perform varying n from 1 by 1 until n > r-count
        move r-quantity(n) to quantity-display
        move r-debit(n) to amount-display
        display function trim(r-description(n)) '  Qty '
            function trim(quantity-display) '  Amount '
            function trim(amount-display)
    end-perform
    move r-subtotal to amount-display
    display 'Subtotal: ' function trim(amount-display)
    move r-tax to amount-display
    display 'Tax: ' function trim(amount-display)
    move r-total to amount-display
    display 'Total: ' function trim(amount-display)
    display function trim(r-text).

approve-invoice.
    if r-state not = 'D'
        display 'Only draft invoices can be approved.' exit paragraph
    end-if
    perform show-invoice
    display 'Approval posts Dr 1100 / Cr 4000 and 2100.'
    perform confirm-save
    if valid-operation = 1
        move 'A' to r-state perform save-record
        display 'Invoice approved and posted.'
    end-if.

invoice-paid.
    *> Derived from immutable posted receipts; do not maintain a paid counter.
    move 0 to paid-value
    move r-id to picked-id
    move row-buffer to saved-row
    perform varying j from 1 by 1 until j > row-count
        move cache-row(j)(1:10) to table-key
        if table-kind = 'CR'
            move cache-row(j) to row-buffer
            if r-state = 'P' and r-project = picked-id
                add r-total to paid-value
            end-if
        end-if
    end-perform
    move saved-row to row-buffer.

void-invoice.
    if r-state = 'V' display 'Invoice already void.' exit paragraph end-if
    perform invoice-paid
    if paid-value > 0
        display 'Invoice has posted payments; cannot void.' exit paragraph
    end-if
    perform confirm-save
    if valid-operation = 1
        move 'V' to r-state perform save-record
        display 'Invoice void. Excluded from receivables and ledger.'
    end-if.

list-documents.
    display 'ID  Date        State  Client/description  Total'
    perform varying i from 1 by 1 until i > row-count
        move cache-row(i)(1:10) to table-key
        if table-kind = picked-kind
            move cache-row(i) to row-buffer
            move r-id to id-display move r-date to date-display
            move r-total to amount-display
            display function trim(id-display) '  ' date-display '  '
                r-state '  ' function trim(r-name) '  '
                function trim(amount-display)
        end-if
    end-perform.

receipt-menu.
    display '1 New draft receipt  2 List  3 Preview  4 Post'
    move 'Receipt choice (0 back): ' to prompt-text perform ask
    move function trim(input-text) to sub-choice
    evaluate sub-choice
        when '1' perform new-receipt
        when '2' move 'CR' to picked-kind perform list-documents
        when '3' when '4'
            move 'CR' to picked-kind perform pick-document
            if found-index > 0
                perform show-receipt
                if sub-choice = '4' perform post-receipt end-if
            end-if
        when '0' continue
        when other display 'Choose a listed option.'
    end-evaluate.

new-receipt.
    move 'IN' to picked-kind perform pick-document
    if found-index = 0 exit paragraph end-if
    if r-state not = 'A'
        display 'Receipts require an approved invoice.' exit paragraph
    end-if
    perform invoice-paid
    compute due-value = r-total - paid-value
    if due-value <= 0 display 'Invoice is already paid.' exit paragraph end-if
    move r-id to n move r-client to current-index
    move r-date to selected-date
    move r-name to lookup-name
    move 'CR' to picked-kind perform allocate-id
    initialize row-buffer move 'CR' to r-kind
    move next-id to r-id move 'D' to r-state
    move n to r-project move current-index to r-client
    move lookup-name to r-name
    move 'Receipt date (YYYY-MM-DD): ' to prompt-text
    perform read-fiscal-date move date-value to r-date
    *> Date cannot precede the invoice it settles.
    if r-date < selected-date
        display 'Receipt date precedes invoice; discarded.' exit paragraph
    end-if
    move due-value to amount-display
    display 'Outstanding: ' function trim(amount-display)
    move 'Amount received: ' to prompt-text
    move 0.01 to numeric-min move due-value to numeric-max
    if numeric-max > 99999999.99 move 99999999.99 to numeric-max end-if
    move 2 to numeric-scale perform read-number
    move numeric-value to r-total
    move 'Memo: ' to prompt-text perform ask move input-text to r-text
    perform show-receipt perform confirm-save
    if valid-operation = 1
        perform save-record display 'Draft receipt saved.'
    end-if.

show-receipt.
    move r-id to id-display move r-total to amount-display
    display 'RECEIPT CR-' function trim(id-display) ' State: ' r-state
    display function trim(r-name) ' Amount: '
        function trim(amount-display) ' Invoice: ' r-project
    display 'Dr 1000 Bank / Cr 1100 Accounts receivable'
    display function trim(r-text).

post-receipt.
    if r-state not = 'D'
        display 'Only draft receipts can be posted.' exit paragraph
    end-if
    *> Recheck balance at posting: other drafts may target this invoice.
    move row-buffer to cache-row(doc-index)
    move 'IN' to picked-kind move r-project to picked-id
    perform find-record
    if found-index = 0
        display 'Invoice no longer exists.' exit paragraph end-if
    move cache-row(found-index) to row-buffer
    if r-state not = 'A'
        display 'Invoice must be approved.' exit paragraph end-if
    perform invoice-paid
    compute due-value = r-total - paid-value
    move cache-row(doc-index) to row-buffer
    if r-total > due-value
        display 'Payment exceeds current outstanding balance.'
        exit paragraph
    end-if
    perform confirm-save
    if valid-operation = 1
        move 'P' to r-state perform save-record
        display 'Receipt posted; record is permanent.'
    end-if.

journal-menu.
    display '1 New draft journal  2 List  3 Preview  4 Post'
    display '5 Replace draft'
    move 'Journal choice (0 back): ' to prompt-text perform ask
    move function trim(input-text) to sub-choice
    evaluate sub-choice
        when '1' perform new-journal
        when '2' move 'JE' to picked-kind perform list-documents
        when '3' when '4' when '5'
            move 'JE' to picked-kind perform pick-document
            if found-index > 0
                evaluate sub-choice
                    when '3' perform show-journal
                    when '4' perform show-journal perform post-journal
                    when '5'
                        if r-state = 'D'
                            move r-id to next-id
                            initialize row-buffer
                            move 'JE' to r-kind move next-id to r-id
                            move 'D' to r-state perform collect-journal
                        else display 'Only drafts can be replaced.' end-if
                end-evaluate
            end-if
        when '0' continue
        when other display 'Choose a listed option.'
    end-evaluate.

new-journal.
    move 'JE' to picked-kind perform allocate-id
    initialize row-buffer move 'JE' to r-kind
    move next-id to r-id move 'D' to r-state
    perform collect-journal.

collect-journal.
    move 'Journal date (YYYY-MM-DD): ' to prompt-text
    perform read-fiscal-date move date-value to r-date
    move 'Description: ' to prompt-text perform required-text
    move input-text to r-name
    move 'Reference (optional): ' to prompt-text perform ask
    move input-text to r-text
    move 'Number of lines (2-20): ' to prompt-text
    move 2 to numeric-min move 20 to numeric-max
    move 0 to numeric-scale perform read-number
    move numeric-value to r-count
    perform varying line-no from 1 by 1 until line-no > r-count
        display 'Journal line ' line-no
        move 'AC' to picked-kind move 'Account code: ' to prompt-text
        perform pick-master move picked-id to r-account(line-no)
        move lookup-name to r-description(line-no)
        *> Control account changes must originate in invoice/receipt flows.
        if r-account(line-no) = 1100
            display 'Use invoices/receipts for account 1100.'
            display 'Journal discarded.' exit paragraph
        end-if
        perform until exit
            move 'Debit: ' to prompt-text perform read-money
            move numeric-value to r-debit(line-no)
            move 'Credit: ' to prompt-text perform read-money
            move numeric-value to r-credit(line-no)
            if (r-debit(line-no) > 0 and r-credit(line-no) = 0)
                or (r-credit(line-no) > 0 and r-debit(line-no) = 0)
                exit perform
            end-if
            display 'Exactly one of debit/credit must be positive.'
        end-perform
    end-perform
    perform show-journal
    if total-debits not = total-credits
        display 'Journal must balance; not saved.' exit paragraph
    end-if
    move total-debits to r-total
    perform confirm-save
    if valid-operation = 1
        perform save-record display 'Draft journal saved.'
    end-if.

show-journal.
    move r-id to id-display
    display 'JOURNAL JE-' function trim(id-display) ' State: ' r-state
    display function trim(r-name)
    move 0 to total-debits total-credits
    perform varying n from 1 by 1 until n > r-count
        add r-debit(n) to total-debits
        add r-credit(n) to total-credits
        move r-debit(n) to amount-display
        display r-account(n) ' Dr ' function trim(amount-display)
            with no advancing
        move r-credit(n) to amount-display
        display ' Cr ' function trim(amount-display) ' '
            function trim(r-description(n))
    end-perform
    move total-debits to amount-display
    display 'Total debits: ' function trim(amount-display)
    move total-credits to amount-display
    display 'Total credits: ' function trim(amount-display).

post-journal.
    if r-state not = 'D'
        display 'Only draft journals can be posted.' exit paragraph
    end-if
    if r-count < 2 or total-debits not = total-credits
        or total-debits = 0
        display 'Journal must have two lines and balance.' exit paragraph
    end-if
    perform confirm-save
    if valid-operation = 1
        move 'P' to r-state perform save-record
        display 'Journal posted; record is permanent.'
    end-if.

accounts-menu.
    display '1 Chart and balances  2 Add account  3 Account history'
    move 'Account choice (0 back): ' to prompt-text perform ask
    evaluate function trim(input-text)
        when '1'
            move 10101 to report-start move 99991231 to report-end
            perform calculate-balances perform show-trial-balance
        when '2' perform add-account
        when '3' perform account-history
        when '0' continue
        when other display 'Choose a listed option.'
    end-evaluate.

add-account.
    move 'Account code (1000-9999): ' to prompt-text
    move 1000 to numeric-min move 9999 to numeric-max
    move 0 to numeric-scale perform read-number
    move numeric-value to picked-id move 'AC' to picked-kind
    perform find-record
    if found-index > 0
        display 'Account code already exists.' exit paragraph
    end-if
    initialize row-buffer move 'AC' to r-kind move picked-id to r-id
    move 'Account name: ' to prompt-text perform required-text
    move input-text to r-name
    perform until exit
        move 'Class A=Asset L=Liability E=Equity R=Revenue X=Expense: '
            to prompt-text perform required-text
        move function upper-case(function trim(input-text)) to input-text
        if input-text = 'A' or 'L' or 'E' or 'R' or 'X'
            exit perform end-if
        display 'Choose A, L, E, R or X.'
    end-perform
    move input-text to r-class
    perform confirm-save
    if valid-operation = 1
        perform save-record display 'Account saved.'
    end-if.

calculate-balances.
    initialize balance-table
    perform varying i from 1 by 1 until i > row-count
        move cache-row(i) to row-buffer
        if r-date >= report-start and <= report-end
            evaluate true
                when r-kind = 'IN' and r-state = 'A'
                    move 1100 to posting-account
                    move r-total to posting-value perform accumulate
                    move 4000 to posting-account
                    compute posting-value = 0 - r-subtotal
                    perform accumulate
                    move 2100 to posting-account
                    compute posting-value = 0 - r-tax
                    perform accumulate
                when r-kind = 'CR' and r-state = 'P'
                    move 1000 to posting-account
                    move r-total to posting-value perform accumulate
                    move 1100 to posting-account
                    compute posting-value = 0 - r-total
                    perform accumulate
                when r-kind = 'JE' and r-state = 'P'
                    perform varying n from 1 by 1 until n > r-count
                        move r-account(n) to posting-account
                        compute posting-value = r-debit(n) - r-credit(n)
                        perform accumulate
                    end-perform
            end-evaluate
        end-if
    end-perform.

accumulate.
    move 'AC' to picked-kind move posting-account to picked-id
    perform find-record
    if found-index = 0
        display 'Ledger references a missing account; stopped.'
        perform abort-input
    end-if
    add posting-value to account-balance(found-index).

show-trial-balance.
    display 'TRIAL BALANCE (debit positive / credit negative)'
    move 0 to amount-value
    perform varying i from 1 by 1 until i > row-count
        move cache-row(i)(1:10) to table-key
        if table-kind = 'AC'
            move cache-row(i) to row-buffer
            move account-balance(i) to amount-display
            display r-id ' ' r-class ' ' function trim(r-name)
                '  ' function trim(amount-display)
            add account-balance(i) to amount-value
        end-if
    end-perform
    move amount-value to amount-display
    display 'Trial balance difference: ' function trim(amount-display).

account-history.
    initialize row-buffer
    move 'AC' to picked-kind move 'Account code: ' to prompt-text
    perform pick-master move picked-id to account-code
    display 'HISTORY ' account-code ' ' function trim(lookup-name)
    perform varying i from 1 by 1 until i > row-count
        move cache-row(i) to row-buffer
        move 0 to posting-value
        evaluate true
            when r-kind = 'IN' and r-state = 'A'
                evaluate account-code
                    when 1100 move r-total to posting-value
                    when 4000 compute posting-value = 0 - r-subtotal
                    when 2100 compute posting-value = 0 - r-tax
                end-evaluate
            when r-kind = 'CR' and r-state = 'P'
                evaluate account-code
                    when 1000 move r-total to posting-value
                    when 1100 compute posting-value = 0 - r-total
                end-evaluate
            when r-kind = 'JE' and r-state = 'P'
                perform varying n from 1 by 1 until n > r-count
                    if r-account(n) = account-code
                        compute posting-value = posting-value +
                            r-debit(n) - r-credit(n)
                    end-if
                end-perform
        end-evaluate
        if posting-value not = 0
            move posting-value to amount-display
            move r-date to date-display
            display date-display ' ' r-kind '-' r-id ' '
                function trim(r-name) ' ' function trim(amount-display)
        end-if
    end-perform.

reports-menu.
    display '1 Profit and loss  2 Balance sheet  3 Trial balance'
    move 'Report choice (0 back): ' to prompt-text perform ask
    move function trim(input-text) to sub-choice
    if sub-choice not = '1' and not = '2' and not = '3'
        exit paragraph end-if
    if sub-choice = '1'
        move 'From date (YYYY-MM-DD): ' to prompt-text
        perform read-date move date-value to report-start
    else move 10101 to report-start end-if
    move 'Through date (YYYY-MM-DD): ' to prompt-text
    perform read-date move date-value to report-end
    if report-end < report-start
        display 'End date must follow start date.' exit paragraph
    end-if
    perform calculate-balances
    evaluate sub-choice
        when '1' perform show-profit-loss
        when '2' perform show-balance-sheet
        when '3' perform show-trial-balance
    end-evaluate.

summarize-balances.
    move 0 to revenue-value expense-value asset-value
        liability-value equity-value
    perform varying i from 1 by 1 until i > row-count
        move cache-row(i)(1:10) to table-key
        if table-kind = 'AC'
            move cache-row(i) to row-buffer
            evaluate r-class
                when 'A' add account-balance(i) to asset-value
                when 'L' subtract account-balance(i) from liability-value
                when 'E' subtract account-balance(i) from equity-value
                when 'R' subtract account-balance(i) from revenue-value
                when 'X' add account-balance(i) to expense-value
            end-evaluate
        end-if
    end-perform
    compute profit-value = revenue-value - expense-value.

show-profit-loss.
    perform summarize-balances
    display 'PROFIT AND LOSS ' report-start ' through ' report-end
    perform varying i from 1 by 1 until i > row-count
        move cache-row(i)(1:10) to table-key
        if table-kind = 'AC'
            move cache-row(i) to row-buffer
            if r-class = 'R' or 'X'
                move account-balance(i) to amount-value
                if r-class = 'R' compute amount-value = 0 - amount-value
                    end-if
                move amount-value to amount-display
                display function trim(r-name) ': '
                    function trim(amount-display)
            end-if
        end-if
    end-perform
    move revenue-value to amount-display
    display 'Revenue: ' function trim(amount-display)
    move expense-value to amount-display
    display 'Expenses: ' function trim(amount-display)
    move profit-value to amount-display
    display 'Net profit: ' function trim(amount-display).

show-balance-sheet.
    perform summarize-balances
    display 'BALANCE SHEET AS OF ' report-end
    move asset-value to amount-display
    display 'Assets: ' function trim(amount-display)
    move liability-value to amount-display
    display 'Liabilities: ' function trim(amount-display)
    move equity-value to amount-display
    display 'Contributed equity: ' function trim(amount-display)
    move profit-value to amount-display
    display 'Accumulated earnings: ' function trim(amount-display)
    compute amount-value = asset-value - liability-value
        - equity-value - profit-value
    move amount-value to amount-display
    display 'Balance sheet difference: ' function trim(amount-display).

dashboard.
    display 'OUTSTANDING APPROVED INVOICES'
    move 0 to total-debits current-index
    perform varying i from 1 by 1 until i > row-count
        move cache-row(i) to row-buffer
        if r-kind = 'IN' and r-state = 'A'
            perform invoice-paid
            compute due-value = r-total - paid-value
            if due-value > 0
                move due-value to amount-display
                display 'INV-' r-id ' ' function trim(r-name)
                    ' Due: ' function trim(amount-display)
                add due-value to total-debits
            end-if
        end-if
        if r-kind = 'JE' and r-state = 'D'
            add 1 to current-index
        end-if
    end-perform
    move total-debits to amount-display
    display 'Total receivables: ' function trim(amount-display)
    display 'Draft journals: ' current-index.

timesheet-menu.
    display '1 New monthly sheet  2 List  3 View  4 Add day'
    display '5 Submit  6 Approve  7 Reject  8 Reset to draft'
    move 'Timesheet choice (0 back): ' to prompt-text perform ask
    move function trim(input-text) to sub-choice
    evaluate sub-choice
        when '1' perform new-timesheet
        when '2' move 'TS' to picked-kind perform list-documents
        when '3' when '4' when '5' when '6' when '7' when '8'
            move 'TS' to picked-kind perform pick-document
            if found-index > 0
                evaluate sub-choice
                    when '3' perform show-timesheet
                    when '4' perform add-timesheet-day
                    when '5' move 'S' to target-state
                        perform transition-timesheet
                    when '6' move 'A' to target-state
                        perform transition-timesheet
                    when '7' move 'R' to target-state
                        perform transition-timesheet
                    when '8' move 'D' to target-state
                        perform transition-timesheet
                end-evaluate
            end-if
        when '0' continue
        when other display 'Choose a listed option.'
    end-evaluate.

new-timesheet.
    move 'TS' to picked-kind perform allocate-id
    initialize row-buffer move 'TS' to r-kind
    move next-id to r-id move 'D' to r-state
    move 'ST' to picked-kind move 'Consultant ID: ' to prompt-text
    perform pick-master move picked-id to r-staff
    move lookup-name to r-name
    move 'CL' to picked-kind move 'Client ID: ' to prompt-text
    perform pick-master move picked-id to r-client
    move 'Optional project ID (0 none): ' to prompt-text
    perform optional-project
    perform until exit
        move 'Any date in the sheet month (YYYY-MM-DD): ' to prompt-text
        perform read-date
        compute r-date = function integer(date-value / 100) * 100 + 1
        move r-staff to selected-staff move r-date to selected-date
        move row-buffer to saved-row
        move 1 to valid-operation
        perform varying i from 1 by 1 until i > row-count
            move cache-row(i) to row-buffer
            if r-kind = 'TS'
                and r-staff = selected-staff
                and r-date = selected-date
                move 0 to valid-operation
            end-if
        end-perform
        move saved-row to row-buffer
        if valid-operation = 0
            display 'Consultant already has a sheet for this month.'
            exit paragraph
        end-if
        exit perform
    end-perform
    perform confirm-save
    if valid-operation = 1
        perform save-record display 'Monthly timesheet created.'
    end-if.

read-clock.
    perform until exit
        perform required-text
        if function length(function trim(input-text)) = 5
            and input-text(3:1) = ':'
            and input-text(1:2) is numeric
            and input-text(4:2) is numeric
            if function numval(input-text(1:2)) < 24
                and function numval(input-text(4:2)) < 60
                compute clock-value =
                    function numval(input-text(1:2)) * 60
                    + function numval(input-text(4:2))
                exit perform
            end-if
        end-if
        display 'Enter time as HH:MM (00:00 for unused shifts).'
    end-perform.

read-shift.
    perform until exit
        move 'Start (HH:MM): ' to prompt-text perform read-clock
        move clock-value to shift-start
        move 'End   (HH:MM): ' to prompt-text perform read-clock
        move clock-value to shift-end
        if shift-start = 0 and shift-end = 0 exit perform end-if
        if shift-end > shift-start and shift-start >= last-end
            add function sum(shift-end, 0 - shift-start)
                to total-minutes
            move shift-end to last-end
            exit perform
        end-if
        display 'Shifts must end after start and must not overlap.'
    end-perform.

add-timesheet-day.
    if r-state not = 'D'
        display 'Reset rejected sheets to draft before editing.'
        display 'Submitted/approved sheets are locked.' exit paragraph
    end-if
    move 'Work date (YYYY-MM-DD): ' to prompt-text perform read-date
    if function integer(date-value / 100)
        not = function integer(r-date / 100)
        display 'Work date must be inside the sheet month.' exit paragraph
    end-if
    move 0 to line-no
    perform varying n from 1 by 1 until n > r-count
        if r-day(n) = date-value move n to line-no end-if
    end-perform
    if line-no = 0
        if r-count >= 31 display 'Sheet is full.' exit paragraph end-if
        add 1 to r-count move r-count to line-no
    end-if
    initialize r-lines(line-no)
    move date-value to r-day(line-no)
    move 'Work description / task reference: ' to prompt-text
    perform required-text move input-text to r-description(line-no)
    move 0 to total-minutes last-end
    display 'Morning shift (00:00 / 00:00 to skip)'
    perform read-shift
    move shift-start to r-start-am(line-no)
    move shift-end to r-end-am(line-no)
    display 'Afternoon shift'
    perform read-shift
    move shift-start to r-start-pm(line-no)
    move shift-end to r-end-pm(line-no)
    display 'Other / overtime shift'
    perform read-shift
    move shift-start to r-start-ot(line-no)
    move shift-end to r-end-ot(line-no)
    if total-minutes = 0
        display 'At least one positive shift is required.' exit paragraph
    end-if
    compute r-quantity(line-no) rounded = total-minutes / 60
    move 0 to total-minutes
    perform varying n from 1 by 1 until n > r-count
        compute total-minutes = total-minutes
            + r-end-am(n) - r-start-am(n)
            + r-end-pm(n) - r-start-pm(n)
            + r-end-ot(n) - r-start-ot(n)
    end-perform
    compute r-total rounded = total-minutes / 60
    perform show-timesheet perform confirm-save
    if valid-operation = 1
        perform save-record display 'Work day saved.'
    end-if.

show-timesheet.
    move r-id to id-display move r-date to date-display
    display 'TIMESHEET TS-' function trim(id-display) ' ' date-display
        ' State: ' r-state ' Consultant: ' function trim(r-name)
    perform varying n from 1 by 1 until n > r-count
        move r-day(n) to date-display
        move r-quantity(n) to quantity-display
        display date-display ' ' function trim(quantity-display)
            ' hours  ' function trim(r-description(n))
    end-perform
    move r-total to amount-display
    display 'Total hours: ' function trim(amount-display).

transition-timesheet.
    move 0 to valid-operation
    evaluate true
        when r-state = 'D' and target-state = 'S' and r-count > 0
            move 1 to valid-operation
        when r-state = 'S' and (target-state = 'A' or 'R')
            move 1 to valid-operation
        when r-state = 'R' and target-state = 'D'
            move 1 to valid-operation
    end-evaluate
    if valid-operation = 0
        display 'Invalid timesheet transition or empty sheet.' exit paragraph
    end-if
    perform confirm-save
    if valid-operation = 1
        move target-state to r-state perform save-record
        display 'Timesheet status updated: ' r-state
    end-if.

export-ledger.
    open output export-file
    if export-status not = '00'
        display 'Cannot open export: ' function trim(export-path)
        display 'Create its directory first.' exit paragraph
    end-if
    move 'date,source,number,account,description,debit,credit'
        to export-row
    perform write-export
    perform varying i from 1 by 1 until i > row-count
        move cache-row(i) to row-buffer
        evaluate true
            when r-kind = 'IN' and r-state = 'A'
                move 1100 to posting-account
                move r-total to posting-value perform export-posting
                move 4000 to posting-account
                compute posting-value = 0 - r-subtotal
                perform export-posting
                move 2100 to posting-account
                compute posting-value = 0 - r-tax
                perform export-posting
            when r-kind = 'CR' and r-state = 'P'
                move 1000 to posting-account
                move r-total to posting-value perform export-posting
                move 1100 to posting-account
                compute posting-value = 0 - r-total
                perform export-posting
            when r-kind = 'JE' and r-state = 'P'
                perform varying n from 1 by 1 until n > r-count
                    move r-account(n) to posting-account
                    compute posting-value = r-debit(n) - r-credit(n)
                    perform export-posting
                end-perform
        end-evaluate
    end-perform
    close export-file
    if export-status not = '00'
        display 'Export close failed: ' export-status exit paragraph
    end-if
    display 'Ledger CSV saved: ' function trim(export-path).

write-export.
    write export-row
    if export-status not = '00'
        display 'Export write failed: ' export-status
        close export-file
        perform abort-input
    end-if.

export-posting.
    if posting-value = 0 exit paragraph end-if
    move 0 to csv-debit csv-credit
    if posting-value > 0
        move posting-value to csv-debit
    else compute amount-value = 0 - posting-value
        move amount-value to csv-credit
    end-if
    *> RFC 4180 quoting: double every embedded quotation mark.
    move spaces to csv-name move 1 to csv-position
    perform varying k from 1 by 1
        until k > function length(function trim(r-name trailing))
        if r-name(k:1) = '"'
            move '"' to csv-name(csv-position:1)
            add 1 to csv-position
        end-if
        move r-name(k:1) to csv-name(csv-position:1)
        add 1 to csv-position
    end-perform
    move spaces to export-row
    move r-date to date-display
    string date-display ',' r-kind ',' r-id ',' posting-account ',"'
        function trim(csv-name trailing) '",'
        function trim(csv-debit) ',' function trim(csv-credit)
        into export-row
    end-string
    perform write-export.
