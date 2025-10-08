# Define the File Server name
$FileServer = "MIL01.christies.com"  # <--- REPLACE THIS
 
# 1. Get all SMB Shares on the specified server and filter out the C: drive
$Shares = Invoke-Command -ComputerName $FileServer -ScriptBlock {
    Get-SmbShare | 
        Where-Object { 
            # Exclude special/administrative shares that have no path defined, 
            # AND explicitly exclude shares pointing to the root of C:
            ($_.Path -ne $null) -and ($_.Path -notmatch '^[Cc]:\\$')
        } |
        Select-Object Name, Path
}
 
# Create an empty array to store the results
$Report = @()
 
Write-Host "Gathering information for shares on '$FileServer'..."
 
# 2. Loop through each valid share
foreach ($Share in $Shares) {
    Write-Host "Processing Share: $($Share.Name)..."
 
    # Construct the UNC path for remote access
    $UNCPath = "\\$FileServer\" + $Share.Name
 
    try {
        # Get all items recursively 
        # Note: This is where most of the execution time is spent.
        $Items = Get-ChildItem -Path $UNCPath -Recurse -Force -ErrorAction SilentlyContinue
 
        # Calculate the total size (sum of all file lengths)
        $TotalSizeInBytes = ($Items | Where-Object {!$_.PSIsContainer} | Measure-Object -Property Length -Sum).Sum
        $TotalSizeInGB = [math]::Round($TotalSizeInBytes / 1GB, 2)
 
        # Find the last activity date (LastWriteTime)
        $LastActivity = ($Items | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
 
        # Create a custom object for the report
        $Report += [PSCustomObject]@{
            ShareName      = $Share.Name
            UNCPath        = $UNCPath
            TotalSize_GB   = $TotalSizeInGB
            LastActivity_TS = $LastActivity
        }
    }
    catch {
        Write-Warning "Could not process share $($Share.Name). Error: $($_.Exception.Message)"
        $Report += [PSCustomObject]@{
            ShareName      = $Share.Name
            UNCPath        = $UNCPath
            TotalSize_GB   = "Error"
            LastActivity_TS = "Error"
        }
    }
}
 
# 3. Output the results
$Report | Select-Object ShareName, UNCPath, TotalSize_GB, LastActivity_TS | Format-Table -AutoSize
