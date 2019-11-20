$tdate = Get-Date 
$rdate = Get-Date -Format "ddMMyyyy"
$fpath = "C:\Reports\sox-audit$rdate.txt"
$body = "Production users audited on $tdate"

If(Test-Path $fpath){Remove-Item $fpath -Force}

Get-ADUser -Filter * | select name



Add-Content $fpath "Audit Report run on $tdate"
Add-Content $fpath "--------------------------`r`n"


Add-Content $fpath "`r`nProduction User Accounts"
Add-Content $fpath "------------------------"

$dusers = Get-ADUser -Filter {enabled -eq $True} | select -ExpandProperty name
$dusers | %{Add-Content $fpath $_}


Add-Content $fpath "`r`nProduction Domain admins"
Add-Content $fpath "------------------------"

$dadmins = Get-ADGroupMember "Domain admins" | select -ExpandProperty name
$dadmins | %{Add-Content $fpath $_}


Add-Content $fpath "`r`nMembers of LocalAdmins Group"
Add-Content $fpath "------------------------"

$dadmins = Get-ADGroupMember "LocalAdmins" | select -ExpandProperty name
$dadmins | %{Add-Content $fpath $_}

Add-Content $fpath "`r`nMembers of SQLAdmins Group"
Add-Content $fpath "------------------------"

$dadmins = Get-ADGroupMember "SQLAdmins" | select -ExpandProperty name
$dadmins | %{Add-Content $fpath $_}

$adcomputers = Get-ADComputer -Filter * -SearchScope Subtree -SearchBase "OU=Servers,DC=Production,DC=com" | select -expand DNSHostName
Foreach($adcomputer in $adcomputers){
    If (Test-Connection -ComputerName $adcomputer -Quiet){
        $ladmins = Invoke-Command -ComputerName $adcomputer {net localgroup administrators | where {$_ -AND $_ -notmatch "command completed successfully"} | select -skip 4} -ErrorAction SilentlyContinue
        Add-Content $fpath "`r`nAdministrators on server $adcomputer"
        Add-Content $fpath "---------------------------------------"
        $ladmins | %{Add-Content $fpath $_}
    }
}

Send-MailMessage -Attachments $fpath -SmtpServer 10.40.3.41 -Subject "SOX - Production User Audit" -BodyAsHtml $body -From "auditreports@telmetrics.com" -To "monthly_mssql_user@cms.telmetrics.com"