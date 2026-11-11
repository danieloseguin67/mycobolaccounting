param(
    [string]$SqlServer = 'lpc:localhost',
    [string]$Database = 'myaccounting',
    [string]$CompanyName = 'My Demo Consulting Services',
    [Parameter(Mandatory = $true)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'

# SQL runs on Windows so the signed-in user's Windows credentials stay on
# the host. The Linux COBOL process receives a read-only display snapshot.
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $SqlServer
$builder['Initial Catalog'] = $Database
$builder['Integrated Security'] = $true
$builder['Encrypt'] = $false
$builder['Connect Timeout'] = 10
$builder['Application Name'] = 'MyAccounting COBOL reader'
$connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
$transaction = $null
function Read-Table([string]$Query, [int]$CompanyId = 0) {
    $command = $connection.CreateCommand()
    try {
        $command.Transaction = $transaction
        $command.CommandTimeout = 30
        $command.CommandText = $Query
        [void]$command.Parameters.Add('@company', [System.Data.SqlDbType]::Int)
        $command.Parameters['@company'].Value = $CompanyId
        [void]$command.Parameters.Add('@name', [System.Data.SqlDbType]::NVarChar, 256)
        $command.Parameters['@name'].Value = $CompanyName
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        try {
            $table = New-Object System.Data.DataTable
            [void]$adapter.Fill($table)
            return ,$table
        } finally { $adapter.Dispose() }
    } finally { $command.Dispose() }
}
function Display-Value($Value) {
    if ($null -eq $Value -or $Value -is [DBNull]) { return '' }
    if ($Value -is [DateTime]) { return $Value.ToString('yyyy-MM-dd') }
    if ($Value -is [decimal]) { return $Value.ToString('0.00', [Globalization.CultureInfo]::InvariantCulture) }
    # Database text is display data, including when it contains terminal controls.
    $valueText = ([string]$Value -replace '[\x00-\x1f\x7f-\x9f]', ' ')
    if ($valueText.Length -gt 500) { return $valueText.Substring(0, 497) + '...' }
    return $valueText
}
function Format-TableText($Table, [string]$Title) {
    $Title
    if ($Table.Rows.Count -eq 0) { 'No records for this division.'; return }
    ($Table.Columns | ForEach-Object { $_.ColumnName }) -join ' | '
    foreach ($row in $Table.Rows) {
        ($Table.Columns | ForEach-Object { Display-Value $row[$_.ColumnName] }) -join ' | '
    }
}
function Write-View([string]$Name, [string[]]$Lines) {
    [IO.File]::WriteAllLines((Join-Path $OutputDirectory $Name), $Lines,
        (New-Object Text.UTF8Encoding $false))
}

try {
    $connection.Open()
    $transaction = $connection.BeginTransaction([Data.IsolationLevel]::RepeatableRead)
    $company = Read-Table 'SELECT company_id,company_name,address1,address2,city,province,postal,country FROM dbo.company WHERE company_name=@name AND is_active=1'
    if ($company.Rows.Count -ne 1) {
        throw "Expected exactly one active division named '$CompanyName'; found $($company.Rows.Count)."
    }
    $companyId = [int]$company.Rows[0]['company_id']
    $queries = [ordered]@{
        customers = 'SELECT customer_id AS [Customer ID],company AS Customer,contact AS Contact,email AS Email,city AS City,currency AS Currency,tax_code AS [Tax code] FROM dbo.customers WHERE company_id=@company ORDER BY customer_id'
        invoices = 'SELECT i.invoice_id AS [Invoice ID],i.invoice_number AS Invoice,i.invoice_date AS Date,c.company AS Customer,p.project_code AS Project,i.total_amount AS Total,i.tax_amount AS Tax,i.status AS Status,c.currency AS Currency,i.comments AS Comments FROM dbo.invoicemaster i LEFT JOIN dbo.customers c ON c.customer_id=i.customer_id AND c.company_id=i.company_id LEFT JOIN dbo.projects p ON p.project_id=i.project_id WHERE i.company_id=@company ORDER BY i.invoice_date DESC,i.invoice_id DESC'
        lines = 'SELECT d.invoice_id AS [Invoice ID],d.detail_id AS [Line ID],d.item_code AS Item,d.description AS Description,d.quantity AS Quantity,d.unit_price AS [Unit price],d.amount AS Amount,d.line_type AS Type FROM dbo.invoicedetails d JOIN dbo.invoicemaster i ON i.invoice_id=d.invoice_id AND i.company_id=d.company_id WHERE i.company_id=@company ORDER BY d.invoice_id,d.detail_id'
        receipts = 'SELECT r.receipt_id AS [Receipt ID],r.receipt_number AS Receipt,r.invoice_id AS [Invoice ID],i.invoice_number AS Invoice,r.receipt_date AS Date,c.company AS Customer,r.amount AS Amount,r.status AS Status,r.bank_account AS Bank,r.memo AS Memo FROM dbo.cashreceipts r LEFT JOIN dbo.invoicemaster i ON i.invoice_id=r.invoice_id AND i.company_id=r.company_id LEFT JOIN dbo.customers c ON c.customer_id=r.customer_id AND c.company_id=r.company_id WHERE r.company_id=@company ORDER BY r.receipt_date,r.receipt_id'
        projects = 'SELECT p.project_id AS [Project ID],p.project_code AS Project,p.start_date AS [Start date] FROM dbo.projects p WHERE EXISTS (SELECT 1 FROM dbo.invoicemaster i WHERE i.company_id=@company AND i.project_id=p.project_id) ORDER BY p.project_id'
        consultants = 'SELECT salesman_id AS [Consultant ID],salesman_name AS Consultant FROM dbo.salesmen WHERE company_id=@company ORDER BY salesman_id'
        services = 'SELECT v.item_code AS Item,v.description AS Description,v.unit AS Unit,v.price AS Price,v.account AS Account FROM dbo.inventory v WHERE EXISTS (SELECT 1 FROM dbo.invoicedetails d JOIN dbo.invoicemaster i ON i.invoice_id=d.invoice_id AND i.company_id=d.company_id WHERE i.company_id=@company AND d.item_code=v.item_code) ORDER BY v.item_code'
        accounts = 'SELECT account_number AS Account,account_name AS Name,opening_balance AS Opening,balance AS Balance,balance_type AS Type FROM dbo.glmaster WHERE company_id=@company ORDER BY account_number'
        ledger = 'SELECT trans_date AS Date,account_number AS Account,source_number AS Source,trans_no AS [Transaction],description AS Description,debits AS Debits,credits AS Credits FROM dbo.gldetails WHERE company_id=@company ORDER BY trans_date,detail_id'
        journals = 'SELECT entry_id AS [Entry ID],entry_number AS Entry,entry_date AS Date,description AS Description,reference AS Reference,status AS Status FROM dbo.journalmaster WHERE company_id=@company ORDER BY entry_date,entry_id'
        journal_lines = 'SELECT d.entry_id AS [Entry ID],d.account_number AS Account,d.description AS Description,d.debit AS Debit,d.credit AS Credit FROM dbo.journaldetails d JOIN dbo.journalmaster j ON j.entry_id=d.entry_id AND j.company_id=d.company_id WHERE j.company_id=@company ORDER BY d.entry_id,d.line_id'
        timesheets = 'SELECT t.ts_id AS [Timesheet ID],s.salesman_name AS Consultant,t.ts_year AS Year,t.ts_month AS Month,t.status AS Status,c.company AS Customer,t.client AS [Client label],t.project AS Project,t.notes AS Notes FROM dbo.timesheetmaster t LEFT JOIN dbo.salesmen s ON s.salesman_id=t.salesman_id AND s.company_id=t.company_id LEFT JOIN dbo.customers c ON c.customer_id=t.customer_id AND c.company_id=t.company_id WHERE t.company_id=@company ORDER BY t.ts_year,t.ts_month,t.ts_id'
        days = 'SELECT d.ts_id AS [Timesheet ID],d.line_id AS [Day ID],d.work_date AS Date,d.am_start AS [AM start],d.am_end AS [AM end],d.pm_start AS [PM start],d.pm_end AS [PM end],d.other_start AS [Other start],d.other_end AS [Other end],d.total_hours AS Hours FROM dbo.timesheetdetail d JOIN dbo.timesheetmaster t ON t.ts_id=d.ts_id AND t.company_id=d.company_id WHERE t.company_id=@company ORDER BY d.ts_id,d.work_date'
        work = 'SELECT d.ts_id AS [Timesheet ID],w.line_id AS [Day ID],w.description AS Description,w.devops_work_item AS Reference,w.hours AS Hours FROM dbo.timesheetworkitem w JOIN dbo.timesheetdetail d ON d.line_id=w.line_id AND d.company_id=w.company_id JOIN dbo.timesheetmaster t ON t.ts_id=d.ts_id AND t.company_id=d.company_id WHERE t.company_id=@company ORDER BY d.ts_id,w.line_id,w.sort_order,w.item_id'
        taxes = 'SELECT tax_code AS Code,detail_name AS Component,tax_rate AS [Rate percent],tax_account AS Account FROM dbo.taxcodedetail WHERE company_id=@company ORDER BY tax_code,seq'
    }
    $tables = @{}
    foreach ($name in $queries.Keys) { $tables[$name] = Read-Table $queries[$name] $companyId }
    $transaction.Commit()
    $transaction.Dispose()
    $transaction = $null

    [void][IO.Directory]::CreateDirectory($OutputDirectory)
    Write-View 'company.txt' @((Display-Value $company.Rows[0]['company_name']))
    $overview = @("SQL Server: $SqlServer / $Database", "Division: $(Display-Value $company.Rows[0]['company_name']) (company_id=$companyId)",
        "Loaded: $([DateTimeOffset]::Now.ToString('yyyy-MM-dd HH:mm:ss zzz'))", 'Read-only records. Restart the application to refresh.', '')
    foreach ($name in $queries.Keys) { $overview += "${name}: $($tables[$name].Rows.Count)" }
    Write-View 'overview.txt' $overview
    foreach ($name in $queries.Keys) {
        Write-View "$name.txt" @(Format-TableText $tables[$name] $name.ToUpperInvariant())
    }
    # Only invoices owned by the resolved company get a detail file. IDs entered
    # in COBOL cannot retrieve another company's invoice or traverse a path.
    foreach ($invoice in $tables['invoices'].Rows) {
        $id = [int]$invoice['Invoice ID']
        $view = @('INVOICE')
        foreach ($column in $tables['invoices'].Columns) {
            $view += "$($column.ColumnName): $(Display-Value $invoice[$column.ColumnName])"
        }
        foreach ($section in @('lines', 'receipts')) {
            $related = $tables[$section].Clone()
            foreach ($row in $tables[$section].Rows) {
                if ($row['Invoice ID'] -eq $id) { $related.ImportRow($row) }
            }
            $view += ''; $view += @(Format-TableText $related $section.ToUpperInvariant())
        }
        Write-View "invoice-$id.txt" $view
    }
    Write-Host "Connected to $Database / $($company.Rows[0]['company_name']) (company_id=$companyId)."
    Write-Host "Loaded $($tables['invoices'].Rows.Count) invoices, $($tables['lines'].Rows.Count) invoice lines, $($tables['customers'].Rows.Count) customers."
} finally {
    if ($null -ne $transaction) { $transaction.Dispose() }
    $connection.Dispose()
}
