param([string] $solutionPath, 
      [string] $packagetype,
      [string] $regex,
	  [string] $replaceWith,
	  [string] $outputSolutionPath = $null)

$solutionPackagerPath = ".\PSModules\Tools\CoreTools\SolutionPackager.exe"
$toolsVersion = "9.1.0.49"

function replaceInFile($file, $regex, $replaceWith)
{
   $content = Get-Content $file -Encoding:utf8
   $content = $content -replace $regex, $replaceWith
   
   $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
   [System.IO.File]::WriteAllLines($file, $content, $Utf8NoBomEncoding)

   #Set-Content -Path $file -Value $content -Encoding:UTF8NoBOM 
}

function initializeLocation()
{
	if (!(Test-Path -Path ".\PSModules")) {
	  New-Item -ItemType "directory" -Path ".\PSModules"
	}

	#Get nuget
	$sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
	$targetNugetExe = ".\nuget.exe"

	if (!(Test-Path -Path $solutionPackagerPath)) {
	    cd .\PSModules
		
		if (!(Test-Path -Path $targetNugetExe)) {
		  Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe 
		}
		Set-Alias nuget $targetNugetExe -Scope Global 
		
		./nuget install  Microsoft.CrmSdk.CoreTools -Version $toolsVersion -O .\Tools
		md .\Tools\CoreTools
		$coreToolsFolder = Get-ChildItem ./Tools | Where-Object {$_.Name -match 'Microsoft.CrmSdk.CoreTools.'}
		move .\Tools\$coreToolsFolder\content\bin\coretools\*.* .\Tools\CoreTools
		Remove-Item .\Tools\$coreToolsFolder -Force -Recurse
		Remove-Item nuget.exe
		
		cd ..
	}
}

if(!$outputSolutionPath) {
   $outputSolutionPath = $solutionPath
}

initializeLocation

if (Test-Path -Path ".\tempSolution")
{
    Remove-Item ".\tempSolution" -Recurse
}
Write-Host "Extracting..."
Start-Process -FilePath "$solutionPackagerPath" -Wait  -ArgumentList " /action:Extract /folder:tempSolution  /zipfile:`"$solutionPath`""
Write-Host "Processing..."
Get-ChildItem -Path ".\tempSolution" -File -Recurse | % { replaceInFile $_.FullName $regex $replaceWith} 
Write-Host "Packing..."
Start-Process -FilePath "$solutionPackagerPath" -Wait  -ArgumentList " /action:Pack /folder:tempSolution  /zipfile:`"$outputSolutionPath`""
    
   
   




