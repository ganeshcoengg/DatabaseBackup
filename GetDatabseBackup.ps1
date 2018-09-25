#Start:: Set the default parameters 
try{
    $JsonData = (Get-Content ".\config.json" -Raw)
    $JsonObject = ConvertFrom-Json -InputObject $JsonData -ErrorAction Stop
}
catch {
    Write-Host "Check the Json file" -ForegroundColor Red
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
    param ([String]$logString)
    $time = Get-Date
    $string = '*** ' +$time.ToString() +' == '+ $logString
    Add-Content $logfile -Value $string
}

LogWrite "Start ==> Database Backup Started!"
Function GetDatabaseBackup {
    Param([string] $DBName
    )
    $date = ((Get-Date).ToString('yyyyMMddHHmm'))
    $separater = $date+'_'
    Write-Host "$DBName Backup Started..." -NoNewline
    if($isTriggers.ToUpper() -eq "YES"){
        $ErrorLog = & cmd.exe /c "mysqldump -h $DBServer -u $user $pass --databases $DBName > $Backuppath$separater$DBName.sql"
    }
    else {
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
        LogWrite "ERROR :- $DBName DATABASE BACKUP HAS BEEN FAILED - $ErrorLog !!"
    }
}	

function ConvertToRAR {
    #Set rar path 
    Write-Host "Creating RAR..."
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
        & $rar u -r $Backuppath$FileName.rar $Backuppath$date*$separater*.sql
    }
    catch {
        Write-Host $Backuppath$date*$separater*.sql "Not avaiable" -foregroundcolor Red
    }
}



foreach($AdminDatabaseName in $ADMINDATABASE){		
    GetDatabaseBackup $AdminDatabaseName.ADMIN
}

foreach($SADatabaseName in $SADATABASE){		
    GetDatabaseBackup $SADatabaseName.SA
}

foreach($STDatabaseName in $STDATABASE){
    GetDatabaseBackup $STDatabaseName.ST
}

foreach($SWDatabaseName in $SWDATABASE){
    GetDatabaseBackup $SWDatabaseName.SW
}
ConvertToRAR