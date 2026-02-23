<#
.SYNOPSIS
    Severa – Aplikasi Pemasang dan Peluncur Aplikasi dari GitHub
.DESCRIPTION
    Script ini menyediakan antarmuka untuk memilih dan mengunduh tiga versi aplikasi
    (v3.9, v3.10, v3.10.1) dari GitHub, lalu menjalankannya.
    Dibuat dengan tampilan profesional dan logging aktivitas.
.NOTES
    Nama     : Severa
    Versi    : 1.0
    Penulis  : User
    Dibutuhkan: Koneksi internet dan hak tulis di folder tujuan.
#>

# ======================= KONFIGURASI =======================
# Ganti URL berikut sesuai dengan repository GitHub Anda
$urls = @{
    "v3.9"    = "https://github.com/ArvinPrdn/SEVERA-SEB-patch/releases/download/v3.9/patch-seb.exe"
    "v3.10"   = "https://github.com/ArvinPrdn/SEVERA-SEB-patch/releases/download/v3.10/patch-seb.1.exe"
    "v3.10.1" = "https://github.com/ArvinPrdn/SEVERA-SEB-patch/releases/download/v3.10.1/patch-seb.1.exe"
}

# Nama file lokal (kosongkan untuk menggunakan nama dari URL)
$localFileNames = @{
    "v3.9"    = ""
    "v3.10"   = ""
    "v3.10.1" = ""
}

# Folder penyimpanan unduhan
$downloadFolder = "$env:USERPROFILE\Downloads\Severa"

# Folder untuk log
$logFolder = "$env:USERPROFILE\Severa_Logs"
$logFile = Join-Path $logFolder "severa_$(Get-Date -Format 'yyyyMMdd').log"

# ============================================================

# Fungsi menulis log
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    
    # Tampilkan di konsol dengan warna sesuai level
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }
    
    # Simpan ke file log
    if (-not (Test-Path $logFolder)) {
        New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
    }
    Add-Content -Path $logFile -Value $logEntry
}

# Fungsi menampilkan banner
function Show-Banner {
    Clear-Host
    Write-Host @"
    ╔══════════════════════════════════════════════════════════╗
    ║                                                          ║
    ║   ███████ ███████ ██    ██ ███████ ██████   █████  ██████║
    ║   ██      ██      ██    ██ ██      ██   ██ ██   ██ ██   ██║
    ║   ███████ █████   ██    ██ █████   ██████  ███████ ██   ██║
    ║        ██ ██       ██  ██  ██      ██   ██ ██   ██ ██   ██║
    ║   ███████ ███████   ████   ███████ ██   ██ ██   ██ ██████ ║
    ║                                                          ║
    ║            Pemasang & Peluncur Aplikasi v1.0             ║
    ╚══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    Write-Host ""
    Write-Log "Severa dimulai oleh $env:USERNAME"
}

# Fungsi memeriksa koneksi internet
function Test-InternetConnection {
    try {
        $test = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
        if (-not $test) {
            throw "Tidak ada koneksi internet"
        }
        Write-Log "Koneksi internet tersedia"
        return $true
    }
    catch {
        Write-Log "Tidak ada koneksi internet" -Level "ERROR"
        return $false
    }
}

# Fungsi menampilkan menu
function Show-Menu {
    Write-Host ""
    Write-Host " PILIH VERSI APLIKASI" -ForegroundColor Yellow
    Write-Host " ───────────────────────────"
    Write-Host " [1] v3.9" -ForegroundColor Green
    Write-Host " [2] v3.10" -ForegroundColor Green
    Write-Host " [3] v3.10.1" -ForegroundColor Green
    Write-Host " [Q] Keluar" -ForegroundColor Red
    Write-Host " ───────────────────────────"
}

# Fungsi utama
function Start-Severa {
    Show-Banner
    
    # Cek koneksi
    if (-not (Test-InternetConnection)) {
        Write-Host "Tekan sembarang tombol untuk keluar..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
    
    # Buat folder unduhan jika belum ada
    if (-not (Test-Path $downloadFolder)) {
        New-Item -ItemType Directory -Path $downloadFolder -Force | Out-Null
        Write-Log "Folder unduhan dibuat: $downloadFolder"
    }
    
    do {
        Show-Menu
        $choice = Read-Host "Masukkan pilihan"
        
        switch ($choice) {
            '1' { $selectedVersion = "v3.9"; $valid = $true }
            '2' { $selectedVersion = "v3.10"; $valid = $true }
            '3' { $selectedVersion = "v3.10.1"; $valid = $true }
            'q' { Write-Log "Pengguna keluar dari Severa"; exit }
            default {
                Write-Log "Pilihan '$choice' tidak valid" -Level "WARNING"
                $valid = $false
            }
        }
    } until ($valid)
    
    Write-Log "Versi dipilih: $selectedVersion"
    
    # Tentukan URL dan nama file
    $downloadUrl = $urls[$selectedVersion]
    if ([string]::IsNullOrEmpty($downloadUrl)) {
        Write-Log "URL untuk $selectedVersion tidak ditemukan dalam konfigurasi" -Level "ERROR"
        pause
        exit
    }
    
    $localFileName = $localFileNames[$selectedVersion]
    if ([string]::IsNullOrEmpty($localFileName)) {
        $localFileName = [System.IO.Path]::GetFileName($downloadUrl)
    }
    $localFilePath = Join-Path $downloadFolder $localFileName
    
    Write-Log "Mengunduh dari: $downloadUrl"
    Write-Log "Disimpan ke: $localFilePath"
    
    # Unduh file dengan progress bar
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFileAsync((New-Object Uri($downloadUrl)), $localFilePath)
        
        # Tampilkan progress selama download
        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 500
            if ($webClient.IsBusy) {
                Write-Host "." -NoNewline -ForegroundColor Cyan
            }
        }
        Write-Host ""
        
        if (Test-Path $localFilePath) {
            Write-Log "Unduhan selesai" -Level "SUCCESS"
        } else {
            throw "File tidak ditemukan setelah unduhan"
        }
    }
    catch {
        Write-Log "Gagal mengunduh: $_" -Level "ERROR"
        pause
        exit
    }
    
    # Jalankan file
    try {
        Write-Log "Menjalankan $localFilePath ..."
        $process = Start-Process -FilePath $localFilePath -PassThru
        Write-Log "Aplikasi dimulai dengan Process ID: $($process.Id)" -Level "SUCCESS"
        
        # Tanyakan apakah ingin menunggu aplikasi selesai
        $wait = Read-Host "Tunggu hingga aplikasi ditutup? (Y/N) [Y]"
        if ($wait -eq "" -or $wait -match "^[Yy]") {
            $process | Wait-Process
            Write-Log "Aplikasi selesai"
        }
    }
    catch {
        Write-Log "Gagal menjalankan aplikasi: $_" -Level "ERROR"
    }
    
    Write-Host ""
    Write-Log "Severa selesai. Log tersimpan di: $logFile" -Level "SUCCESS"
    Write-Host "Tekan sembarang tombol untuk menutup..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Jalankan fungsi utama
Start-Severa
