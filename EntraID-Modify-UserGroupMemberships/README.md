# <img src="https://code.benco.io/icon-collection/azure-icons/Azure-Active-Directory.svg" alt="EntraID" height="30" width="30"> Entra ID: Modify Group Memberships

## Scripts Checklist

Below is a checklist of the scripts required for modifying group memberships in Entra ID:

1. **DS1-GetAllUsersSelectedAttributes.ps1**
   - This script retrieves selected attributes for all users, which from there a single user can be selected.

2. **DS2-Left-GetAllGroupsSelectedAttributes.ps1**
   - This script retrieves selected attributes for all groups on the left side on the second paga of the form.

3. **DS2-Right-GetAllGroupMembershipsFromuser.ps1**
   - This script retrieves all group memberships for the selected user on page one on the right side of page two.

## JSON Export

Additionally, there is a JSON export of the form in HelloID:
- **Form-Edit-Group-Membership-with-Selector.json**
   - This JSON file contains the configuration for editing group memberships with a selector in HelloID.

These scripts and JSON export are essential for the successful execution of the Modify Group Memberships functionality in Entra ID. Ensure you have these resources before making any changes.

