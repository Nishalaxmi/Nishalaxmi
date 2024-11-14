param([string] $currentVersion = 'v0.0.0', [string] $previousVersion = 'v0.0.1')
$projectName = "Caresoft";
$repoName = "eureka";
$awsPath = "891150219266.dkr.ecr.eu-west-1.amazonaws.com";
$env:AWS_PROFILE="eureka"
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $awsPath
$currentPath = Get-Location

$dockerApiImages = @{
	EurekaHubApi = "$repoName/eureka-crp-hub-api-service";
	EurekaViewerApi = "$repoName/eureka-crp-viewer-api-service";
}

$dockerUIImages = @{
	EurekaUI = "$repoName/eureka-crp-hub-ui-service";
	EurekaViewerUI = "$repoName/eureka-crp-viewer-ui-service";
}

$apiProjects = @{
    EurekaHubApi = "apps/hub-api-service";
	EurekaViewerApi = "apps/viewer-api-service";
}

$uiProjects = @{
	EurekaUI = "eureka-crp-hub-ui";
	EurekaViewerUI = "eureka-crp-viewer-ui";
}

Write-Host "**********Building API Docker Images...**********"
foreach ($project in $apiProjects.Keys) {
	$path = $apiProjects[$project];
	$imageName = $dockerApiImages[$project];
	Set-Location "../backend"
	$imagePath = Get-Location
	Write-Host "********** Build api image from $imagePath path **********"
	docker build -f $path/dockerfile -t $imageName .
	Set-Location $currentPath
}
Write-Host "Building API Docker Images...Done"


Write-Host "**********Building UI Projects...**********"
Set-Location "../frontend"
If (Test-Path 'dist') {
		Remove-Item 'dist' -Recurse
}
foreach ($project in $uiProjects.Keys) {
	$path = $uiProjects[$project];
	Set-Location "../frontend"
	npm install
    npm run ng-high-memory build $path
	Set-Location $currentPath
}
Set-Location $currentPath
Write-Host "**********Building UI Projects...Done**********"

Write-Host "**********Building UI Docker Images...**********"
foreach ($project in $uiProjects.Keys) {
	$path = $uiProjects[$project];
	$imageName = $dockerUIImages[$project];
	Set-Location "../frontend"
	$imagePath = Get-Location
	Write-Host "********** Build ui image from $imagePath path **********"
	docker build -t $imageName --build-arg APP=$path .
	Set-Location $currentPath
}
Write-Host "**********Building UI Docker Images...Done**********"

Write-Host "**********Publishing API Docker Images for version $currentVersion...**********"
foreach ($project in $dockerApiImages.Keys) {
    $imageName = $dockerApiImages[$project];
    docker tag $imageName ${awsPath}/${imageName}:${currentVersion}
    docker push ${awsPath}/${imageName}:${currentVersion}
}
Write-Host "**********Publishing API Docker Images for version $currentVersion...Done**********"

Write-Host "**********Publishing UI Docker Images for version $currentVersion...**********"
foreach ($project in $dockerUIImages.Keys) {
    $imageName = $dockerUIImages[$project];
    docker tag $imageName ${awsPath}/${imageName}:${currentVersion}
    docker push ${awsPath}/${imageName}:${currentVersion}
}
Write-Host "**********Publishing UI Docker Images for version $currentVersion...Done**********"
