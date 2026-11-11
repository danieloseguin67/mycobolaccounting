param(
    [string]$SqlServer = 'lpc:localhost',
    [string]$Database = 'myaccounting',
    [string]$CompanyName = 'My Demo Consulting Services'
)
# Optional integration check against the real database. All SQL is SELECT.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $PSScriptRoot '.tmp'
[void][IO.Directory]::CreateDirectory($testRoot)
$directory = Join-Path $testRoot ('sql-' + [Guid]::NewGuid().ToString('N'))
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $SqlServer
$builder['Initial Catalog'] = $Database
$builder['Integrated Security'] = $true
$builder['Connect Timeout'] = 10
$connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
try {
    & "$projectRoot\scripts\read-sqlserver.ps1" -SqlServer $SqlServer -Database $Database `
        -CompanyName $CompanyName -OutputDirectory $directory
    $connection.Open()
    $command = $connection.CreateCommand()
    try {
        $command.CommandTimeout = 30
        $command.CommandText = @'
SELECT i.invoice_id FROM dbo.invoicemaster i
JOIN dbo.company c ON c.company_id=i.company_id
WHERE c.company_name=@name AND c.is_active=1 ORDER BY i.invoice_id;
SELECT COUNT(*) AS line_count FROM dbo.invoicedetails d
JOIN dbo.invoicemaster i ON i.invoice_id=d.invoice_id AND i.company_id=d.company_id
JOIN dbo.company c ON c.company_id=i.company_id
WHERE c.company_name=@name AND c.is_active=1;
SELECT i.invoice_id FROM dbo.invoicemaster i
JOIN dbo.company c ON c.company_id=i.company_id
WHERE c.company_name<>@name;
'@
        [void]$command.Parameters.Add('@name', [Data.SqlDbType]::NVarChar, 256)
        $command.Parameters['@name'].Value = $CompanyName
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        $expected = New-Object System.Data.DataSet
        try { [void]$adapter.Fill($expected) } finally { $adapter.Dispose() }
    } finally { $command.Dispose() }

    $actualFiles = @(Get-ChildItem -LiteralPath $directory -Filter 'invoice-*.txt')
    if ($actualFiles.Count -ne $expected.Tables[0].Rows.Count) { throw 'Invoice count mismatch.' }
    foreach ($row in $expected.Tables[0].Rows) {
        $path = Join-Path $directory "invoice-$($row.invoice_id).txt"
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing own invoice $($row.invoice_id)." }
        if ((Get-Content -LiteralPath $path -Encoding UTF8) -notcontains "Invoice ID: $($row.invoice_id)") {
            throw 'Invoice detail does not match its ID.'
        }
    }
    foreach ($row in $expected.Tables[2].Rows) {
        if (Test-Path -LiteralPath (Join-Path $directory "invoice-$($row.invoice_id).txt")) {
            throw "Another division's invoice was exposed: $($row.invoice_id)."
        }
    }
    $lineCount = [int]$expected.Tables[1].Rows[0].line_count
    $expectedLines = if ($lineCount -eq 0) { 2 } else { $lineCount + 2 }
    if (@(Get-Content -LiteralPath (Join-Path $directory 'lines.txt') -Encoding UTF8).Count -ne $expectedLines) {
        throw 'Invoice line count mismatch.'
    }
    # A failed division lookup must fail closed rather than select another company.
    $missingDirectory = Join-Path $directory 'missing'
    $rejected = $false
    try {
        & "$projectRoot\scripts\read-sqlserver.ps1" -SqlServer $SqlServer -Database $Database `
            -CompanyName "Missing division '$([Guid]::NewGuid())" -OutputDirectory $missingDirectory
    } catch {
        if ($_.Exception.Message -notlike 'Expected exactly one active division*') { throw }
        $rejected = $true
    }
    if (-not $rejected -or (Test-Path -LiteralPath $missingDirectory)) {
        throw 'Unknown division did not fail closed.'
    }
    Write-Host 'SQL integration passed: own invoices and lines match SQL; other divisions are excluded; unknown division rejected.'
} finally {
    $connection.Dispose()
    if (Test-Path -LiteralPath $directory) {
        if ((Split-Path -Parent ([IO.Path]::GetFullPath($directory))) -ne [IO.Path]::GetFullPath($testRoot)) {
            throw 'Unexpected test cleanup path.'
        }
        Get-ChildItem -LiteralPath $directory -File | ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Force
        }
        [IO.Directory]::Delete($directory, $false)
    }
}
