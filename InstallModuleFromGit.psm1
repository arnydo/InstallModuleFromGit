function Install-ModuleFromGit {
    [CmdletBinding()]
    param(
        $GitRepo,
        $GitType,
        $GitServer,
        $Branch = "master",
        $DestinationPath
    )

    Process {

        if ($GitRepo) {
            Write-Verbose ("[$(Get-Date)] Retrieving {0} {1}" -f $GitRepo, $Branch)

            switch -wildcard ($GitType) {
                'github.com' {
                    $GitServer = "github.com"
                    $url = "https://{0}/{1}/archive/{1}.zip" -f $GitServer, $GitRepo, $Branch}
                'gitlab.com' {
                    $GitServer = "gitlab.com"
                    $url = "https://{0}/{1}/-/archive/{2}/{3}-{4}.zip" -f $GitServer, $GitRepo, $Branch, $GitRepo.Split("/")[-1], $branch
                }
                Default {$url = "https://{0}/{1}/-/archive/{2}/{3}-{4}.zip" -f $GitServer, $GitRepo, $Branch, $GitRepo.Split("/")[-1], $branch}
            }
            $targetModuleName = $GitRepo.split('/')[-1]
            Write-Debug "targetModuleName: $targetModuleName"

            $tmpDir = [System.IO.Path]::GetTempPath()

            $OutFile = Join-Path -Path $tmpDir -ChildPath "$($targetModuleName).zip"
            Write-Debug "OutFile: $OutFile"


            if ($IsLinux -or $IsOSX) {
                Invoke-RestMethod $url -OutFile $OutFile
            }

            else {
                Invoke-RestMethod $url -OutFile $OutFile
                Unblock-File $OutFile
            }

            Expand-Archive -Path $OutFile -DestinationPath $tmpDir -Force

            $unzippedArchive = "$($targetModuleName)-$($Branch)"
            Write-Debug "targetModule: $targetModule"

            if ($IsLinux -or $IsOSX) {
                $dest = Join-Path -Path $HOME -ChildPath ".local/share/powershell/Modules"
            }

            else {
                $dest = "C:\Program Files\WindowsPowerShell\Modules"
            }

            if ($DestinationPath) {
                $dest = $DestinationPath
            }
            $dest = Join-Path -Path $dest -ChildPath $targetModuleName
            Write-Debug "dest: $dest"

            $psd1 = Get-ChildItem (Join-Path -Path $tmpDir -ChildPath $unzippedArchive) -Include *.psd1 -Recurse

            if ($psd1) {
                $ModuleVersion = (Get-Content -Raw $psd1.FullName | Invoke-Expression).ModuleVersion
                $dest = Join-Path -Path $dest -ChildPath $ModuleVersion
            }

            if (!(test-path $dest)){
                Write-warning "Directory [$dest] does not exist. Creating..."
                New-Item -Path $dest -ItemType Directory
            }
            
            $null = Copy-Item "$(Join-Path -Path $tmpDir -ChildPath $unzippedArchive)\*" $dest -Force
        }
    }
}
