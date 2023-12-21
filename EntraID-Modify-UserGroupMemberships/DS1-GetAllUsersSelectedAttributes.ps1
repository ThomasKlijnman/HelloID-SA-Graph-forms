# Define the search value and query
$searchValue = $datasource.searchUser
$searchQuery = "*$searchValue*"

# Build the authorization header
$tokenUrl = "https://login.microsoftonline.com/$GraphtenantID/oauth2/token"
$body = @{
    'resource' = 'https://graph.microsoft.com'
    'client_id' = $GraphclientID
    'client_secret' = $GraphclientSecret
    'grant_type' = 'client_credentials'
}

# Obtain the access token
$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -ContentType "application/x-www-form-urlencoded" -Body $body
$accessToken = $tokenResponse.access_token

# Define the function to invoke the Graph API
function Invoke-GraphApi {
    param (
        [string]$ApiEndpoint,
        [string]$Method = 'GET',
        [string]$Body = $null,
        [string]$Version = 'v1.0'
    )

    # Set the base URL for the Graph API
    $baseUrl = "https://graph.microsoft.com/$Version"

    # Replace 'YOUR_ACCESS_TOKEN' with the dynamically obtained access token
    $authorization = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type' = 'application/json'
    }

    # Build the full URL
    $url = "$baseUrl$ApiEndpoint"

    # Execute the HTTP call based on the specified method
    $response = Invoke-RestMethod -Uri $url -Headers $authorization -Method $Method -Body $Body -ContentType "application/json"

    # Return the response
    $response
}

# Define the properties to be selected
$properties = @("displayName","userPrincipalName","mail","accountEnabled","createdDateTime","id")

# Define the endpoint for fetching users
$userEndpoint = '/users' + '?$select=' + ($properties -join ",") + '&$top=999'
$EntraIDUsersResponse = Invoke-GraphApi -ApiEndpoint $userEndpoint

# Initialize the user list
$EntraIDUsers = $EntraIDUsersResponse.value

# Loop through the paginated results
while (![string]::IsNullOrEmpty($EntraIDUsersResponse.'@odata.nextLink')) {
    $EntraIDUsersResponse = Invoke-GraphApi -ApiEndpoint $EntraIDUsersResponse.'@odata.nextLink'
    $EntraIDUsers += $EntraIDUsersResponse.value
}  

# If there are users, loop through each user and output its properties if the displayName matches the search query
if($EntraIDUsersResponse.count -gt 0){
    foreach($user in $EntraIDUsers){
      if($user.displayName -like $searchQuery){
          $returnObject = @{
             displayName=$user.displayName;
             userPrincipalName=$user.userPrincipalName;
             accountEnabled=$user.accountEnabled
             GUID=$user.id
          }
        Write-Output $returnObject
      }
   }
}
