<#
.SYNOPSIS
    Dotfiles installer for native Windows. (macOS, Linux and WSL use install.sh.)

.DESCRIPTION
    install    link + deps (the default)
    deps       fetch the vim plugins
    link       symlink everything into your profile, backing up what is there
    status     show what is linked, what differs and what is missing
    unlink     remove the symlinks this script created
    packages   install the base packages with winget, then the font
    fonts      install the Hack Nerd Font for the current user
    tour       show TOUR.md, the guide to what this setup includes

    Creating symlinks on Windows needs either Developer Mode
    (Settings > System > For developers) or an elevated PowerShell.

.EXAMPLE
    .\install.ps1
    .\install.ps1 link -DryRun
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('install', 'deps', 'link', 'status', 'unlink', 'packages', 'fonts', 'tour')]
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

# The zsh prompt in WSL draws its icons with a Nerd Font, and Windows Terminal
# takes its fonts from Windows, so the font is installed here and not in WSL.
function Invoke-Fonts {
    if ($env:OS -ne 'Windows_NT') {
        throw 'fonts is for Windows only: use install.sh on macOS and Linux'
    }

    # A per-user install needs no administrator rights: the files go under
    # the user profile and are registered under HKEY_CURRENT_USER.
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $regKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

    if (Get-ChildItem -Path $fontDir -Filter 'HackNerdFont*.ttf' -ErrorAction SilentlyContinue) {
        Say Green 'ok' 'Hack Nerd Font is already installed'
        return
    }

    Say Blue 'fonts' "Hack Nerd Font -> $fontDir"
    if ($DryRun) { return }

    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('hack-nerd-font-' + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $zip = Join-Path $tmp 'Hack.zip'
        # Windows PowerShell 5.1 does not use TLS 1.2 unless told to.
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -UseBasicParsing -OutFile $zip `
            -Uri 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip'
        Expand-Archive -Path $zip -DestinationPath $tmp

        New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
        if (-not (Test-Path $regKey)) { New-Item -Path $regKey -Force | Out-Null }

        foreach ($ttf in Get-ChildItem -Path $tmp -Filter '*.ttf') {
            $dest = Join-Path $fontDir $ttf.Name
            Copy-Item -LiteralPath $ttf.FullName -Destination $dest -Force
            New-ItemProperty -Path $regKey -Name "$($ttf.BaseName) (TrueType)" `
                -Value $dest -PropertyType String -Force | Out-Null
        }
    }
    finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force
    }

    Say Green 'ok' 'restart Windows Terminal, then choose "Hack Nerd Font" under'
    Say Green '' 'Settings > Profiles > Defaults > Appearance > Font face'
}

switch ($Command) {
    'tour'     {
        $tour = Join-Path $Dotfiles 'TOUR.md'
        if ((Get-Command glow -ErrorAction SilentlyContinue) -and -not [Console]::IsOutputRedirected) { glow -p $tour } else { Get-Content $tour }
    }
    'deps'     { Invoke-Deps }
    'packages' { Invoke-Packages; Invoke-Fonts }
    'fonts'    { Invoke-Fonts }
    'status'   { Get-Manifest | ForEach-Object { Invoke-Status $_ } }
    'unlink'   { Get-Manifest | ForEach-Object { Invoke-Unlink $_ } }
    'link'     { Get-Manifest | ForEach-Object { Invoke-Link $_ } }
    'install'  { Get-Manifest | ForEach-Object { Invoke-Link $_ }; Invoke-Deps }
}

if ($script:BackedUp -gt 0) {
    Say Yellow 'note' "$($script:BackedUp) existing item(s) moved to $BackupDir"
}
