$td = Get-Date
$rdate = Get-Date -Format "ddMMyyyy"
$fpath = "C:\Reports\adusers$rdate.csv"
$body = "Corporate users part of telmetrics.corp domain audited on $td1"
If(Test-Path $fpath) {Remove-Item $fpath}
Get-ADOrganizationalUnit -Filter * | %{ Get-ADUser -filter * -Properties * -SearchBase $_.DistinguishedName -SearchScope OneLevel | ?{$_.enabled -eq $True} | select Name,@{n='Organizational Unit';e={($_.canonicalname -Split "/")[-2]}},@{Name='LastLogonTimeStamp';Expression={If($_.LastLogonTimeStamp){([DateTime]::FromFileTime($_.LastLogonTimeStamp)).ToShortDateString()} Else{"Never Logged On"}}}} | Export-Csv $fpath -NoTypeInformation
Send-MailMessage -Attachments $fpath -SmtpServer 10.40.3.41 -Subject "SOX - Corporate User Audit" -BodyAsHtml $body -From "auditreports@telmetrics.com" -To "monthly_mssql_user@cms.telmetrics.com"


