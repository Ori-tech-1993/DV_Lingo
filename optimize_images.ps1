# Function to optimize images
Add-Type -AssemblyName System.Drawing

$images = @(
    "images/background-02-1920x750.jpg",
    "images/background-03-1920x750.jpg"
)

foreach ($relativePath in $images) {
    $fullPath = Join-Path $PWD $relativePath
    if (Test-Path $fullPath) {
        Write-Host "Optimizing $relativePath..."
        
        # Load image
        $img = [System.Drawing.Image]::FromFile($fullPath)
        
        # Encoder parameters for compression quality
        $encoder = [System.Drawing.Imaging.Encoder]::Quality
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encoder, 70) # 70% Quality
        
        # Get JPEG codec
        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
        
        # Save to temp file
        $tempPath = $fullPath + ".tmp.jpg"
        $img.Save($tempPath, $codec, $encoderParams)
        $img.Dispose()
        
        # Replace original
        Move-Item -Path $tempPath -Destination $fullPath -Force
        Write-Host "Optimized $relativePath"
    } else {
        Write-Host "File not found: $relativePath"
    }
}
