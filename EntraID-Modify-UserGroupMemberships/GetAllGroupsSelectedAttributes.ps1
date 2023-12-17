
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
$properties = @("displayName","description","renewedDateTime","SecurityEnabled","CreatedDateTime","id")

$baseSearchUri = "https://graph.microsoft.com/"
$searchUri = $baseSearchUri + "v1.0/groups" + '?$select=' + ($properties -join ",") + '&$top=999'

Try{
  $EntraIDGroupsResponse = Invoke-RestMethod -Uri $searchUri -Method Get -Headers $authorization -Verbose:$false
  $EntraIDGroups = $EntraIDGroupsResponse.value

  while (![string]::IsNullOrEmpty($EntraIDGroupsResponse.'@odata.nextLink')) {
    $azureADUsersResponse = Invoke-RestMethod -Uri $EntraIDGroupsResponse.'@odata.nextLink' -Method Get -Headers $authorization -Verbose:$false
    $EntraIDGroups += $EntraIDGroupsResponse.value
  }  

    if($EntraIDGroupsResponse.count -gt 0){
      foreach($group in $EntraIDGroups){
        
            $returnObject = @{
               displayName=$group.displayName;
                description=$group.description;
               createdDateTime=$group.createdDateTime;
               securityEnabled=$group.securityEnabled
              GUID=$group.id
          }
        Write-Output $returnObject
     }
   }
}
catch {
        $errorDetailsMessage = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
        Write-Error ("Error searching for EntraID Groups. Error: $_" + $errorDetailsMessage)
}
