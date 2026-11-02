# Windows-only file-format export. No generation, resizing, cropping, or visual edits.
# Each source must be fully opaque. Every decoded RGB pixel is verified after export.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$codecSource = @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public static class SporklePngEncoding {
  public static void Export(string source, string destination) {
    if (File.Exists(destination)) throw new IOException("Output exists; do not overwrite.");
    using (var input = new Bitmap(source)) {
      var rect = new Rectangle(0, 0, input.Width, input.Height);
      var data = input.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      try {
        var row = new byte[input.Width * 4];
        for (int y = 0; y < input.Height; y++) {
          Marshal.Copy(IntPtr.Add(data.Scan0, y * data.Stride), row, 0, row.Length);
          for (int x = 3; x < row.Length; x += 4)
            if (row[x] != 255) throw new InvalidDataException("Non-opaque source; manual review required.");
        }
      } finally { input.UnlockBits(data); }
      using (var output = new Bitmap(input.Width, input.Height, PixelFormat.Format24bppRgb)) {
        var original = input.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var target = output.LockBits(rect, ImageLockMode.WriteOnly, PixelFormat.Format24bppRgb);
        try {
          var from = new byte[input.Width * 4]; var to = new byte[input.Width * 3];
          for (int y = 0; y < input.Height; y++) {
            Marshal.Copy(IntPtr.Add(original.Scan0, y * original.Stride), from, 0, from.Length);
            for (int x = 0; x < input.Width; x++) {
              to[x*3] = from[x*4]; to[x*3+1] = from[x*4+1]; to[x*3+2] = from[x*4+2];
            }
            Marshal.Copy(to, 0, IntPtr.Add(target.Scan0, y * target.Stride), to.Length);
          }
        } finally { input.UnlockBits(original); output.UnlockBits(target); }
        output.Save(destination, ImageFormat.Png);
      }
      using (var saved = new Bitmap(destination)) {
        if (saved.Width != input.Width || saved.Height != input.Height)
          throw new InvalidDataException("Dimensions changed.");
        var before = input.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        var after = saved.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try {
          var a = new byte[input.Width * 4]; var b = new byte[a.Length];
          for (int y = 0; y < input.Height; y++) {
            Marshal.Copy(IntPtr.Add(before.Scan0, y * before.Stride), a, 0, a.Length);
            Marshal.Copy(IntPtr.Add(after.Scan0, y * after.Stride), b, 0, b.Length);
            for (int x = 0; x < a.Length; x += 4)
              if (a[x] != b[x] || a[x+1] != b[x+1] || a[x+2] != b[x+2] || b[x+3] != 255)
                throw new InvalidDataException("Decoded RGB pixels changed.");
          }
        } finally { input.UnlockBits(before); saved.UnlockBits(after); }
      }
    }
    if (File.ReadAllBytes(destination)[25] != 2)
      throw new InvalidDataException("Output is not PNG truecolor RGB.");
  }
}
'@
Add-Type -TypeDefinition $codecSource -ReferencedAssemblies @(
    [System.Drawing.Bitmap].Assembly.Location,
    [System.Drawing.Rectangle].Assembly.Location,
    ([Reflection.Assembly]::Load('System.Private.Windows.GdiPlus')).Location,
    ([Reflection.Assembly]::Load('System.Private.Windows.Core')).Location,
    'System.Runtime', 'System.Runtime.InteropServices'
)
$exports = @(
    @{Source='And.png'; Output='feature-graphic/feature-1024x500-rgb.png'},
    @{Source='Iphone-4.png'; Output='phone-candidates/01-home.png'},
    @{Source='Iphone-4-1.png'; Output='phone-candidates/02.png'},
    @{Source='Iphone-4-2.png'; Output='phone-candidates/03.png'},
    @{Source='Iphone-4-3.png'; Output='phone-candidates/04-growth.png'},
    @{Source='Iphone-4-4.png'; Output='phone-candidates/05.png'},
    @{Source='Iphone-4-5.png'; Output='phone-candidates/06.png'},
    @{Source='Iphone-4-6.png'; Output='phone-candidates/07.png'}
)
$report = foreach ($item in $exports) {
    $source = Join-Path $PSScriptRoot ('originals/' + $item.Source)
    $destination = Join-Path $PSScriptRoot ('exports/' + $item.Output)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    [SporklePngEncoding]::Export($source, $destination)
    $header = [IO.File]::ReadAllBytes($destination)
    [pscustomobject]@{
        Source=$item.Source; Output=('exports/' + $item.Output)
        Width=[Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($header,16))
        Height=[Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($header,20))
        PNGColorType=$header[25]; IdenticalRGBPixels=$true
        SourceSHA256=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        OutputSHA256=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
    }
}
$report | Export-Csv -LiteralPath (Join-Path $PSScriptRoot 'encoding-report.csv') -NoTypeInformation -Encoding utf8
$report | Format-Table Source,Width,Height,PNGColorType,IdenticalRGBPixels -AutoSize
