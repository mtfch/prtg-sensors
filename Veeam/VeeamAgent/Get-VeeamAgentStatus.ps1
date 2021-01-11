<# 
    .SYNOPSIS 
    PRTG Sensor script to monitor Veeam Agent by MTF Data AG (Tobias Meier, tobiasmeier78)
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 
    Version 1.0, 2021-01-08
    Please send ideas, comments and suggestions to https://github.com/mtfch/prtg-sensors
    .LINK 
    https://www.mtf.ch/
    .DESCRIPTION 
    This script returns Xml for a custom PRTG sensor providing the following channels
     - Veeam Agent Status (status of the last backup (24hours ago))
    .NOTES 
    Requirements 
    - Windows Server 2012 R2  
    - NoSpamProxy PowerShell module
    
    Revision History 
    -------------------------------------------------------------------------------- 
    1.0 Initial community release
    .EXAMPLE 
    .\Get-VeeamAgentStatus.ps1
#> 

#Event ID for finished backup job accordnig: https://helpcenter.veeam.com/docs/agentforwindows/userguide/appendix_events.html?ver=40
$VeeamBackupFinishedEventId = 190

$BackupResult = [pscustomobject]@{
    Status = "Error"
    Message = "No backup finished event found - please check backup job"
}

#Read Eventlog
function Get-EventLogEntries {
    $Result = Get-EventLog -LogName 'Veeam Agent' -After (Get-Date).AddDays(-1) | Where {$_.EventID -eq $VeeamBackupFinishedEventId}
    if ( $Result ) {
        
        $BackupResult.Message = $Result.Message
        if ( $Result.EntryType -eq "Information" ) {
            $BackupResult.Status = "Success"
        }
        else {
            $BackupResult.Status = $Result.EntryType
        }
    }
    return $BackupResult
}

#Search for event entry
$BackupResult = Get-EventLogEntries

#XML Output for PRTG, according to https://www.paessler.com/manuals/prtg/exe_script_advanced_sensor
$Output = "<?xml version=""1.0"" encoding=""Windows-1252"" ?>`n"
$Output += "<prtg>`n"
if ( $BackupResult.Status -ne "Error" ) {
    $Output += "  <result>`n"
    $Output += "    <channel>Veeam Agent Status</channel>`n"
    $Output += "    <value>$($BackupResult.Status)</value>`n"
    if ( $BackupResult.Status -eq "Warning" ) { $Output += "    <warning>1</warning>`n" }
    $Output += "  </result>`n"
}
if ( $BackupResult.Status -eq "Error" ) { $Output += "  <error>1</error>`n" }
$Output += "  <text>$($BackupResult.Message)</text>`n"
$Output += '</prtg>'

$Output

