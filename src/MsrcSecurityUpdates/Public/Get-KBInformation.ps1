function Get-PatchInformation {
    <#
    .SYNOPSIS
        Get download links for KB articles.
    .DESCRIPTION
        For a given kb article return applicable products and download links. 
    .EXAMPLE
        PS C:\> ParseUpdateCatalog
        Explanation of what the example does - TODO
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        This code modified and based on http://stealthpuppy.com/powershell-download-import-updates-mdt/
    #>

    [cmdletbinding()]
    Param(
        $KbArticleID,
        $UpdateCatalogSearchPath = ("https://www.catalog.update.microsoft.com/Search.aspx?q=KB" + ($KbArticleID -split "KB")[1] ),
        # Filter down to a specific product
        $ProductName
    )

    ("{0}: Querying catalog.update.microsoft.com for KB article: {1} using search string: {2}" -f 
        (Get-Date -Format G), 
        $KbArticleID,
        $UpdateCatalogSearchPath 
    ) | Out-String | Write-Verbose

    # This search result table will contain a table with multiple rows of results ( if it's valid) so we'll need to filter down by product
    # Note - they use an interesting formatting in the DOC, see examples
    # - 4ca4dbaa-fae4-4a7c-9760-8e202d10128f_R0
    # - id="4ca4dbaa-fae4-4a7c-9760-8e202d10128f_C0_R0"
    # - 8452bac0-bf53-4fbd-915d-499de08c338b_R1
    # if it's a <tr> The first part is the GUID, then there's the ROW
    # if it's a <td> the first part of the ID is update guid and then it's the column number and then row. 
    # Row 0 is the headerRow
    # colume 1 is the product, colume 0 is the title. There are more but those are the interesting ones
    $MSUpdateCatalogSearchResultDoc = Invoke-WebRequest -Uri $UpdateCatalogSearchPath
    $SearchResultsTable = $MSUpdateCatalogSearchResultDoc.ParsedHtml.getElementById('ctl00_catalogBody_updateMatches')
    $TableData = $SearchResultsTable.getElementsByTagName('td') | Where-Object { $_.id -like "*_C*_R*"} | ForEach-Object {
        # Build a table of objects 
        $RowID = ($_.id -split "_")
        $Result = New-Object pscustomobject -Property @{
            GUID         = $RowID[0]
            ColumnNumber = $RowID[1]
            RowNumber    = $RowID[2]
            Content      = $_.InnerText
        }
        # Skip the header row
        if ( $Result.RowNumber -ne "R0" ) {
            return $Result
        }
    }
    $KbObject = New-Object pscustomobject -Property @{
        ArticleID     = $KbArticleID
        SearchString  = $UpdateCatalogSearchPath
        KbInformation = @()
    }

    # group each result in the table by the GUID and the loop from those groups and set values based on the columns
    foreach ( $Result in ($TableData | Group-Object -Property GUID)) {
        if (($Result.Group.Where( {$_.ColumnNumber -eq "C2"})).Content -match $ProductName -AND 
            ($Result.Group.Where( {$_.ColumnNumber -eq "C1"})).Content -notmatch "without $KbArticleID"
        ) {
            $KbInfoObject = New-Object pscustomobject -Property @{
                GUID               = $Result.Name
                ApplicableProducts = ($Result.Group.Where( {$_.ColumnNumber -eq "C2"})).Content
                Description        = ($Result.Group.Where( {$_.ColumnNumber -eq "C1"})).Content
                Size               = ($Result.Group.Where( {$_.ColumnNumber -eq "C6"})).Content
                PublicationDate    = ($Result.Group.Where( {$_.ColumnNumber -eq "C4"})).Content
                Classification     = ($Result.Group.Where( {$_.ColumnNumber -eq "C3"})).Content
                DownloadUrls       = @()
            }

            $KbObject.KbInformation += $KbInfoObject
        }
    }

    # Get the download links for each result
    foreach ($KbInfoObject in $KbObject.KbInformation) {

        ("{0}: Getting download links for KB: {1} product: {2} with description: {3}" -f (Get-Date -Format G), 
            $KbObject.ArticleID, 
            $KbInfoObject.ApplicableProducts,
            $KbInfoObject.Description 
        ) | Out-String | Write-Verbose

        $Post = @{ size = 0; updateID = $KbInfoObject.GUID; uidInfo = $KbInfoObject.GUID } | ConvertTo-Json -Compress
        $PostBody = @{ updateIDs = "[$Post]" } 
        $KbInfoObject.DownloadUrls += Invoke-WebRequest -Uri 'http://www.catalog.update.microsoft.com/DownloadDialog.aspx' -Method Post -Body $postBody |
            Select-Object -ExpandProperty Content |
            Select-String -AllMatches -Pattern "(http[s]?\://download\.windowsupdate\.com\/[^\'\""]*)" | 
            ForEach-Object { $_.matches.value }
      
    }

    return $KbObject
}