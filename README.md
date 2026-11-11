# MyAccounting in COBOL

A working, single-user terminal implementation of the core workflows in
[MyAccountFunctionalAnalysis.md](MyAccountFunctionalAnalysis.md). The application
and accounting calculations are written in COBOL. PowerShell runs the build
and reads SQL Server using Windows authentication;
Python is used only for automated integration tests.

This is an initial functional prototype, **not full feature parity** with the
Windows application in the guide. The default launcher browses SQL Server data
for **My Demo Consulting Services**. Local accounting entry workflows use
GnuCOBOL indexed files and are available with `-Local`. See the coverage table
below before using it for real business records.

## Start on Windows

Install/start Docker Desktop in Linux-container mode. From this directory:

```powershell
.\scripts\run.cmd
```

The first run builds a Debian/GnuCOBOL 3.1 toolchain image and compiles the
application. Later runs reuse that image and compile the local source. Internet
access is needed for the first image build. The default mode also needs the local
`myaccounting` SQL Server database and Windows permission to read its tables.
The program does not open network ports.

### SQL Server division browser (default)

The launcher connects to `lpc:localhost`, database `myaccounting`, using the current
Windows identity. It resolves the active company named **My Demo Consulting
Services** (currently `company_id=2`) and filters company-owned records by that ID.
Shared projects and inventory items are included only when referenced by the
division's invoices. Invoice lines, journal lines, and timesheet work items are
also checked against their owning division's parent documents.

Choose **3 Invoices** to immediately list the division's invoices. Choose **3 View**
inside that menu and enter the **Invoice ID** shown in the first column, for
example `4` for `INV-20245031`. The view shows its customer, project, amounts,
line items, and receipts. Choose `0` to return to the main menu. **2 Related
records** shows customers, referenced projects/services, consultants, and taxes.
Other main menu choices show receipts, journals with lines, accounts, ledger
entries, and timesheets with daily entries/work items.

SQL browsing is **read-only** and refreshes each time the launcher starts. It
does not create or post SQL transactions. SQL connection/query failures stop
startup with an error. Windows PowerShell queries SQL on the host and passes
UTF-8 display files to the Linux COBOL process in a read-only mount; Docker does
not need SQL credentials or a SQL driver. These per-session files under
`data/sqlserver-<session-id>/` are deleted on normal exit. Forced termination may
leave them behind. Display cells longer than 500 characters are abbreviated.
Account passwords, login tokens, email credentials, and signature images are
not queried.

Override the connection or division explicitly when needed:

```powershell
.\scripts\run.cmd -SqlServer 'lpc:localhost' -Database myaccounting -CompanyName 'My Demo Consulting Services'
```

### Local accounting entry mode

For the original editable prototype, run:

```powershell
.\scripts\run.cmd -Local
```

This mode requires no SQL Server. It stores records in `data/myaccounting.dat`
and uses its own session lock. SQL browsing does not import into that ledger.
The accounting entry instructions, financial reports, CSV export, storage
limits, and backup guidance below describe this local mode.

The CMD launcher starts PowerShell with an execution-policy override for that
process only; it does not change your computer's PowerShell policy. You can also
run the PowerShell script directly when your policy allows local scripts:

```powershell
.\scripts\run.ps1
```

Run the launcher in a terminal (for example, the VS Code integrated terminal).
The launcher automatically disables Docker's TTY allocation when input/output
is redirected, including IDE runners. You can also force this mode with
`.\scripts\run.cmd -NoTty` (add `-Local` for local entry). If startup fails, the launcher preserves the exit
code and Docker/application error instead of throwing a generic exception.

Build or test separately:

```powershell
.\scripts\build.ps1
.\scripts\test.ps1
```

Testing also requires Python 3 on the host. Tests use isolated temporary files;
they do not touch `data/myaccounting.dat`.

