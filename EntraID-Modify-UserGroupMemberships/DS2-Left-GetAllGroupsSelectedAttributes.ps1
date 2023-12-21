# Define the UserPrincipalName
$UserPrincipalName = $datasource.UserPrincipalName
$UserGUID = $datasource.GUID

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

# Define the endpoint for fetching user groups
$userGroupsEndpoint = "/users/$UserGUID/memberOf/microsoft.graph.group?$select=displayName,id,onPremisesSyncEnabled"
$UserGroupsResponse = Invoke-GraphApi -ApiEndpoint $userGroupsEndpoint

# Initialize the group list
$UserGroups = $UserGroupsResponse.value

# Loop through the paginated results
while (![string]::IsNullOrEmpty($UserGroupsResponse.'@odata.nextLink')) {
    $UserGroupsResponse = Invoke-GraphApi -ApiEndpoint $UserGroupsResponse.'@odata.nextLink'
    $UserGroups += $UserGroupsResponse.value
}  

# If there are groups, loop through each group and output its properties
if($UserGroupsResponse.count -gt 0){
    foreach($group in $UserGroups){
        # Check if onPremisesSyncEnabled is false
        if (-not $group.onPremisesSyncEnabled){
            $returnObject = @{
                displayName=$group.displayName;
                id=$group.id;
            }
            Write-Output $returnObject
        }
    }
}

