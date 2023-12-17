
$UserPrincipalName = $datasource.UserPrincipalName

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

# Nieuw endpoint met variabel
$baseSearchUri = "https://graph.microsoft.com/"
$searchUri = $baseSearchUri + "v1.0/users/$UserPrincipalName/memberOf/microsoft.graph.group?$select=displayName,id"

Try{
  $UserGroupsResponse = Invoke-RestMethod -Uri $searchUri -Method Get -Headers $authorization -Verbose:$false
  $UserGroups = $UserGroupsResponse.value

  while (![string]::IsNullOrEmpty($UserGroupsResponse.'@odata.nextLink')) {
    $UserGroupsResponse = Invoke-RestMethod -Uri $UserGroupsResponse.'@odata.nextLink' -Method Get -Headers $authorization -Verbose:$false
    $UserGroups += $UserGroupsResponse.value
  }  

  if($UserGroupsResponse.count -gt 0){
    foreach($group in $UserGroups){
      $returnObject = @{
         displayName=$group.displayName;
         id=$group.id
      }
      Write-Output $returnObject
    }
  }
}
catch {
    $errorDetailsMessage = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
    Write-Error ("Error with searching for Groups. Error: $_" + $errorDetailsMessage)
}
