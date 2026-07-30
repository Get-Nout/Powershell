function Convert-CSV-To-Excel {
param (
        [String]$Csv, #Location of the source file
        [String]$Xlsx, #Desired location of output  
        [String]$Delimiter = ";" #Specify the delimiter used in the file
     )

# Create a new Excel workbook with one empty sheet
    $Excel = New-Object -ComObject excel.application 
    $Workbook = $Excel.Workbooks.Add(1)
    $Worksheet = $Workbook.worksheets.Item(1)

# Build the QueryTables.Add command and reformat the data
    $TxtConnector = ("TEXT;" + $Csv)
    $Connector = $Worksheet.QueryTables.add($TxtConnector,$Worksheet.Range("A1"))
    $Query = $Worksheet.QueryTables.item($Connector.name)
    $Query.TextFileOtherDelimiter = $Delimiter
    $Query.TextFileParseType  = 1
    $Query.TextFileColumnDataTypes = ,1 * $Worksheet.Cells.Columns.Count
    $Query.AdjustColumnWidth = 1

# Execute & delete the import query
    $Query.Refresh()
    $Query.Delete()

# Save & close the Workbook as XLSX.
    $Workbook.SaveAs($Xlsx,51)
    $Excel.Quit()

}