#Start:: Set the default parameters 
try{
    $JsonData = (Get-Content ".\config.json" -Raw)
    $JsonObject = ConvertFrom-Json -InputObject $JsonData -ErrorAction Stop
}
catch {
    Write-Host "Please correct Json file parameters." -ForegroundColor Red
    Exit-PSSession
}

$ADMINDATABASE = $JsonObject.ADMINDB
$SADATABASE = $JsonObject.SADB
$STDATABASE = $JsonObject.STDB
$SWDATABASE = $JsonObject.SWDB
$BackupPath	= $JsonObject.DatabaseBackupPath.Path	
$HostName = $JsonObject.MySQLServer
$password = $JsonObject.MySQLPassword
$userName = $JsonObject.MySQLUserName
$logpath = Get-Location
$logfile = $logpath.Path+"\"+((Get-Date).ToString('MMdd'))+'DatabaseBackupLogs.txt'
$isTriggers = $JsonObject.WithTrigger.isTrigger
$user = $userName.UserName
$pw = $password.Password
$pass = "-p$pw"
$DBServer = $HostName.DBHost

# Validation of Input 
# 1. Check Json file is Error free
# 2. Test the Database path is configured or not
# 3. Test given "WithTrigger" value is  right or not

function LogWrite {
    param ([String]$logString,
    [bool] $iserror = $false)
    $time = Get-Date
    if($iserror){
        $string = '*** ' +$time.ToString() +' == ERROR == '+ $logString
    }
    else{
        $string = '*** ' +$time.ToString() +' == '+ $logString
    }
    Add-Content $logfile -Value $string
}

LogWrite "Database Backup Started!"
Function GetDatabaseBackup {
    Param([string] $DBName
    )
    $date = ((Get-Date).ToString('yyyyMMddHHmm'))
    $separater = $date+'_'
    Write-Host "$DBName Backup Started..." -NoNewline
    if($isTriggers.ToUpper() -eq "YES"){
        LogWrite "$DBName Backup Started with Triggers"
        $ErrorLog = & cmd.exe /c "mysqldump -h $DBServer -u $user $pass --databases $DBName > $Backuppath$separater$DBName.sql"
    }
    else {
        LogWrite "$DBName Backup Started without Triggers"
        $ErrorLog = & cmd.exe /c "mysqldump -h $DBServer -u $user $pass --databases $DBName --skip-triggers > $Backuppath$separater$DBName.sql"
    }

    #check status
    if ($?){
        Write-Host "Completed!!" -ForegroundColor Green
        LogWrite "$DBName Seployment database backup successfully completed!!"
    }
    else{
        $ErrorLog= $Error[0].Exception.Message 
        Write-Host "$DBName DATABASE BACKUP FAILED" -ForegroundColor Red
        LogWrite "$DBName DATABASE BACKUP HAS BEEN FAILED - $ErrorLog !!" $true
    }
}

function ConvertToRAR {
    #Set rar path 
    Write-Host "Creating RAR..."
    LogWrite "Creating RAR..."
    try{
        if (Test-Path -path  "C:\Program Files (x86)\WinRAR\Rar.exe"){
            $rar = "C:\Program Files (x86)\WinRAR\Rar.exe"
        }
        else{
            $rar = "C:\Program Files\WinRAR\Rar.exe"
        }
        $filedate = ((Get-Date).ToString('yyyyMMddHHmm'))
        $FileName = "mysqldumpIndiDB_$filedate"
        $date = ((Get-Date).ToString('yyyyMMdd'))
        $separater = "_"
        $dirInfo = Get-ChildItem $BackupPath
        if($dirinfo.Length -eq 0){
            LogWrite "File not founnd" True
            throw [System.IO.FileNotFoundException] "File not founnd"           #throw an exception if sql file not created for rar 
        }
        else{
            & $rar u -r $Backuppath$FileName.rar $Backuppath$date*$separater*.sql
        }
    }
    catch [System.IO.FileNotFoundException]{
        Write-Host "Database sql file not avaiable for Rar" -foregroundcolor Red
        LogWrite "Database sql file not avaiable for Rar" $true
    }
    catch{
        Write-Host "An Error has occured!"
        LogWrite "An Error has Occured! System Error." $true
    }
}

foreach($AdminDatabaseName in $ADMINDATABASE){	
    $admindatabase = $AdminDatabaseName.ADMIN
    LogWrite "$admindatabase database Back Starting..."	
    GetDatabaseBackup $admindatabase
}

foreach($SADatabaseName in $SADATABASE){
    $sadatabase = $SADatabaseName.SA
    LogWrite "$sadatabase database Back Starting..."	
    GetDatabaseBackup $sadatabase
}

foreach($STDatabaseName in $STDATABASE){
    $stdatabase = $STDatabaseName.ST
    LogWrite "$stdatabase database Back Starting..."	
    GetDatabaseBackup $stdatabase
}

foreach($SWDatabaseName in $SWDATABASE){
    $swdatabase = $SWDatabaseName.SW
    LogWrite "$swdatabase database Back Starting..."	
    GetDatabaseBackup $swdatabase
}
ConvertToRAR