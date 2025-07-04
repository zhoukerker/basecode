param(
  [string]$fileName,
  [string]$inputFileName,
  [string]$outputFileName
)
# 切换为 utf8
# [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Log {
  param (
    [string]$Message,
    [System.ConsoleColor]$Color = [System.ConsoleColor]::Red
  )
  Write-Host "====== $Message ======" -ForegroundColor $Color
}

# 检查 cr 指令后是否跟着文件名
if (-not $fileName) {
  Write-Log "请在 cr 指令后跟上文件名，如 test.cpp"
  exit 1
}

# 删除 .cpp 后缀
if ($fileName.EndsWith(".cpp")) {
  $fileName = $filename -replace "\.cpp$", ""
}

# 检查cpp文件是否存在
if (-not (Test-Path "$fileName.cpp")) {
  Write-Log "未找到 $fileName.cpp，请查看 VSCode 左侧的资源管理器是否有该程序"
  exit 1
}

$gccOutput = c++ "$fileName.cpp" -o "$fileName.exe" -O2 --std=c++20 -Wall `
                 -fexec-charset=GBK `
                 -fdiagnostics-color=always 2>&1
$exitCode = $LASTEXITCODE
$gccOutput | ForEach-Object { Write-Host $_ }
if ($exitCode -ne 0) {
  if ($gccOutput -match "C:\\Users") {
    Write-Log "用户名不能为中文，请根据说明文件指引进行修改"
    exit 1
  }
  if ($gccOutput -match "WinMain") {
    Write-Log "程序中没有 main 函数，请检查是否保存"
    exit 1
  }
  Write-Log "编译失败，请检查上述语法错误信息后进行修改"
  exit 1
}

if ($gccOutput -match "warning:") {
  Write-Log "上述是警告信息，请检查（如在预期内则可忽略）" Yellow
}
Write-Log "编译成功，开始执行" Green

if ($inputFileName) {
  if (-not(Test-Path $inputFileName)) {
    Write-Log "未找到输入文件 $inputFileName，请查看 VSCode 左侧的资源管理器是否有该文件"
    exit 1
  }
  if ($outputFileName) {
    Get-Content $inputFileName | & "./$fileName.exe" | Out-File "./$outputFileName"
  } else {
    Get-Content $inputFileName | & "./$fileName.exe"
  }
} else {
  & "./$fileName.exe"
}
Write-Log "执行结束，删除可执行程序" Green

Remove-Item "./$fileName.exe"