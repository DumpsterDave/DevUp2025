#region Blocking Collections
<#
  In this example, we utilize a blocking collection with a "builder" to fully populate the collection before a "consumer" starts consuming items from it. The consumer will wait until the builder has completed adding items before it starts processing them.
#>
$BlockingCollection = [System.Collections.Concurrent.BlockingCollection[System.Int32]]::new()
$Runspaces = [System.Collections.Generic.List[Object]]::new()

#Create the producer/builder runspace
$Builder = [PowerShell]::Create()
$Builder.Runspace.Name = "Builder"
[void]$Builder.AddScript({
  Param(
    [System.Collections.Concurrent.BlockingCollection[Int32]]$BlockingCollection
  )
  Write-Output "$(Get-Date -f 'HH:mm:ss.fff') Started adding items to the collection"
  for ($i = 0; $i -lt 100; $i++) {
    $BlockingCollection.Add($i)
    Start-Sleep -Milliseconds 25
  }
  $BlockingCollection.CompleteAdding()
  Write-Output "$(Get-Date -f 'HH:mm:ss.fff') Completed adding items to the collection"
})
[void]$Builder.AddParameters(@{
  BlockingCollection = $BlockingCollection
})

#create the consumer
$Consumer = [PowerShell]::Create()
$Consumer.Runspace.Name = "Consumer"
[void]$Consumer.AddScript({
  Param(
    [System.Collections.Concurrent.BlockingCollection[Int32]]$BlockingCollection
  )
  Write-Output "$(Get-Date -f 'HH:mm:ss.fff') Started consuming items from the collection"
  $item = $null
  while ($BlockingCollection.IsAddingCompleted -ne $true) {
    Start-Sleep -Milliseconds 10
  }
  while ($BlockingCollection.TryTake([ref]$item, 100)) {
    Write-Output "$(Get-Date -f 'HH:mm:ss.fff') Consumed item: $item"
  }
  Write-Output "$(Get-Date -f 'HH:mm:ss.fff') Completed consuming items from the collection"
})
[void]$Consumer.AddParameters(@{
  BlockingCollection = $BlockingCollection
})

$Ps = "" | Select-Object PowerShell,Handle
$Ps.Handle = $Consumer.BeginInvoke()
$Ps.PowerShell = $Consumer
[void]$Runspaces.Add($Ps)

$Ps = "" | Select-Object PowerShell,Handle
$Ps.Handle = $Builder.BeginInvoke()
$Ps.PowerShell = $Builder
[void]$Runspaces.Add($Ps)

$Runspaces
foreach ($Rs in $Runspaces) {
  Write-Output "Runspace: $($Rs.PowerShell.Runspace.Name)"
  Write-Output $Rs.PowerShell.EndInvoke($Rs.Handle)
  $Rs.PowerShell.Dispose()
}
#endregion

#region Concurrent Bag
<#
  In this example, we create a ConcurrentBag and populate it with items from multiple runspaces. Each runspace adds a range of items to the bag, demonstrating how concurrent collections can be used to safely share data between threads.
#>
$ConcurrentBag = [System.Collections.Concurrent.ConcurrentBag[System.Int32]]::new()
$Runspaces = [System.Collections.Generic.List[Object]]::new()
$RunspacePool = [runspacefactory]::CreateRunspacePool(1,10)
$RunspacePool.Open()
for ($i = 0; $i -lt 10; $i++) {
  $PowerShell = [powershell]::Create()
  $PowerShell.Runspace.Name = "Runspace_$($i)"
  $PowerShell.RunspacePool = $RunspacePool
  [void]$PowerShell.AddScript({
    Param(
      [System.Collections.Concurrent.ConcurrentBag[Int32]]$ConcurrentBag,
      [Int32]$index
    )
    $Start = $Index * 10
    $End = $Start + 10
    for ($j = $Start; $j -lt $End; $j++) {
      $ConcurrentBag.Add($j)
      Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 100)
    }
  })
  [void]$PowerShell.AddParameters(@{
    ConcurrentBag=$ConcurrentBag;
    index=$i;
  })

  $Ps = "" | Select-Object PowerShell,Handle
  $Ps.Handle = $PowerShell.BeginInvoke()
  $Ps.PowerShell = $PowerShell
  [void]$Runspaces.Add($Ps)
}

foreach ($runspace in $Runspaces) {
  [void]$runspace.PowerShell.EndInvoke($runspace.Handle)
  $runspace.PowerShell.Dispose()
}
$ConcurrentBag
#endregion

#region Concurrent Dictionary
<#
  In this example, we create a concurrent dictionary with keys set to each letter of the English alphabet.  Each runspace randomly selects a key 26 times and increments it's value in the dictionary.  
