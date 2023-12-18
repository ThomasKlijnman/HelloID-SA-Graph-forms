
$searchValue = $datasource.searchUser
$searchQuery = "*$searchValue*"

# Bouw de autorisatieheader
$tokenUrl = "https://login.microsoftonline.com/$GraphtenantID/oauth2/token"
$body = @{
    'resource' = 'https://graph.microsoft.com'
    'client_id' = $GraphclientID
    'client_secret' = $GraphclientSecret
    'grant_type' = 'client_credentials'
}

# Verkrijg het access token
$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -ContentType "application/x-www-form-urlencoded" -Body $body
$accessToken = $tokenResponse.access_token

# Voer het GET-verzoek uit met filtering direct in de URL
$authorization = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type' = 'application/json'
}

$properties = @("displayName","userPrincipalName","mail","accountEnabled","createdDateTime","id")

$baseSearchUri = "https://graph.microsoft.com/"
$searchUri = $baseSearchUri + "v1.0/users" + '?$select=' + ($properties -join ",") + '&$top=999'

Try{
  $EntraIDUsersResponse = Invoke-RestMethod -Uri $searchUri -Method Get -Headers $authorization -Verbose:$false
  $EntraIDUsers = $EntraIDUsersResponse.value

  while (![string]::IsNullOrEmpty($EntraIDUsersResponse.'@odata.nextLink')) {
    $EntraIDUsersResponse = Invoke-RestMethod -Uri $EntraIDUsersResponse.'@odata.nextLink' -Method Get -Headers $authorization -Verbose:$false
    $EntraIDUsers += $EntraIDUsersResponse.value
  }  

  if($EntraIDUsersResponse.count -gt 0){
    foreach($user in $EntraIDUsers){
      if($user.displayName -like $searchQuery){
          $returnObject = @{
             displayName=$user.displayName;
              userPrincipalName=$user.userPrincipalName;
             #mail=$user.mail;
             accountEnabled=$user.accountEnabled
            GUID=$user.id
        }
      Write-Output $returnObject
      }
   }
 }
}
catch {
        $errorDetailsMessage = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
        Write-Error ("Error searching for EntraID Users. Error: $_" + $errorDetailsMessage)
}

