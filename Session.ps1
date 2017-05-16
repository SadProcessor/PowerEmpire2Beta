<#
.SYNOPSIS
    Create a new session to an Empire server.
.DESCRIPTION
    Create a new session to an Empire server.
.PARAMETER ComputerName
    IP Address or FQDN of remote Empire server.
.PARAMETER Port
    Port number to use in the connection to the remote Empire server.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER Credential
    Credentials to use for the connection.
.EXAMPLE
    C:\PS> <New-EmpireSession -ComputerName 192.168.1.170 -Credential carlos -NoSSLCheck
    Create a new session to an Empire server without checking the SSL certificate.
.NOTES
    Licensed under BSD 3-Clause license
#><#--------------------------------------------------------------------------------------------<<<--OK#>
function New-EmpireSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $ComputerName,
        
        [Parameter(Mandatory = $true)]
        [Management.Automation.PSCredential]
        [Management.Automation.CredentialAttribute()]
        $Credential = [Management.Automation.PSCredential]::Empty,
        
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Port = 1337,
        
        [Parameter(Mandatory=$false)]
        [switch]
        $NoSSLCheck
    )
    
    begin {
    }
    
    process {
        if ($NoSSLCheck)
        {
            DisableSSLCheck
        }
        $RequestOpts = @{}
        $RequestOpts.Add('Method','Post')
        $RequestOpts.Add('Uri', "https://$($ComputerName):$($Port)/api/admin/login")
        $RequestOpts.Add('ContentType', 'application/json')
        $RequestOpts.Add('Body', (ConvertTo-Json -InputObject @{
            username=$Credential.UserName
            password=$Credential.GetNetworkCredential().Password}))
        $response = Invoke-RestMethod @RequestOpts
        if ($response) {
                $SessionProps = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                $SessionIndex = $Global:EmpireSessions.Count
                $SessionProps.Add('Id', $SessionIndex)
                $SessionProps.Add('Host',$ComputerName)
                $SessionProps.Add('Port', $Port)
                $SessionProps.add('Token',$response.token)
                $sessionobj = New-Object -TypeName psobject -Property $SessionProps
                $sessionobj.pstypenames[0] = 'Empire.Session'

                [void]$Global:EmpireSessions.Add($sessionobj) 

                $sessionobj
        }
    }
    
    end {
    }
}


<#
.SYNOPSIS
    Get all current or specific current sessions against an Empire server.
.DESCRIPTION
    Get all current or specific current sessions against an Empire server.
.PARAMETER Id
    Empire session Id.
.EXAMPLE
    C:\PS> Get-EmpireSession -Id 0
    Get session with Id 0.
.EXAMPLE
    C:\PS> Get-EmpireSession
    Get all current sessions.
.NOTES
    Licensed under BSD 3-Clause license
#><#--------------------------------------------------------------------------------------------<<<--OK#>
function Get-EmpireSession {
    [CmdletBinding()]
    param(

        # Nessus session Id
        [Parameter(Mandatory=$false,
                   ParameterSetName = 'Index',
                   Position=0)]
        [Alias('Index')]
        [int32[]]
        $Id = @()
    )

    Begin{}
    Process {
        if ($Id.Count -gt 0) {
            foreach($i in $Id) {
                foreach($Connection in $Global:EmpireSessions) {
                    if ($Connection.Id -eq $i) {
                        $Connection
                    }
                }
            }
        }
        else {
            # Return all sessions.
            $return_sessions = @()
            foreach($s in $Global:EmpireSessions){$return_sessions += $s}
            $return_sessions
        }
    }
    End{}
}

<#
.SYNOPSIS
    Remove a specific Empire server session from the list of sessions.
.DESCRIPTION
    Remove a specific Empire server session from the list of sessions.
.PARAMETER Id
    Empire session Id.
.EXAMPLE
    C:\PS> <example usage>
    Explanation of what the example does
.NOTES
    Licensed under BSD 3-Clause license
#><#--------------------------------------------------------------------------------------------<<<--OK#>
function Remove-EmpireSession
{
    [CmdletBinding()]
    param(

        # Nessus session Id
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('Index')]
        [int32[]]
        $Id = @()
    )

    Begin{}
    Process {
        # Finding and saving sessions in to a different Array so they can be
        # removed from the main one so as to not generate an modification
        # error for a collection in use.
        $connections = $Global:EmpireSessions
        $toremove = New-Object -TypeName System.Collections.ArrayList
        
        if ($Id.Count -gt 0)
        {
            foreach($i in $Id)
            {
                Write-Verbose -Message "Removing server session $($i)"
                
                foreach($Connection in $connections)
                {
                    if ($Connection.id -eq $i)
                    {
                        [void]$toremove.Add($Connection)
                    }
                }
            }

            foreach($Connection in $toremove)
            {   
                Write-Verbose -message "Removing session from `$Global:EmpireSessions"
                $Global:EmpireSessions.Remove($Connection)
                Write-Verbose -Message "Session $($i) removed."
            }
         }
    }
    End{}
}
