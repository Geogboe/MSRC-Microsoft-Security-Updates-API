$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Test-MsrcApiKey" {
    It "Properly returns false if no API key has been set and one is not located in the credentials vault." {
            if ( (Get-Variable MSRCApiKey -ErrorAction SilentlyContinue) -eq $true ) {
                Remove-Item "variable:\MsrcApiKey"
            }
        ( Test-MsrcApiKey -Verbose ) | Should Be $false
    }

    It "Properly returns false if no API key has been set and one is not located in the credentials vault." {
        if ( (Get-Variable MSRCApiKey -ErrorAction SilentlyContinue) -eq $true ) {
            Remove-Item "variable:\MsrcApiKey"
        }
    ( Test-MsrcApiKey ) | Should Be $false
}
}