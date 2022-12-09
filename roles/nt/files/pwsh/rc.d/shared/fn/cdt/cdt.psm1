function cdt {
  $parent = [System.IO.Path]::GetTempPath()
  [string] $name = [System.Guid]::NewGuid()
  $tmp = Join-Path $parent $name
  New-Item -ItemType Directory -Path $tmp
  cd -- $tmp
}
