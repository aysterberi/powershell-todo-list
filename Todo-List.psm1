Function Todo
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [ValidateSet("add", "remove", "complete", "set", "list", "help", "open", "")]
        [string] $Command,
        [Parameter()][Alias("d")]
        [string] $Description,
        [Parameter()][Alias("s")]
        [string] $Status,
        [Parameter()][Alias("i")]
        [string] $Id,
        [Parameter()][Alias("u")]
        [string] $Url
    )

    # Get or create the file
    if (-not(Test-Path -Path $PSScriptRoot\Todo-List.json -PathType Leaf))
    {
        try
        {
            New-Item -Path $PSScriptRoot\Todo-List.json -ItemType File -Force -ErrorAction Stop
        } catch
        {
            Write-Error -Message "Unable to create Todo-List.json file. Please check permissions and try again." -ErrorAction Stop
        }
    }

    # If no command is specified, show help
    if (-not($Command))
    {
        Write-TodoHelp
    } else
    {
        switch ($Command)
        {
            "add"       { Invoke-AddTodoItem -Description $Description; break; }
            "remove"    { Invoke-RemoveTodoItem -Id $Id; break; }
            "complete"  { Invoke-CompleteTodoItem -Id $Id; break; }
            "set"       { Invoke-SetTodoItem -Id $Id -Status $Status -Description $Description -Url $Url; break; }
            "list"      { Invoke-ListTodoItems -Status $Status; break; }
            "open"      { Invoke-OpenTodoItem -Id $Id; break; }
            "help"      { Write-TodoHelp; break; }
        }
    }
}

Function Invoke-AddTodoItem
{
    param(
        [Parameter(Mandatory)]
        [string] $Description
    )

    $NextId = Get-NextId
    $NewTodoItem = @{
        Id = $NextId
        Description = $Description
        Status = "Pending"
        Url = $Url
    }
    $json = Get-Content -Path $PSScriptRoot\Todo-List.json | ConvertFrom-Json
    $json.items += $NewTodoItem
    $json | ConvertTo-Json | Set-Content -Path $PSScriptRoot\Todo-List.json
}

Function Invoke-RemoveTodoItem
{
    param(
        [Parameter(Mandatory)]
        [string] $Id
    )

    $json = Get-Content -Path $PSScriptRoot\Todo-List.json | ConvertFrom-Json
    $json.items = $json.items | Where-Object { $_.id -ne $Id }
    $json | ConvertTo-Json | Set-Content -Path $PSScriptRoot\Todo-List.json
}

Function Invoke-CompleteTodoItem
{
    param(
        [Parameter(Mandatory)]
        [string] $Id
    )

    $json = Get-Content -Path $PSScriptRoot\Todo-List.json | ConvertFrom-Json
    $json.items | Where-Object { $_.id -eq $Id } | ForEach-Object { $_.status = "Done" }
    $json | ConvertTo-Json | Set-Content -Path $PSScriptRoot\Todo-List.json
}

Function Invoke-SetTodoItem
{
    param(
        [Parameter(Mandatory)]
        [string] $Id,
        [string] $Status,
        [string] $Description,
        [string] $Url
    )

    if(-not($Status) -and -not($Description) -and -not($Url))
    {
        Write-Host "You must specify either a status, a description, or a url to set."
    } else
    {
        $json = Get-Content -Path $PSScriptRoot\Todo-List.json | ConvertFrom-Json
        $json.items | Where-Object { $_.id -eq $Id } | ForEach-Object {
            if ($Status)
            {
                $_.status = $Status
            }
            if ($Description)
            {
                $_.description = $Description
            }
            if ($Url)
            {
                $_.url = $Url
            }
        }
        $json | ConvertTo-Json | Set-Content -Path $PSScriptRoot\Todo-List.json
    }
}

Function Invoke-ListTodoItems
{
    param(
        [ValidateSet("Pending", "Done", "OnHold", "")]
        [string] $Status
    )

    if (-not($Status)) { $Status = "Pending" }

    Get-Content -Raw $PSScriptRoot\Todo-List.json |
        ConvertFrom-Json |
        Select-Object -ExpandProperty "items" |
        Where-Object { $_.status -eq $Status } |
        Format-Table -Property id, description, @{Label="More Info"; Expression={ if ([string]::IsNullOrEmpty($_.Url)) {"No"} else {"Yes"} }}
}

Function Invoke-OpenTodoItem
{
    param(
        [Parameter(Mandatory)]
        [string] $Id
    )
    $Url = Get-Content -Raw $PSScriptRoot\Todo-List.json |
        ConvertFrom-Json |
        Select-Object -ExpandProperty "items" |
        Where-Object { $_.id -eq $Id } |
        Select-Object -ExpandProperty "url"

    if ([string]::IsNullOrEmpty($Url))
    {
        Write-Host "No URL specified for this item."
    } else
    {
        Start-Process $Url
    }
}

Function Get-NextId
{
    $CurrentHighestId = Get-Content -Path $PSScriptRoot\Todo-List.json -Raw |
        ConvertFrom-Json |
        Select-Object -ExpandProperty items |
        Select-Object -ExpandProperty id |
        Measure-Object -Maximum |
        Select-Object -ExpandProperty Maximum

    return $CurrentHighestId + 1
}


Function Write-TodoHelp
{
    Write-Host "----- Todo help section -----" -f "DarkGreen"
    Write-Host "todo add -d <description> -u <url> (optional)" -f "DarkCyan" -n
    Write-Host " - Adds a new todo item with the specified description" -f "white"
    Write-Host "todo remove -i <id>" -f "DarkCyan" -n
    Write-Host " - Removes the todo item with the specified id" -f "white"
    Write-Host "todo complete -i <id>" -f "DarkCyan" -n
    Write-Host " - Marks the todo item with the specified id as complete" -f "white"
    Write-Host "todo set -i <id> -s <status> -d <description>" -f "DarkCyan" -n
    Write-Host " - Sets the status and/or description of the todo item with the specified id" -f "white"
    Write-Host "todo list" -f "DarkCyan" -n
    Write-Host " - Lists all pending todo items" -f "white"
    Write-Host "todo list -s <status>" -f "DarkCyan" -n
    Write-Host " - Lists all todo items with the specified status" -f "white"
    Write-Host "todo open -i <id>" -f "DarkCyan" -n
    Write-Host " - Opens the URL associated with the todo item with the specified id" -f "white"
    Write-Host "todo help" -f "DarkCyan" -n
    Write-Host " - Shows this help section" -f "white"
    Write-Host
    Write-Host "----- Status options -----" -f "DarkGreen"
    Write-Host "Pending, Done, OnHold" -f "DarkCyan"
}

Export-ModuleMember -Function Todo