#>
$ConcurrentDictionary = [System.Collections.Concurrent.ConcurrentDictionary[String,Int32]]::new()
$Runspaces = [System.Collections.Generic.List[Object]]::new()
$RunspacePool = [runspacefactory]::CreateRunspacePool(1,10)
$RunspacePool.Open()
$Keys = "A".."Z"
for ($i = 0; $i -lt 10; $i++) {
  $PowerShell = [powershell]::Create()
  $PowerShell.Runspace.Name = "Runspace_$($i)"
  $PowerShell.RunspacePool = $RunspacePool
  [void]$PowerShell.AddScript({
    Param(
      [System.Collections.Concurrent.ConcurrentDictionary[String,Int32]]$ConcurrentDictionary,
      [String[]]$Keys
    )
      #Create an Update Factory Function
      $Increment = { param($key, $oldValue) $oldValue + 1 }

      #Populate it with random keys
      for ($i = 0; $i -lt 26; $i++) {
        $index = Get-Random -Minimum 0 -Maximum 25
        $key = $Keys[$index]
        $ConcurrentDictionary.AddOrUpdate($key, 1, $Increment)
      }
  })
  [void]$PowerShell.AddParameters(@{
    ConcurrentDictionary=$ConcurrentDictionary;
    Keys=$Keys;
  })

  $Ps = "" | Select-Object PowerShell,Handle
  $Ps.Handle = $PowerShell.BeginInvoke()
  $Ps.PowerShell = $PowerShell
  [void]$Runspaces.Add($Ps)
}

foreach ($runspace in $Runspaces) {
  [void]$runspace.PowerShell.EndInvoke($runspace.Handle)
  $runspace.PowerShell.Dispose()
}
$ConcurrentDictionary
$Total = 0
foreach ($key in $ConcurrentDictionary.Keys) {
  $Total += $ConcurrentDictionary[$key]
}
Write-Output "`e[106mConcurrent Dictionary Total (Should be 260):`e[0m"
$Total
#endregion

#region Concurrent Queue
<#
  This example demonstrates adding items to a queue (in order)
#>
$ConcurrentQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$Runspaces = [System.Collections.Generic.List[Object]]::new()
$RunspacePool = [runspacefactory]::CreateRunspacePool(1,10)
$RunspacePool.Open()
for ($i = 0; $i -lt 10; $i++) {
  $PowerShell = [powershell]::Create()
  $PowerShell.Runspace.Name = "Runspace_$($i)"
  $PowerShell.RunspacePool = $RunspacePool
  [void]$PowerShell.AddScript({
    Param(
      [System.Collections.Concurrent.ConcurrentQueue[string]]$ConcurrentQueue,
      [Int32]$index
    )
    for ($j = 1; $j -lt 11; $j++) {
      $ConcurrentQueue.Enqueue("Runspace $($index) - Item $($j)")
      Start-Sleep -Milliseconds (Get-Random -Minimum 1 -Maximum 100)
    }
  })
  [void]$PowerShell.AddParameters(@{
    ConcurrentQueue=$ConcurrentQueue;
    index=$i;
  })

  $Ps = "" | Select-Object PowerShell,Handle
  $Ps.Handle = $PowerShell.BeginInvoke()
  $Ps.PowerShell = $PowerShell
  [void]$Runspaces.Add($Ps)
}
foreach ($runspace in $Runspaces) {
  [void]$runspace.PowerShell.EndInvoke($runspace.Handle)
  $runspace.PowerShell.Dispose()
}
$ConcurrentQueue
#endregion

#region Concurrent Stack
<#
  This example demonstrates popping items from a stack (in reverse order).  The stack has 75 items, but uses 10 runspaces to pop them off.  Each runspace will pop items until the stack is empty.
#>
$ConcurrentStack = [System.Collections.Concurrent.ConcurrentStack[Int32]]::new()
for ($i = 1; $i -le 75; $i++) {
  $ConcurrentStack.Push($i)
}
$Runspaces = [System.Collections.Generic.List[Object]]::new()
$RunspacePool = [runspacefactory]::CreateRunspacePool(1,10)
$RunspacePool.Open()
for ($i = 0; $i -lt 10; $i++) {
  $PowerShell = [powershell]::Create()
  $PowerShell.Runspace.Name = "Runspace_$($i)"
  $PowerShell.RunspacePool = $RunspacePool
  [void]$PowerShell.AddScript({
    Param(
      [System.Collections.Concurrent.ConcurrentStack[Int32]]$ConcurrentStack,
      [Int32]$index
    )
    $item = $null
    while ($ConcurrentStack.TryPop([ref]$item)) {
      Write-Output "Runspace $($index) grabbed $($item)"
      Start-Sleep -Milliseconds (Get-Random -Minimum 1 -Maximum 100)
    }
  })
  [void]$PowerShell.AddParameters(@{
    ConcurrentStack=$ConcurrentStack;
    index=$i;
  })

  $Ps = "" | Select-Object PowerShell,Handle
  $Ps.Handle = $PowerShell.BeginInvoke()
  $Ps.PowerShell = $PowerShell
  [void]$Runspaces.Add($Ps)
}
foreach ($runspace in $Runspaces) {
  Write-Output $runspace.PowerShell.EndInvoke($runspace.Handle)
  $runspace.PowerShell.Dispose()
}
#endregion