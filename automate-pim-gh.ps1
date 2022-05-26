##Activate PIM automatically

$Cloud_Email = $env:USERNAME + "@yourDomain.com" # Enter your domain here
$Tenant_ID = "Tenant_ID_Here" #Enter tenant ID
##The Azure app that has perissions to get token on users behalf
$App_Client_ID = "App_Client_ID" ##Client ID of app created in AzureAD
$MSAL_Authority = "Your_AzureAD_Primary_domain" #The Primamry domain from AzureAD


# Get token for MS Graph
$MsResponse = Get-MSALToken -Scopes @("https://graph.microsoft.com/.default") -ClientId $App_Client_ID -RedirectUri "urn:ietf:wg:oauth:2.0:oob" -Authority $MSAL_Authority -Interactive -ExtraQueryParameters @{claims='{"access_token" : {"amr": { "values": ["mfa"] }}}'}

# Get token for AAD Graph
$AadResponse = Get-MSALToken -Scopes @("https://graph.windows.net/.default") -ClientId $App_Client_ID -RedirectUri "urn:ietf:wg:oauth:2.0:oob" -Authority $MSAL_Authority

##Connecting to azure ad using AAD access token + 
Connect-AzureAD -AadAccessToken $AadResponse.AccessToken -MsAccessToken $MsResponse.AccessToken -AccountId: $cloud_email -tenantId: $Tenant_ID

Write-host($Azure_Subject_ID)
function ActivatePIM(){
    $Azure_Subject_ID = Get-AzureADUser -SearchString $Cloud_Email | Select-Object ObjectID
    Write-Host($Azure_Subject_ID.ObjectId)
    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.EndDateTime = (Get-Date).AddHours(8).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $roleDefinition = Get-AzureADMSPrivilegedRoleDefinition  -ProviderId AadRoles -ResourceId $Tenant_ID -Filter "DisplayName eq 'User Administrator'" ##Enter role you would like to activate
    Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId AadRoles -Schedule $schedule -ResourceId $Tenant_ID -RoleDefinitionId $roleDefinition.Id -SubjectId $Azure_Subject_ID.ObjectId -Type 'UserAdd' -AssignmentState 'Active' -Reason ""
}

ActivatePIM



