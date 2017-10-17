function Test-MsrcApiKey { 
    
    <#
    .SYNOPSIS
        For a given given operating system, download relevant patches locally
    .DESCRIPTION
        TODO    
        Long description
    .EXAMPLE
        TODO
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        TODO
        Inputs (if any)
    .OUTPUTS
        TODO
        Output (if any)
    .NOTES
        General notes
    #>

    [cmdletbinding()]
    param (
        $ApiKey
    )

    try { 
        # Search for latest security release. 
        ("{0}: Verifying API key has been set." -f (Get-Date -Format G) ) | Out-String | Write-Verbose
        Get-MsrcSecurityUpdate -WarningAction Stop # > $null # not working | Out-Null
        return $true

    }
    catch {
        # Set API key if it isn't set
        if ( $ApiKey ) { 
            ("{0}: Setting API Key from provided parameter..." -f (Get-Date -Format G) ) | out-string | Write-Verbose 
            Set-MSRCApiKey -ApiKey $ApiKey
            return $true
        }
        elseif ( Test-WindowsCredential -ResourceName "MsrcApiKey") {
        
            ("{0}: Setting API Key from Windows Credential Vault." -f (Get-Date -Format G) ) | out-string | Write-Verbose 
            $PlainTextApiKey = (Get-WindowsCredential -ResourceName "MsrcApiKey").GetNetworkCredential().Password       
            Set-MSRCApiKey -ApiKey $PlainTextApiKey
            return $true

        }
        else {
            try { 
                $ApiKey = Read-Host -AsSecureString -Prompt "Supply an ApiKey" 
                # Note - PowerShell, how to get the value of a secure string? Using some object called "Marshal"
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKey)
                $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            
                ("{0}: Writing API key into credentials vault." -f (Get-Date -Format G) ) | out-string | Write-Verbose
                $Credential = New-Object pscredential "ApiKey", $ApiKey
                Set-WindowsCredential -ResourceName "MsrcApiKey" -Credential $Credential
            
                ("{0}: Setting API Key." -f (Get-Date -Format G) ) | out-string | Write-Verbose        
                Set-MSRCApiKey -ApiKey $UnsecurePassword
                return $true
            }
            catch {
                return $false
            }
        }
    } 
}