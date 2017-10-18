function Test-MsrcApiKey { 
    
    <#
    .SYNOPSIS
        Check if the MSRC api key has been set. 
    .DESCRIPTION
        Check if the MSRC api key has been set and if it hasn't, check the Windows credential vault to see if it's been previously stored. 
    .EXAMPLE
        PS C:\> . .\Test-MsrcApiKey.ps1;Test-MsrcApiKey -Verbose
        VERBOSE: 10/18/2017 8:27:02 AM: No MSRC API key variable loaded in environment.
        VERBOSE: 10/18/2017 8:27:02 AM: Setting MSRC key from Windows credential vault
        VERBOSE: GET https://api.msrc.microsoft.com/Updates?api-version=2016-01-01 with 0-byte payload
        VERBOSE: received 6040-byte response of content type application/json; odata.metadata=minimal; odata.streaming=true
        True
    .INPUTS
        None
    .OUTPUTS
        [bolean]
    .NOTES
        Todo - validate with a request that the api key supplied actually works
    #>

    [cmdletbinding()]
    param (
        # The name of the env variable storing the MSRC api key
        [string]
        $MsrcApiKeyEnvVariableName = "MSRCApiKey"
    )

    $MsrcApiKeyVariable = Get-Variable -Name $MsrcApiKeyEnvVariableName -ea SilentlyContinue -Verbose
    if ([string]::IsNullOrEmpty($MsrcApiKeyVariable)) {
        ("{0}: No MSRC API key variable loaded in environment." -f (Get-Date -Format G) ) | out-string | Write-Verbose
        # Check vault for MSRC ApiKey
        if ( (Test-WindowsCredential -ResourceName "MsrcApikey") -eq $false) {
            ("{0}: No MSRC API key found in Windows credential vault" -f (Get-Date -Format G) ) | out-string | Write-Verbose            
            return $false
        }
        else {
            ("{0}: Setting MSRC key from Windows credential vault" -f (Get-Date -Format G) ) | out-string | Write-Verbose                        
            # Load in the api key
            $MsrcApiKey = (Get-WindowsCredential -ResourceName "MsrcApikey").GetNetworkCredential().Password
            # Test the ApiKey
            if ( (Invoke-WebRequest -Uri "https://api.msrc.microsoft.com/Updates?api-version=2016-01-01" -UseBasicParsing -Headers @{
                        "api-key" = $MsrcApiKey
                    }).StatusCode -eq 200) {
                Set-MsrcApiKey -ApiKey $MsrcApiKey                        
                return $true    
            }
            else {
                ("{0}: MSRC key found in Windows credential vault is invalid." -f (Get-Date -Format G) ) | 
                    out-string | Write-Error  
                return $false                      
            }
        }
    }
}