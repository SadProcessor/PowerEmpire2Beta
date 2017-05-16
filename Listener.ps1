<#
.Synopsis
   Get default Empire listener options.
.DESCRIPTION
   Get default Empire listener options.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER Token
    Empire API token to use to execute the action.
.PARAMETER ComputerName
    IP Address or FQDN of remote Empire server.
.PARAMETER Port
    Port number to use in the connection to the remote Empire server.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.EXAMPLE
   C:\PS> Get-EmpireListenerOption -Id 0
   Get listener options for a Empire server.
.NOTES
    Licensed under BSD 3-Clause license
#><#--------------------------------------------------------------------------------------------<<<--FIXED#>
function Get-EmpireListenerOption { 
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ParameterSetName='Session',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Int]
        $Id,
        <#FIX-->>>-#>
        [ValidateSet('http','http_com','http_foreign','http_hop','meterpreter')]
        [Parameter(Mandatory=$true)][String]$Type,
        <#-<<<--FIX#>
        [Parameter(Mandatory=$true,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $Token,

        [Parameter(Mandatory=$true,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $ComputerName,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [int]
        $Port = 1337,
        
        [Parameter(Mandatory=$false)]
        [switch]
        $NoSSLCheck
    )

    Begin {
        if ($NoSSLCheck) {
            DisableSSLCheck
        }
    }
    Process {
        
        switch ($PSCmdlet.ParameterSetName) {
            'session' { $sessionobj = Get-EmpireSession -Id $Id
                if ($sessionobj) {
                   $RequestOpts = @{}
                    $RequestOpts.Add('Method','Get')
                    $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners/options/$Type")<#-<<<--FIX#>
                    $RequestOpts.Add('ContentType', 'application/json')
                    $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
                } else {
                    Write-Error -Message "Session not found."
                    return
                }
            }
            
            'Direct' {
                $RequestOpts = @{}
                $RequestOpts.Add('Method','Get')
                $RequestOpts.Add('Uri', "https://$($ComputerName):$($Port)/api/listeners/options/$Type")<#-<<<--FIX#>
                $RequestOpts.Add('ContentType', 'application/json')
                $RequestOpts.Add('Body', @{'token'= $token})
            }
            Default {}
        }
        
        
        $response = Invoke-RestMethod @RequestOpts
        if ($response) {
            $PropertyNames = $response.ListenerOptions | Get-Member -MemberType NoteProperty | select -ExpandProperty Name
            foreach ($Option in $PropertyNames) {
                $optionObj = New-Object psobject
                Add-Member -InputObject $optionObj -MemberType NoteProperty -Name 'Name' -Value $option
                Add-Member -InputObject $optionObj -MemberType NoteProperty -Name 'Description' -Value $response.ListenerOptions.$($option).Description
                Add-Member -InputObject $optionObj -MemberType NoteProperty -Name 'Required' -Value $response.ListenerOptions.$($option).Required
                Add-Member -InputObject $optionObj -MemberType NoteProperty -Name 'Value' -Value $response.ListenerOptions.$($option).Value
                $optionObj.pstypenames[0] = 'Empire.Listener.Option'
                $optionObj
            }
        } else {
            Write-Warning -Message 'No resposnse received.'
        }
    }
    End{
    }
}

<#
.Synopsis
   Get Empire listerner information and options.
.DESCRIPTION
   Get Empire listerner information and options.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER Token
    Empire API token to use to execute the action.
.PARAMETER ComputerName
    IP Address or FQDN of remote Empire server.
.PARAMETER Port
    Port number to use in the connection to the remote Empire server.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER Name
    Listener name.
.EXAMPLE
   C:\PS> Get-EmpireListener -Id 0
   Get all current listeners on the Empire server.
.NOTES
    Licensed under BSD 3-Clause license
#><#-<<<-----------------------------------------------------------------------?? works but need to check all options are displayed#>
function Get-EmpireListener {
    [CmdletBinding(DefaultParameterSetName='Session')]
    [OutputType([int])]
    Param (
        [Parameter(Mandatory=$true,
                   ParameterSetName='Session',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Int]
        $Id,
        
        [Parameter(Mandatory=$true,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $Token,

        [Parameter(Mandatory=$true,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $ComputerName,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [int]
        $Port = 1337,
        
        [Parameter(Mandatory=$false)]
        [string]
        $Name,
        
        [Parameter(Mandatory=$false)]
        [switch]
        $NoSSLCheck
    )

    Begin {
        if ($NoSSLCheck) {
            DisableSSLCheck
        }
    }
    Process {
        
        switch ($PSCmdlet.ParameterSetName) {
            'session' { $sessionobj = Get-EmpireSession -Id $Id
                if ($sessionobj) {
                   $RequestOpts = @{}
                    $RequestOpts.Add('Method','Get')
                    if ($Name) {
                        Write-Verbose -Message "Getting listerner with name $($name)."
                        $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners/$($name)")
                    } else {
                        Write-Verbose -Message 'Getting all listeners.'
                        $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners")
                    }
                    $RequestOpts.Add('ContentType', 'application/json')
                    $RequestOpts.Add('Body', @{'token'= $sessionobj.token})
                } else {
                    Write-Error -Message "Session not found."
                    return
                }
            }
            
            'Direct' {
                $RequestOpts = @{}
                $RequestOpts.Add('Method','Get')
                if ($name) {
                    $RequestOpts.Add('Uri', "https://$($ComputerName):$($Port)/api/listeners/listeners/$($name)")
                } else {
                    $RequestOpts.Add('Uri', "https://$($ComputerName):$($Port)/api/listeners/listeners")   
                }
                $RequestOpts.Add('ContentType', 'application/json')
                $RequestOpts.Add('Body', @{'token'= $token})
            }
            Default {}
        }
        
        
        $response = Invoke-RestMethod @RequestOpts
        if ($response) {
            $response.listeners
        }

        
    }
    End{
    }
}

<#
.SYNOPSIS
    Stop and remove a specified Empire listener.
.DESCRIPTION
    Stop and remove a specified Empire listener.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER Token
    Empire API token to use to execute the action.
.PARAMETER ComputerName
    IP Address or FQDN of remote Empire server.
.PARAMETER Port
    Port number to use in the connection to the remote Empire server.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.PARAMETER ListenerId
    ID number of the listener to remove.
.EXAMPLE
    C:\PS> Remove-EmpireListener -Id 0 -ListenerId 3
    Explanation of what the example does
.NOTES
    Licensed under BSD 3-Clause license
#><#-<<<-----------------------------------------------------------------------?? BUG ?? Unknown Agent name when agent created on server#>
function Remove-EmpireListener {
    [CmdletBinding(DefaultParameterSetName='Session')]
    [OutputType([int])]
    Param (
        [Parameter(Mandatory=$true,
                   ParameterSetName='Session',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $Id,
        
        [Parameter(Mandatory=$true,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $Token,

        [Parameter(Mandatory=$true,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $ComputerName,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [int]
        $Port = 1337,
        
        [Parameter(Mandatory=$True)]
        [String]
        $ListenerName,
        
        [Parameter(Mandatory=$false)]
        [switch]
        $NoSSLCheck
    )

    Begin {
        if ($NoSSLCheck) {
            DisableSSLCheck
        }
    }
    Process {
        
        switch ($PSCmdlet.ParameterSetName) {
            'session' { $sessionobj = Get-EmpireSession -Id $Id
                if ($sessionobj) {
                   $RequestOpts = @{}
                    $RequestOpts.Add('Method','DELETE')
                    $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners/$($ListenerName)?token=$($sessionobj.token)")
                    $RequestOpts.Add('ContentType', 'application/json')
                    #$RequestOpts.Add('Body', @{'token'= $sessionobj.token})
                } else {
                    Write-Error -Message "Session not found."
                    return
                }
            }
            
            'Direct' {
                $RequestOpts = @{}
                $RequestOpts.Add('Method','DELETE')
                $RequestOpts.Add('Uri', "https://$($ComputerName):$($Port)/api/listeners/$($ListenerName)?token=$($sessionobj.token)")
                $RequestOpts.Add('ContentType', 'application/json')
                $RequestOpts.Add('Body', @{'token'= $token})
            }
            Default {}
        }
        
        
        Invoke-RestMethod @RequestOpts
        
    }
    End{
    }
}

<#
.Synopsis
   Create a new listener on a Empire server.
.DESCRIPTION
   Create a new listener on a Empire server.
.PARAMETER Id
    Empire session Id of the session to use.
.PARAMETER Token
    Empire API token to use to execute the action.
.PARAMETER ComputerName
    IP Address or FQDN of remote Empire server.
.PARAMETER Port
    Port number to use in the connection to the remote Empire server.
.PARAMETER NoSSLCheck
    Do not check if the TLS/SSL certificate of the Empire is valid.
.EXAMPLE
   C:\PS> New-EmpireListener -Id 1 -Name CampaingDevops -ListenerHost 192.168.1.170:443 -CertPath "/root/Desktop/Empire/data/empire.pem"
   Create an HTTPS listener by specifying a PEM certificate to use in the server on port 443.
.EXAMPLE
   C:\PS> New-EmpireListener -Id 1 -Name CampaingAgainstIT -ListenerHost 192.168.1.170 -ListenerPort 80
   Create a listener for a phishing campaing on port 80
.NOTES
    Licensed under BSD 3-Clause license
#><#-<<<----------------------------------------------------------------------------------------FIXED--#>
function New-EmpireListener {
    [CmdletBinding(DefaultParameterSetName='Session')]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ParameterSetName='Session',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Int]
        $Id,
        
        [Parameter(Mandatory=$true,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $Token,

        [Parameter(Mandatory=$true,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $ComputerName,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Direct',
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [int]
        $Port = 1337,
        
        # Listener name.
        [Parameter(Mandatory=$True)]
        [string]
        $Name,

        # Hostname/IP for staging.
        [Parameter(Mandatory=$false)]
        [string]
        $ListenerHost,
        
        # Port for the listener.
        [Parameter(Mandatory=$false)]
        [int]
        $ListenerPort,
        
        # Certificate path for https listeners.
        [Parameter(Mandatory=$false)]
        [string]
        $CertPath,
        
        # Agent delay/reach back interval (in seconds).
        [Parameter(Mandatory=$false)]
        [int]
        $DefaultDelay,
        
        # Jitter in agent reachback interval (0.0-1.0).
        [Parameter(Mandatory=$false)]
        [ValidateRange(0.0,1.0)]
        [float]
        $DefaultJitter,
        
        # Number of missed checkins before exiting
        [Parameter(Mandatory=$false)]
        [int]
        $DefaultLostLimit,
        
        # Default communication profile for the agent.
        [Parameter(Mandatory=$false)]
        [string]
        $DefaultProfile,
        
        # Date for the listener to exit (MM/dd/yyyy).
        [Parameter(Mandatory=$false)]
        [datetime]
        $KillDate,
        
        # Listener target to redirect to for pivot/hop
        [Parameter(Mandatory=$false)]
        [string]
        $RedirectTarget,
        
        # Staging key for initial agent negotiation.
        [Parameter(Mandatory=$false)]
        [string]
        $StagingKey,
        
        # Listener type (native, pivot, hop, foreign, meter).
        [Parameter(Mandatory=$true)]
        [ValidateSet('http','http_com','http_foreign','http_hop','meterpreter')]<#-<<<--FIX#>
        [string]
        $Type,
        
        # Hours for the agent to operate (09:00-17:00).
        [Parameter(Mandatory=$false)]
        [string]
        $WorkingHours,
        
        [Parameter(Mandatory=$false)]
        [switch]
        $NoSSLCheck
    )

    Begin {
        if ($NoSSLCheck) {
            DisableSSLCheck
        }
    }
    Process {
        # create JSON for listener options
        $bodyhash = @{Name=$Name;}
        if ($ListenerHost) {$bodyhash.Add('Host',$ListenerHost)}
        if ($ListenerPort) {$bodyhash.Add('Port',$ListenerPort)}
        if ($CertPath) {$bodyhash.Add('CertPath',$CertPath)}
        if ($DefaultDelay) {$bodyhash.Add('DefaultDelay',$DefaultDelay)}
        if ($DefaultJitter) {$bodyhash.Add('DefaultJitter',$DefaultJitter)}
        if ($DefaultLostLimit) {$bodyhash.Add('DefaultLostLimit',$DefaultLostLimit)}
        if ($DefaultProfile) {$bodyhash.Add('DefaultProfile',$DefaultProfile)}
        if ($KillDate) {$bodyhash.Add('KillDate',$KillDate.ToString("MM/dd/yyyy", [CultureInfo]::InvariantCulture))}
        if ($RedirectTarget) {$bodyhash.Add('RedirectTarget',$RedirectTarget)}
        if ($StagingKey) {$bodyhash.Add('StagingKey',$StagingKey)}
        #if ($Type) {$bodyhash.Add('Type',$Type)}<#-<<<--FIX#>
        if ($WorkingHours) {$bodyhash.Add('WorkingHours',$WorkingHours)}
        
        $Body = ConvertTo-Json -InputObject $bodyhash
        
        switch ($PSCmdlet.ParameterSetName) {
            'session' { $sessionobj = Get-EmpireSession -Id $Id
                if ($sessionobj) {
                   $RequestOpts = @{}
                    $RequestOpts.Add('Method','Post')
                    $RequestOpts.Add('Uri', "https://$($sessionobj.host):$($sessionobj.port)/api/listeners/${type}?token=$($sessionobj.token)")<#-<<<--FIX#>
                    $RequestOpts.Add('ContentType', 'application/json')
                    $RequestOpts.Add('Body', $Body)
                    $RequestOpts
                } else {
                    Write-Error -Message "Session not found."
                    return
                }
            }
            
            'Direct' {
                $RequestOpts = @{}
                $RequestOpts.Add('Method','Post')
                $RequestOpts.Add('Uri', "https://$($ComputerName):$($Port)/api/listeners/${type}?token=$($Token)")<#-<<<--FIX#>
                $RequestOpts.Add('ContentType', 'application/json')
                $RequestOpts.Add('Body', $Body)
            }
            Default {}
        }
        $respose = Invoke-RestMethod @RequestOpts
        if ($response) {
            $respose
        }
    }
    End {
    }
}


