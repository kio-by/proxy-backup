
# Set env

$kill_process = '1cv8*'
$project_name = 'b-mega-project'
$proxy_ip = '000.000.000.000'
$rar='C:\Program Files\WinRAR\rar.exe'           # Путь к RAR
$pathBase = 'c:\1c\base'                         # Пути откуда копируем
$pathin = 'c:\Users\user\Documents\backup\'  # Путь куда копируем


# Kill all 1c
Stop-Process -Name $kill_process -Force
timeout /T 03

# Подготовка к архивации
# Аргументы коммандной строки RAR
$rarAr = @('a','-agyyyy-mm-dd','-m5','-dh')
#$rarAr = @('a','-agYYYY-MM-DD','-m5','-dh','-x@D:\Bases\isk.txt')

# Запускаем RAR, копируем архив и ждём полного завершения процесса с помощью | Out-Null
& $rar $rarAr "$pathin" $pathBase | Out-Null

# Copy to server
$name_date = get-date -Format yyyy-MM-dd

scp $pathin$name_date'.rar' $project_name@"$proxy_ip":~/backup/

# Create temp-flag file
ssh $project_name@$proxy_ip "touch ~/backup/.temp-flag/delete.$($name_date)"

# Remove backup file
Remove-Item $pathin$name_date'.rar'
