<#
.SYNOPSIS
    Dotfiles installer for native Windows. (macOS, Linux and WSL use install.sh.)

.DESCRIPTION
    install    link + deps (the default)
    deps       fetch the vim plugins
    link       symlink everything into your profile, backing up what is there
    status     show what is linked, what differs and what is missing
    unlink     remove the symlinks this script created
    packages   install the base packages with winget

    Creating symlinks on Windows needs either Developer Mode
    (Settings > System > For developers) or an elevated PowerShell.

.EXAMPLE
    .\install.ps1
    .\install.ps1 link -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('install', 'deps', 'link', 'status', 'unlink', 'packages')]
    [string]$Command = 'install',

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$Dotfiles = $PSScriptRoot
$BackupDir = Join-Path (Join-Path $HOME '.dotfiles-backup') (Get-Date -Format 'yyyyMMdd-HHmmss')
$script:BackedUp = 0

function Say([string]$Color, [string]$Tag, [string]$Message) {
    Write-Host ('{0,-8} ' -f $Tag) -ForegroundColor $Color -NoNewline
    Write-Host $Message
}

# Every file this repo manages on Windows: path in repo -> path on disk.
# Vim on Windows reads _vimrc and vimfiles instead of .vimrc and .vim.
function Get-Manifest {
    $entries = @(
        @{ Src = '.gitconfig'; Dst = Join-Path $HOME '.gitconfig' }
        @{ Src = '.vimrc';     Dst = Join-Path $HOME '_vimrc' }
        @{ Src = '.vim';       Dst = Join-Path $HOME 'vimfiles' }
    )

    if ($env:APPDATA) {
        $codeDir = Join-Path (Join-Path $env:APPDATA 'Code') 'User'
        if ((Test-Path $codeDir) -or (Get-Command code -ErrorAction SilentlyContinue)) {
            $entries += @(
                @{ Src = 'vscode/settings.json'; Dst = Join-Path $codeDir 'settings.json' }
                @{ Src = 'vscode/snippets/global.code-snippets'; Dst = Join-Path (Join-Path $codeDir 'snippets') 'global.code-snippets' }
                @{ Src = 'vscode/colors/helix-theme'; Dst = Join-Path (Join-Path (Join-Path $HOME '.vscode') 'extensions') 'helix-theme' }
            )
        }
        else {
            Say Blue 'skip' 'VS Code not found, leaving its settings alone'
        }
    }

    foreach ($e in $entries) {
        $e.Src = Join-Path $Dotfiles $e.Src
        $e
    }
}

# $null when the path does not exist; unlike Test-Path this also finds broken links.
function Get-Entry([string]$Path) {
    Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}

function Test-OurLink([string]$Src, [string]$Dst) {
    $item = Get-Entry $Dst
    if (-not $item -or $item.LinkType -ne 'SymbolicLink') { return $false }
    # .Target is a string in PowerShell 7 and a string[] in Windows PowerShell 5.1
    $target = @($item.Target)[0]
    return [IO.Path]::GetFullPath($target) -eq [IO.Path]::GetFullPath($Src)
}

function New-Link([string]$Src, [string]$Dst) {
    try {
        New-Item -ItemType SymbolicLink -Path $Dst -Target $Src | Out-Null
        return
    }
    catch {
        # Windows PowerShell 5.1 ignores Developer Mode; mklink honours it.
        if ($env:OS -ne 'Windows_NT') { throw }
    }

    $flag = if (Test-Path -LiteralPath $Src -PathType Container) { '/D' } else { '' }
    cmd /c "mklink $flag `"$Dst`" `"$Src`"" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create a symlink at $Dst. Turn on Developer Mode (Settings > System > For developers) or run PowerShell as Administrator."
    }
}

function Invoke-Link($e) {
    if (Test-OurLink $e.Src $e.Dst) {
        Say Green 'ok' $e.Dst
        return
    }

    # Anything already there is moved aside, never deleted.
    if (Get-Entry $e.Dst) {
        $relative = $e.Dst.Substring($HOME.Length).TrimStart('\', '/')
        $backup = Join-Path $BackupDir $relative
        Say Yellow 'backup' "$($e.Dst) -> $backup"
        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path (Split-Path $backup) | Out-Null
            Move-Item -LiteralPath $e.Dst -Destination $backup
        }
        $script:BackedUp++
    }

    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path (Split-Path $e.Dst) | Out-Null
        New-Link $e.Src $e.Dst
    }
    Say Green 'link' "$($e.Dst) -> $($e.Src)"
}

function Invoke-Status($e) {
    $item = Get-Entry $e.Dst
    if (Test-OurLink $e.Src $e.Dst) {
        Say Green 'linked' $e.Dst
        return
    }

    if (-not $item) {
        Say Yellow 'missing' $e.Dst
    }
    elseif ($item.LinkType) {
        Say Yellow 'foreign' "$($e.Dst) is a link to $(@($item.Target)[0])"
    }
    else {
        Say Yellow 'copy' "$($e.Dst) is a copy, not a link"
    }
}

function Invoke-Unlink($e) {
    if (Test-OurLink $e.Src $e.Dst) {
        if (-not $DryRun) {
            # .Delete() removes the link itself and never follows it into the repo.
            (Get-Entry $e.Dst).Delete()
        }
        Say Green 'unlink' $e.Dst
    }
    else {
        Say Blue 'skip' "$($e.Dst) is not one of our links"
    }
}

function Invoke-Deps {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'git is required: winget install Git.Git'
    }

    # vim-plug reads the plugin list from _vimrc, so that has to be linked first.
    $vimrc = Join-Path $HOME '_vimrc'
    if (-not (Get-Command vim -ErrorAction SilentlyContinue)) {
        Say Yellow 'note' 'vim is not on PATH: open Vim and run :PlugInstall'
    }
    elseif (-not (Test-OurLink (Join-Path $Dotfiles '.vimrc') $vimrc)) {
        Say Yellow 'note' "$vimrc is not linked yet: run link first, then deps"
    }
    else {
        Say Blue 'deps' 'vim plugins (vim-plug)'
        if (-not $DryRun) {
            vim -es -u $vimrc -i NONE -c 'PlugInstall --sync' -c 'qa'
        }
    }
}

function Invoke-Packages {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget is not available: install "App Installer" from the Microsoft Store'
    }
    $ids = Get-Content (Join-Path (Join-Path $Dotfiles 'packages') 'winget.txt') |
        Where-Object { $_ -and $_ -notmatch '^\s*#' }
    foreach ($id in $ids) {
        Say Blue 'install' $id
        if (-not $DryRun) {
            winget install --exact --id $id --accept-source-agreements --accept-package-agreements
        }
    }
}

switch ($Command) {
    'deps'     { Invoke-Deps }
    'packages' { Invoke-Packages }
    'status'   { Get-Manifest | ForEach-Object { Invoke-Status $_ } }
    'unlink'   { Get-Manifest | ForEach-Object { Invoke-Unlink $_ } }
    'link'     { Get-Manifest | ForEach-Object { Invoke-Link $_ } }
    'install'  { Get-Manifest | ForEach-Object { Invoke-Link $_ }; Invoke-Deps }
}

if ($script:BackedUp -gt 0) {
    Say Yellow 'note' "$($script:BackedUp) existing item(s) moved to $BackupDir"
}
