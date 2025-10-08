# Create an array to store results
$results = @()
 
# Get all SMB shares
$shares = Get-SmbShare
 
foreach ($share in $shares) {
    $path = $share.Path
    $lastAccess = ""
    $permissions = ""
 
    # Check if path is not empty/null and exists
    if (![string]::IsNullOrWhiteSpace($path) -and (Test-Path $path)) {
        $lastAccess = (Get-Item $path).LastAccessTime
        $acl = Get-Acl $path
 
        # Build permissions string
        $permList = @()
        foreach ($entry in $acl.Access) {
            $permList += "$($entry.IdentityReference): $($entry.FileSystemRights)"
        }
        $permissions = $permList -join ", "
    } else {
        $lastAccess = "Path Not Found or Empty"
        $permissions = "N/A"
    }
 
    # Add to results
    $results += [PSCustomObject]@{
        ShareName      = $share.Name
        LastAccessed   = $lastAccess
        Permissions    = $permissions
    }
}
 
# Export to CSV file
$results | Export-Csv -Path "C:\Temp\ShareInfo.csv" -NoTypeInformation -Encoding UTF8
