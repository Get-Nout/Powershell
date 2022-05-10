Function ConvertCSVTo-XSLS{
#Version: 1.1
#Changes: 1.1 Now with error logs
#Purpose: Convert one or multiple CSV files into one XSLX File

    Param(
        [Parameter(Mandatory=$true)][String]$CSV = "C:\temp\input.csv",
        [String]$ExportFile = ($CSV.replace(".csv",".xlsx")),
        [String]$Delimiter = $Excel.Application.International(5),
        [Boolean]$AddPage = $False,
        [Boolean]$Overwrite = $False
        )

    Try{
        # Create a new Excel Workbook with one empty sheet
            Write-Host "Creating new Excel Sheet..."
            $Excel = New-Object -ComObject excel.application -ErrorAction Stop
            $Workbook = $Excel.Workbooks.Add(1)
            $Worksheet = $Workbook.worksheets.Item(1)

    } Catch{
        Throw "ERROR001 - Failed to use Excel functions, is it installed?" 
    }

    Try{
        # Build the Querry to convert it to XLSX
            Write-Host "Building Conversion Querry..."
            $TxtConnector = ("TEXT;" + $CSV)
            $Connector = $worksheet.QueryTables.add($TxtConnector,$worksheet.Range("A1"))
            $Query = $worksheet.QueryTables.item($Connector.name)   
    } Catch{
        Throw "ERROR002 - Failed to build Querry, is the CSV file ok?" 
    }

    Try{
        # Set the delimiter (, or ;) according to your regional settings
            Write-Host "Setting Delimiter to '$Delimiter'"
            $Query.TextFileOtherDelimiter = $Delimiter        
    } Catch{
        Throw "ERROR003 - Something strange happend to the delimiter." 
    }

    Try{
        # Set the format to delimited and text for every column
        # A trick to create an array of 2s is used with the preceding comma
            $Query.TextFileParseType  = 1
            $Query.TextFileColumnDataTypes = ,2 * $Worksheet.Cells.Columns.Count
            $Query.AdjustColumnWidth = 1
    } Catch{
        Throw "ERROR004 - Something happend while converting setting the format" 
    }

    try{
        # Execute & delete the import query
            Write-Host "Converting... "
            $Query.Refresh() | out-null

            Write-Host "Cleaning up Querry..."
            $Query.Delete() 
    } Catch{
        Throw "ERROR005 - Something strange happend while converting" 
    }

    Try{
        # Overwrite the file?
        if($Overwrite){
            $Excel.DisplayAlerts = $false;
        }else{
            $Excel.DisplayAlerts = $true;
        }
    }Catch{
         Throw "ERROR006 - Failed to Set displayalerts." 
    }
    Try{
        # Save & close the Workbook as XLSX. Change the output extension for Excel 2003
        Write-Host "Saving ..."
        $Workbook.SaveAs($ExportFile,51)

        Write-Host "Closing Excel..."
        $Excel.Quit()
    } Catch{
        Throw "ERROR007 - Something went wrong trying to save" 
    }
}