# Powershell Script which creates users from a sample CSV File into Active Directory
# Version 1.1
# Modified to work in Multiple Domain Environments
# Author: Andy Grogan
# http://www.telnetport25.com
#
# Compatible with:
# Powershell 1.0 and 2.0
# Windows 2003
# Windows 2008
# Windows 2008 R2
#
$ErrorActionPreference = "SilentlyContinue"

function Select-FileDialog
{
	param([string]$Title,[string]$Directory,[string]$Filter="CSV Files (*.csv)|*.csv")
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	$objForm = New-Object System.Windows.Forms.OpenFileDialog
	$objForm.InitialDirectory = $Directory
	$objForm.Filter = $Filter
	$objForm.Title = $Title
	$objForm.ShowHelp = $true

	$Show = $objForm.ShowDialog()

	If ($Show -eq "OK")
	{
		Return $objForm.FileName
	}
	Else
	{
		Exit
	}
}

$FileName = Select-FileDialog -Title "Import an CSV file" -Directory "c:\"

$ExchangeUsersOU = "OU=ExchangeUsers"

$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
$DomainDN = (([System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()).Domains | ? {$_.Name -eq $domain}).GetDirectoryEntry().distinguishedName
$final = "LDAP://$DomainDN"
$DomainPath = [ADSI]"$final"
$cOU = $DomainPath.Create("OrganizationalUnit",$ExchangeUsersOU)
$cOU.SetInfo()

$UserInformation = Import-Csv $FileName

$OUPath = "LDAP://$ExchangeUsersOU,$DomainDN"
$UserPath = [ADSI]"$OUPath"
Write-Host "---------------------------------------------------------------"
Write-Host "Creating LAB Users"
Write-Host "Version 1.1"
Write-Host "---------------------------------------------------------------"

Foreach ($User in $UserInformation){

	$CN = $User.samAccountName
	$SN = $User.Surname
	$Given = $User.givenName
	$samAccountName = $User.samAccountName
	$Display = $User.DisplayName

	$LABUser = $UserPath.Create("User","CN=$CN")
	Write-Host "Creating User: $User.samAccountName"
	$LABUser.Put("samAccountName",$samAccountName)
	$LABUser.Put("sn",$SN)
	$LABUser.Put("givenName",$Given)
	$LABUser.Put("displayName",$Display)
	$LABUser.Put("mail","$samAccountName@$domain")
	$LABUser.Put("description", "Lab User - created via Script")
	$LABUser.Put("userPrincipalName","$samAccountName@$domain")
	$LABUser.SetInfo()

	$Pwrd = $User.Password

	$LABUser.psbase.invoke("setPassword",$Pwrd)
	$LABUser.psbase.invokeSet("AccountDisabled",$False)
	$LABUser.psbase.CommitChanges()

}
Write-Host "Script Completed"

	
