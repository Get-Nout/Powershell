function Invoke-SqlSelect
    #Created by 'Rubanov'
{
    [CmdletBinding()]
    Param
    ( 
        [ValidateNotNullOrEmpty()] 
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)] 
        [string] $SqlServer,
        [Parameter(ValueFromPipeline=$True,Mandatory=$False)] 
        [string] $Database = "master",
        [ValidateNotNullOrEmpty()] 
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)] 
        [string] $SqlStatement
    )
    $ErrorActionPreference = "Stop"

    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $sqlConnection.ConnectionString = "Server=$SqlServer;Database=$Database;Integrated Security=True"

    $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
    $sqlCmd.CommandText = $SqlStatement
    $sqlCmd.Connection = $sqlConnection

    $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $sqlAdapter.SelectCommand = $sqlCmd
    $dataTable = New-Object System.Data.DataTable
    try
    {
        $sqlConnection.Open()
        $sqlOutput = $sqlAdapter.Fill($dataTable)
        Write-Output -Verbose $sqlOutput
        $sqlConnection.Close()
        $sqlConnection.Dispose()
        return $dataTable
    }
    catch
    {
        Write-Output -Verbose "Error executing SQL on database [$Database] on server [$SqlServer]. Statement: `r`n$SqlStatement"
        return $null
    }
}



