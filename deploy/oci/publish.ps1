param(
    [ValidateSet("linux-x64", "linux-arm64")]
    [string]$Runtime = "linux-x64",
    [string]$SshTarget = $env:DOOJA_SSH,
    [string]$PublicHost = $env:DOOJA_PUBLIC_HOST
)

$ErrorActionPreference = "Stop"
$repo = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$project = Join-Path $repo "dashboard\src\Dooja.Web\Dooja.Web.csproj"
$out = Join-Path $repo "dashboard\artifacts\oci-publish"

if (Test-Path $out) { Remove-Item -Recurse -Force $out }
dotnet publish $project -c Release -r $Runtime --self-contained false -o $out
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed." }

Copy-Item (Join-Path $PSScriptRoot "*.sh") $out
Copy-Item (Join-Path $PSScriptRoot "dooja.service") $out
Copy-Item (Join-Path $PSScriptRoot "nginx-dooja.conf") $out
Copy-Item (Join-Path $PSScriptRoot "nginx-dooja-https.conf") $out

Write-Host "Published to $out for $Runtime."

if ([string]::IsNullOrWhiteSpace($SshTarget)) {
    Write-Host "DOOJA_SSH is empty. Copy the folder to the server, then run install-server.sh there."
    exit 0
}
if ([string]::IsNullOrWhiteSpace($PublicHost)) {
    throw "Set DOOJA_PUBLIC_HOST before uploading."
}

ssh $SshTarget "rm -rf /tmp/dooja-publish && mkdir -p /tmp/dooja-publish"
scp -r "$out\*" "${SshTarget}:/tmp/dooja-publish/"
ssh $SshTarget "DOOJA_PUBLIC_HOST='$PublicHost' bash /tmp/dooja-publish/install-server.sh /tmp/dooja-publish"
