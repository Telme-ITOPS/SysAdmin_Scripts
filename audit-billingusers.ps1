Import-module RemoteDesktop
$td = Get-Date
$fd = get-date -Format "dd-MMM-yyyy"
$fname = "billingusers-$fd.csv"
$body = "Billing users audited on $td"
If(Test-Path C:\Reports\$fname) {Remove-Item C:\Reports\$fname}
$rusers = Get-RDRemoteApp -DisplayName Billing -ConnectionBroker CorpTerminal2.telmetrics.corp | select -ExpandProperty UserGroups 
$rusers += (invoke-command {net localgroup administrators | where {$_ -AND $_ -notmatch "command completed successfully"} | select -skip 4} -computer corpterminal2)
$busers = @{}
foreach($ruser in $rusers){
    If([Regex]::Matches($ruser, "\\").Count){
        $oname = ($ruser -split "\\")[-1]
        $obj = Get-ADObject -Filter * -Properties samaccountname | ? {$_.samaccountname -eq $oname}
        If($obj.ObjectClass -eq 'group'){
            $gmem = Get-ADGroupMember $obj -Recursive
            foreach($mem in $gmem){
                If(!($busers.ContainsKey($mem.name))){
                    If(Test-Path \\corpterminal2\users\$($mem.samaccountname)\appdata\Roaming\Telmetrics\Logs\billing\log.log){
                        $busers.Add($mem.name, (Get-Item \\corpterminal2\users\$($mem.samaccountname)\appdata\Roaming\Telmetrics\Logs\billing\log.log | select -ExpandProperty LastWriteTime))
                    }
                    Else{
                        $busers.Add($mem.name,"Never")
                    }
                }
            }
        }
        Else{
            If(!($busers.ContainsKey($obj.Name))){
                If(Test-Path \\corpterminal2\users\$($obj.samaccountname)\appdata\Roaming\Telmetrics\Logs\billing\log.log){
                    $busers.Add($obj.Name, (Get-Item \\corpterminal2\users\$($obj.samaccountname)\appdata\Roaming\Telmetrics\Logs\billing\log.log | select -ExpandProperty LastWriteTime))
                }
                Else{
                    $busers.Add($obj.Name,"Never")
                }
            }
        }
    }
    Else{
            If(!($busers.ContainsKey($ruser))){
                If(Test-Path \\corpterminal2\users\$ruser\appdata\Roaming\Telmetrics\Logs\billing\log.log){
                    $busers.Add($ruser, (Get-Item \\corpterminal2\users\$ruser\appdata\Roaming\Telmetrics\Logs\billing\log.log | select -ExpandProperty LastWriteTime))
                }
                Else{
                    $busers.Add($ruser,"Never")
                }
            }
    }
}

$busers.keys | select @{l='Name';e={$_}}, @{l='Last Logon';e={$busers.$_}} | Export-Csv C:\Reports\$fname -NoTypeInformation
Send-MailMessage -Attachments C:\Reports\$fname -SmtpServer 10.40.3.41 -Subject "SOX - Billing User Audit" -BodyAsHtml $body -From "auditreports@telmetrics.com" -To "monthly_mssql_user@cms.telmetrics.com"



