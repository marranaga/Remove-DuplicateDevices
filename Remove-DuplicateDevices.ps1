$Expression = 'select r.ResourceId, r.ResourceType, r.Name, r.SMSUniqueIdentifier, r.ResourceDomainORWorkgroup, r.Client, r.CreationDate from  SMS_R_System as r full join SMS_R_System as s1 on s1.ResourceId = r.ResourceId full join SMS_R_System as s2 on s2.Name = s1.Name where s1.Name = s2.Name and s1.ResourceId != s2.ResourceId order by r.CreationDate'
$QueryName = 'Duplicate Systems'

if (-not (Get-CMQuery -Name $QueryName)) {
    New-CMQuery -Expression $Expression -Name $QueryName -Comment 'Find all duplicate systems in the site'
}

$Duplicates = Invoke-CMQuery -Name $QueryName
$DuplicateNames = $Duplicates | Group-Object -Property Name -NoElement | Select-Object -ExpandProperty Name

foreach ($DuplicateName in $DuplicateNames) {
    $DuplicateItems = $Duplicates | Where-Object { $_.Name -eq $DuplicateName }

    $New = $DuplicateItems | Sort-Object -Property 'CreationDate' -Descending | Select-Object -First 1
    $Old = $DuplicateItems | Sort-Object -Property 'CreationDate' -Descending | Select-Object -Skip 1

    Write-Host "Old Object(s): $($Old | Out-String)" -ForegroundColor 'Magenta'
    Write-Host "New Object(s): $($New | Out-String)" -ForegroundColor 'Cyan'
    $Old | Foreach-Object { Get-CMResource -ResourceId $_.ResourceId -Fast } | Foreach-Object { Remove-CMDevice -InputObject $_ -Force }
}