# Function to optimize and resize images
Add-Type -AssemblyName System.Drawing

function Optimize-Image {
    param (
        [string]$FilePath,
        [int]$Quality = 50,
        [int]$MaxWidth = 0
    )

    if (Test-Path $FilePath) {
        Write-Host "Processing $FilePath..."
        $fullPath = Resolve-Path $FilePath
        
        try {
            $img = [System.Drawing.Image]::FromFile($fullPath)
            
            # Resize if MaxWidth is set and image is wider
            if ($MaxWidth -gt 0 -and $img.Width -gt $MaxWidth) {
                $newHeight = [int]($img.Height * ($MaxWidth / $img.Width))
                $newBitmap = New-Object System.Drawing.Bitmap($MaxWidth, $newHeight)
                $graph = [System.Drawing.Graphics]::FromImage($newBitmap)
                $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graph.DrawImage($img, 0, 0, $MaxWidth, $newHeight)
                $img.Dispose()
                $img = $newBitmap
                $graph.Dispose()
                Write-Host "  Resized to width: $MaxWidth"
            }

            # Encoder parameters for compression quality
            $encoder = [System.Drawing.Imaging.Encoder]::Quality
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encoder, $Quality)
            
            # Get Codec
            $ext = [System.IO.Path]::GetExtension($FilePath).ToLower()
            $mime = "image/jpeg"
            if ($ext -eq ".png") { $mime = "image/png" }
            $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq $mime }
            
            if ($null -eq $codec) {
                # Fallback
            }

            # Save to temp file
            $tempPath = "$fullPath.tmp$ext"
            $img.Save($tempPath, $codec, $encoderParams)
            $img.Dispose()
            
            # Replace
            Move-Item -Path $tempPath -Destination $fullPath -Force
            Write-Host "  Saved optimized file."
        }
        catch {
            Write-Host "  Error processing $FilePath : $_"
        }
    }
    else {
        Write-Host "  File not found: $FilePath"
    }
}

# 1. Resize Backgrounds to 1280px (HD ready is enough for web bg usually) and Quality 50
$bgs = Get-ChildItem "images/background-*.jpg"
foreach ($bg in $bgs) {
    Optimize-Image -FilePath $bg.FullName -Quality 50 -MaxWidth 1280
}

# 2. Resize Community to 800px
Optimize-Image -FilePath "images/community.png" -MaxWidth 800 -Quality 60

# 3. Resize bona.png again (just to be sure/consistent) with 60 Quality
Optimize-Image -FilePath "images/bona.png" -MaxWidth 800 -Quality 60
