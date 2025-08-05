#region Unsafe Collections
<#
  Here, we create a simple runspace that accepts an ArrayList, a Hashtable, and an Int32.  It then attempts to update each by incrementing the first element of the ArrayList, the first key of the Hashtable, and the Int32 value.
#>
$UnsafeArrayList = [System.Collections.ArrayList]::New(1..2)
$UnsafeHashTable = [System.Collections.Hashtable]::New(@{0=1})
[Int32]$UnsafeInt = 100

$RunspacePool = [runspacefactory]::CreateRunspacePool(1,10)
$RunspacePool.Open()

$Runspaces = [System.Collections.Generic.List[Object]]::new()

for ($i = 0; $i -lt 100; $i++) {
  $PowerShell = [powershell]::Create()
  $PowerShell.Runspace.Name = "Runspace_$($i)"
  $Powershell.RunspacePool = $RunspacePool
  [void]$PowerShell.AddScript({
    Param(
      $ArrayList,
      $HashTable,
      $int
    )
    Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 20)
    $ArrayList[0]++
    $HashTable[0]++
    $int++
  })
  [void]$PowerShell.AddParameters(@{
    ArrayList=$UnsafeArrayList;
    HashTable=$UnsafeHashTable;
    int=$UnsafeInt
    index=$i;
  })

  $Ps = "" | Select-Object PowerShell,Handle
  $Ps.Handle = $PowerShell.BeginInvoke()
  $Ps.PowerShell = $PowerShell
  
  [void]$Runspaces.Add($Ps)
}

foreach ($runspace in $Runspaces) {
  $Output = $runspace.PowerShell.EndInvoke($runspace.Handle)
  $runspace.PowerShell.Dispose()
}
#endregion

#region Unsafe Results
Clear-Host
Write-Output "`e[106mUnsafe Array List (Was [1, 2]):`e[0m"
$UnsafeArrayList
Write-Output "`e[106mUnsafe Hash Table (Was {0=1}):`e[0m"
$UnsafeHashTable
Write-Output "`e[106mUnsafe Int (Was 100):`e[0m"
$UnsafeInt
#endregion

#region Safe Collections
<#
  In this example, we replace the arraylist and Hashtable with their synchronized versions.  This allows us to safely update them from multiple threads...  Sorta
#>
$SafeArrayList = [System.Collections.ArrayList]::Synchronized(1..2)
$SafeHashTable = [System.Collections.Hashtable]::Synchronized(@{0=1})
[Int32]$SafeInt = 100

$RunspacePool = [runspacefactory]::CreateRunspacePool(1,10)
$RunspacePool.Open()

$Runspaces = [System.Collections.Generic.List[Object]]::new()

for ($i = 0; $i -lt 100; $i++) {
  $PowerShell = [powershell]::Create()
  $PowerShell.Runspace.Name = "Runspace_$($i)"
  $Powershell.RunspacePool = $RunspacePool
  [void]$PowerShell.AddScript({
    Param(
      $ArrayList,
      $HashTable,
      $int
    )
    Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 20)
    $ArrayList[0]++
    $HashTable[0]++
    $int++
  })
  [void]$PowerShell.AddParameters(@{
    ArrayList=$SafeArrayList;
    HashTable=$SafeHashTable;
    int=$SafeInt
    index=$i;
  })

  $Ps = "" | Select-Object PowerShell,Handle
  $Ps.Handle = $PowerShell.BeginInvoke()
  $Ps.PowerShell = $PowerShell
  
  [void]$Runspaces.Add($Ps)
}

foreach ($runspace in $Runspaces) {
  $Output = $runspace.PowerShell.EndInvoke($runspace.Handle)
  $runspace.PowerShell.Dispose()
}
#endregion

#region Safe Results
Clear-Host
Write-Output "`e[106mSafe Array List (Was [1, 2]):`e[0m"
$SafeArrayList
Write-Output "`e[106mSafe Hash Table (Was {0=1}):`e[0m"
$SafeHashTable
Write-Output "`e[106mSafe Int (Was 100):`e[0m"
$SafeInt
#endregion

#region Actually Safe Collections
<#
  Here we actually make the collections safe by using a Monitor to lock them while we update them.  This is the correct way to ensure thread safety when sharing data between runspaces.
#>
$SafeArrayList = [System.Collections.ArrayList]::Synchronized(1..2)
$SafeHashTable = [System.Collections.Hashtable]::Synchronized(@{0=1})
[Int32]$SafeInt = 100

$RunspacePool = [runspacefactory]::CreateRunspacePool(1,10)
$RunspacePool.Open()

$Runspaces = [System.Collections.Generic.List[Object]]::new()

for ($i = 0; $i -lt 100; $i++) {
  $PowerShell = [powershell]::Create()
  $PowerShell.Runspace.Name = "Runspace_$($i)"
  $Powershell.RunspacePool = $RunspacePool
  [void]$PowerShell.AddScript({
    Param(
      $ArrayList,
      $HashTable,
      $int
    )
    [System.Threading.Monitor]::Enter($ArrayList)
    [System.Threading.Monitor]::Enter($HashTable)
    Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 20)
    $ArrayList[0]++
    $HashTable[0]++
    [System.Threading.Monitor]::Exit($HashTable)
    [System.Threading.Monitor]::Exit($ArrayList)
    $int++
  })
  [void]$PowerShell.AddParameters(@{
    ArrayList=$SafeArrayList;
    HashTable=$SafeHashTable;
    int=$SafeInt
    index=$i;
  })

  $Ps = "" | Select-Object PowerShell,Handle
  $Ps.Handle = $PowerShell.BeginInvoke()
  $Ps.PowerShell = $PowerShell
  
  [void]$Runspaces.Add($Ps)
}

foreach ($runspace in $Runspaces) {
  $Output = $runspace.PowerShell.EndInvoke($runspace.Handle)
  $runspace.PowerShell.Dispose()
}
#endregion

#region Actually Safe Results
Clear-Host
Write-Output "`e[106mActually Safe Array List (Was [1, 2]):`e[0m"
$SafeArrayList
Write-Output "`e[106mActually Safe Hash Table (Was {0=1}):`e[0m"
$SafeHashTable
Write-Output "`e[106mActually Safe Int (Was 100):`e[0m"
$SafeInt
#endregion