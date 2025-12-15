# Function to optimize and resize images
Add-Type -AssemblyName System.Drawing

function Optimize-Image {
    param (
        [string]$FilePath,
        [int]$Quality = 60,
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
                # Fallback to jpeg if png encoder issues (rare in .NET but possible for basic handling)
                # Actually System.Drawing saves PNG losslessly usually, so 'Quality' param might be ignored for PNG in standard GDI+.
                # For bona.png (profile), if it has no transparency, JPG is better. If it has transparency, we must keep PNG.
                # Let's save as is with the encoder params (GDI+ often ignores quality for PNG).
                # If it's a PNG, we mainly rely on the RESIZE to drop bytes.
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

# 1. Optimize BONA.PNG (Resize is key here!)
# Resizing to 800px width. Even if GDI+ doesn't compress PNG well, reducing pixels from likely 3000+ to 800 will save MBs.
Optimize-Image -FilePath "images/bona.png" -MaxWidth 800

# 2. Optimize Backgrounds (Aggressive compression)
$bgs = Get-ChildItem "images/background-*.jpg"
foreach ($bg in $bgs) {
    Optimize-Image -FilePath $bg.FullName -Quality 60
}

# 3. Optimize Community
Optimize-Image -FilePath "images/community.png" -MaxWidth 1000
