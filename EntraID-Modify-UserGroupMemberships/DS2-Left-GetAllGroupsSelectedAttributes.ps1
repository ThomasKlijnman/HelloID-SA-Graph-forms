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

# Function to invoke the Graph API with parameters
function Invoke-GraphApi {
    param (
        [string]$ApiEndpoint,
        [string]$Method = 'GET',
        [string]$Body = $null,
        [string]$Version = 'v1.0'
    )

    # Set the base URL for the Graph API via version param. (For example; v1.0 or Beta)
    $baseUrl = "https://graph.microsoft.com/$Version"

    # Fill the bearer token with the dynamically obtained access token
    $authorization = @{
        'Authorization' = "Bearer $accessToken"
        'Content-Type' = 'application/json'
    }

    # Build the full URL
    $url = "$baseUrl$ApiEndpoint"

    # Execute the API call based on the specified method
    $response = Invoke-RestMethod -Uri $url -Headers $authorization -Method $Method -Body $Body -ContentType "application/json"

    # Return the response
    $response
}

# Define parameters for invoking the Graph API
$InvokeParams = @{
  ApiEndpoint = "/groups"
  Method = "GET"
  Body = $null
}

# Invoke the Graph API and get the response
$EntraIDGroupsResponse = Invoke-GraphApi @InvokeParams

# Initialize the group list
$EntraIDGroups = $EntraIDGroupsResponse.value

# Excluded group list
$excludedGuids = @("%STRIPED%")

# Loop through the paginated results
while (![string]::IsNullOrEmpty($EntraIDGroupsResponse.'@odata.nextLink')) {
    $EntraIDGroupsResponse = Invoke-GraphApi -ApiEndpoint $EntraIDGroupsResponse.'@odata.nextLink'
    $EntraIDGroups += $EntraIDGroupsResponse.value
}  

# If there are groups, loop through each group and output its properties
if($EntraIDGroupsResponse.count -gt 0){
    foreach($group in $EntraIDGroups){
        # Check if onPremisesSyncEnabled is false
        if (-not $group.onPremisesSyncEnabled -and $excludedGuids -notcontains $group.id) {
            $returnObject = @{
                displayName=$group.displayName;
                description=$group.description;
                createdDateTime=$group.createdDateTime;
                GUID=$group.id;
            }
            Write-Output $returnObject
         } 
    }
}