To additionally verify the SQL reader against the live database (read-only):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\test_sqlserver.ps1
```

### Native GnuCOBOL alternative

With GnuCOBOL 3.1+ **built with indexed-file support**, a C compiler, and runtime:

```sh
mkdir -p build data exports
cobc -x -free -Wall -Werror -debug -I copybooks -o build/myaccounting src/myaccounting.cob
./build/myaccounting
python3 tests/test_accounting.py --exe ./build/myaccounting
```

The supplied Docker path is verified on Windows. Native Windows compilation is
not verified. Indexed files are tied to the compiler's storage backend; do not
move files between different backends. Use CSV for sharing ledger data.

## First session

Each operation returns to the main menu. Choose its section again for the next
operation. All confirmations require `Y`; other responses cancel. Use main menu
`0` to exit. EOF exits and discards the unfinished operation.

1. Choose **2 Configuration**, then **1 Company/fiscal settings**. Enter your
   company, three-letter currency, fiscal start/end, and tax percentage. Defaults
   are CAD, 13%, and the current calendar year. The rate is an editable example.
2. Choose **2**, then **2 Add client**. Record the assigned client ID.
3. Choose **2**, then **4 Add service**. Enter description, unique service code,
   and price. Record the service ID. Names/notes are limited to 80 characters.
4. Choose **3 Invoices**, then **1 New invoice**. Enter client ID, date, optional
   project/consultant IDs (`0` for none), note, and service lines. Enter quantity
   and unit price explicitly; the service's default price is shown for reference.
5. Save the draft. Choose **3**, then **4 Approve**, and its invoice number.
   Approval creates its financial posting. **6 Replace draft** rebuilds a draft
   with the same number; cancelling leaves the original unchanged.
6. Choose **4 Cash receipts**, then **1 New draft receipt**. Enter the approved
   invoice number, receipt date, amount, and memo. Choose **4**, then **4 Post**
   to finalize it. Partial payments are supported.
7. Choose **5 Journal**, then **1 New draft journal** to record an expense or
   adjustment. Enter at least two lines with equal debit and credit totals.
   Choose **5**, then **4 Post**. Example: debit `5000` $250, credit `1000` $250.
8. Choose **1 Dashboard** to see unpaid invoices, **6 Accounts** for balances
   and history, **7 Reports** for financial statements, or **9 CSV export**.

Dates are entered as **YYYY-MM-DD**. Screen dates display as YYYY/MM/DD.
Amounts accept a dot decimal separator and up to two fractional digits; signs,
commas, and exponent notation are rejected. Blank numeric fields mean zero
where zero is allowed. Transaction dates must lie within the configured fiscal
dates. Report dates can cover any period, including earlier fiscal years.

### Timesheets

Add a consultant in Configuration first. In **8 Timesheets**, create a monthly
sheet for a consultant and client, optionally selecting a project. There can be
only one sheet per consultant per month, even across different clients.

Use **4 Add day** for a work description and morning, afternoon, and overtime
shifts. Enter times as `HH:MM`; `00:00` / `00:00` skips a shift. Shifts must be
chronological, on the same day, and non-overlapping. Entering an existing date
replaces that day's entry after confirmation. Totals use actual minutes, rounded
to two decimal hours for display.

Submit a nonempty draft, then approve or reject it. Rejected sheets must be reset
to draft before editing. Approved sheets are locked. The local operator performs
these actions; there is no separate reviewer identity or external approval.

## Accounting behavior

| Account | Class | Used for |
| --- | --- | --- |
| 1000 | Asset | Bank |
| 1100 | Asset | Accounts receivable control |
| 2100 | Liability | Tax payable |
| 3000 | Equity | Owner contributions/opening balance offsets |
| 4000 | Revenue | Service revenue |
| 5000 | Expense | Operating expenses |

Additional accounts can be created as Asset, Liability, Equity, Revenue, or
Expense. The system accounts above have fixed mappings in this version.
Enter opening balances with a balanced journal rather than editing accounts.
Direct journals to `1100` are blocked to preserve invoice/receivable agreement.

- Invoice lines round quantity x price to cents. The invoice sums these lines,
  calculates tax once on the subtotal, and rounds tax to cents.
- Drafts have no financial effect. Approval debits receivables and credits
  revenue/tax. Receipts debit bank and credit receivables when posted.
- Receipts must target an approved invoice; their client is inherited from it.
  Amounts are checked again when posting, so competing drafts cannot overpay.
  Receipts cannot predate their invoice.
- Posted receipts and journals cannot be edited, deleted, or posted twice.
  Correct journal mistakes using a separate balanced reversing entry.
- An unpaid invoice can be voided; void invoices are excluded from all ledger
  reports, including historical ones. A paid invoice cannot be voided. Dated
  reversal/credit-note workflows are not implemented.
- Trial balances show debit balances as positive and credit balances as negative.
  Profit and loss shows revenue and expenses with their normal signs. The balance
  sheet includes cumulative earnings through its as-of date without needing a
  year-end closing entry. This version does not implement fiscal closing.
- One currency and one tax rate per invoice are supported. Do not change currency
  after entering records: there is no exchange conversion or historical currency
  separation. Tax percentage changes apply only to newly entered/replaced drafts.
- Invoices, receipts, journals, and timesheets have separate automatic number
  sequences starting at 1. Records are retained, so numbers are not reused.

## Coverage against the functional guide

| Guide area | Implemented | Remaining |
| --- | --- | --- |
| Dashboard | Unpaid invoices and draft journal count | Monthly chart, personal tasks |
| Configuration | Company, fiscal dates, currency, tax, clients, services, projects, consultants | Full contact forms, tax components, payment terms, geography, email, users |
| Invoices | Multiple service lines, notes, rounded totals, draft replacement, approval, void | PDF/email, attachments, per-client tax/accounts, prefix settings |
| Cash receipts | Invoice-linked drafts, preview, partial payments, posting | Unallocated payments, selectable bank, draft editing, reversals |
| Journal | Balanced drafts, replacement, preview, immutable posting | Draft deletion, audit identities |
| Chart of accounts | Seed accounts, additional accounts, live balances, posted history | Rename/delete, account mapping configuration |
| Reports | Date-filtered profit and loss, balance sheet, trial balance | PDF, XLSX, drill-down UI |
| Timesheets | Monthly uniqueness, shifts, descriptions, hours, approval lifecycle | Separate work-item lists, TPG import, PDF/email, automatic invoicing |
| Exports/imports | Accountant CSV of all current posted ledger lines | Sage/pipe imports, OCR, XLSX, CSV import |
| Security/storage | Local files, session lock, input validation; read-only SQL Server division browser using Windows authentication | SQL Server writes, application roles, encryption, user audit trail |

The broader guide's conflicting invoice status lists are resolved to **D**raft,
**A**pproved, and **V**oid (section 7.3). Paid balance is derived from posted
receipts. Receipt/journal states are **D**raft and **P**osted. Timesheet states
are **D**raft, **S**ubmitted, **A**pproved, and **R**ejected.

## Data, backup, and limits

`data/myaccounting.dat` is a GnuCOBOL indexed file. Each business document and its
posting data are stored together in one fixed-size record. Reports reconstruct
balances from those records. There is no separate ledger update that could be
skipped after saving a document. File writes are checked and flushed with COBOL
`COMMIT`; the storage engine is not a transactional SQL database, and recovery
from power loss/corruption is not guaranteed.

An atomic `.lock` directory prevents simultaneous sessions, including separate
containers. If the program is forcibly terminated, that directory may remain.
Only after confirming that no accounting session/container is still running,
remove the empty `data/myaccounting.dat.lock` directory to resume. Normal exits,
EOF, and handled file errors release it. Keep data on a local filesystem.

Close the program before copying **all files in `data/`** for backup. Preserve
backups before changing record layouts; schema migrations are not implemented.
Files and CSV exports are unencrypted and inherit your filesystem permissions.
CSV is a sharing format, not a restorable application backup.

Limits: 2,000 total records (including configuration and master records), 20 lines
per invoice/journal, 31 daily entries per timesheet, 80 characters per text field,
quantity up to 99,999.99, and entered prices/payments/journal lines up to
99,999,999.99. Computed document totals must fit 9,999,999,999.99; oversized invoices
are rejected. This prototype has not been validated for production accounting,
tax filings, hostile input/data-file tampering, or disaster recovery.

Override paths when launching the executable directly with `MYACCOUNT_FILE` and
`MYACCOUNT_EXPORT`; parent directories must already exist. Default export:
`exports/accountant.csv`. CSV contains date, source, document number, account,
description, debit, and credit. Export replaces the previous CSV.

## Source layout

```text
src/myaccounting.cob       Terminal workflows, validation, persistence, reports
copybooks/record.cpy       Schema 1 record shared by file/cache operations
scripts/build.ps1          Build in Docker
scripts/run.ps1            Compile and launch interactively
scripts/run.cmd            Windows launcher for restricted PowerShell policies
scripts/read-sqlserver.ps1 Read division business records into display files
scripts/test.ps1           Build and run integration tests
tests/test_accounting.py   Real-process accounting and persistence checks
tests/test_sqlserver.ps1   Optional read-only live division-isolation checks
Dockerfile                Isolated compiler/runtime image
```
