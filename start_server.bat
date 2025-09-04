@echo off
setlocal enabledelayedexpansion

chcp 65001 >nul
title Minecraft服务器控制面板

:: by_YC - 服务器启动脚本

set CONFIG_FILE=start_config
set SERVER_JAR=

:: 初始化配置
if not exist "%CONFIG_FILE%" (
    echo JAVA_PATH=java > "%CONFIG_FILE%"
    echo JAVA_OPTS=-Xms2G -Xmx4G >> "%CONFIG_FILE%"
    echo SERVER_JAR= >> "%CONFIG_FILE%"
)

:: 加载配置
for /f "tokens=1,* delims==" %%a in (%CONFIG_FILE%) do (
    set "%%a=%%b"
)

:: 检查Java安装
where java >nul 2>nul
if errorlevel 1 (
    echo 未找到Java安装!
    echo 请安装Java后继续，将打开Java下载页面...
    timeout /t 5 /nobreak >nul
    start "" "https://www.azul.com/downloads/"
    pause
    exit /b 1
)

:: 自动检测服务器核心
echo 正在检测服务器核心...
set "CORE_FOUND=false"
for %%i in (*server*.jar) do (
    if not "%%i"=="" (
        set "SERVER_JAR=%%i"
        set "CORE_FOUND=true"
        echo 找到服务器核心: !SERVER_JAR!
        goto :main_menu
    )
)

:: 如果没有找到核心，显示选择菜单
if "!CORE_FOUND!"=="false" (
    echo 未找到服务器核心文件(包含server字段的jar文件)
    echo.
    echo 请选择要安装的服务器核心:
    echo 注意:请把服务器核心文件名改成server.jar
    echo 1) Vanilla (官方原版)
    echo 2) Paper (高性能)
    echo 3) Spigot (插件支持)
    echo 4) 手动指定核心文件
    echo 5) 退出
    echo.
    set /p "choice=请选择 [1-5]: "
    
    if "!choice!"=="1" (
        echo 请从 https://www.minecraft.net/zh-hans/download/server 下载服务器jar文件并放置于此目录
        pause
        exit /b 1
    )
    if "!choice!"=="2" (
        start "" "https://papermc.io/downloads"
        echo 请下载Paper服务器jar文件并放置于此目录
        pause
        exit /b 1
    )
    if "!choice!"=="3" (
        start "" "https://www.spigotmc.org/wiki/spigot-installation/"
        echo 请下载Spigot服务器jar文件并放置于此目录
        pause
        exit /b 1
    )
    if "!choice!"=="4" (
        set /p "custom_core=请输入服务器核心文件名: "
        if exist "!custom_core!" (
            set "SERVER_JAR=!custom_core!"
            echo SERVER_JAR=!SERVER_JAR!>> "%CONFIG_FILE%"
            goto :main_menu
        ) else (
            echo 文件不存在: !custom_core!
            pause
            exit /b 1
        )
    )
    if "!choice!"=="5" (
        exit /b 0
    )
)

:main_menu
:: 更新配置文件中的服务器核心路径
if not "%SERVER_JAR%"=="" (
    echo SERVER_JAR=%SERVER_JAR%>> "%CONFIG_FILE%"
)

cls
echo =========================================
echo    Minecraft服务器控制面板
echo =========================================
echo a)—启动服务器
echo b)—检查Java版本
echo c—关闭脚本
echo =========================================

:: 检查服务器是否正在运行
set "server_running=false"
for /f "tokens=2 delims= " %%i in ('tasklist /fi "imagename eq java.exe" /fo table /nh ^| find /i "java.exe"') do (
    set "server_running=true"
)

if "!server_running!"=="true" (
    echo 当前状态: 运行中
) else (
    echo 当前状态: 已停止
)

echo 服务器核心: %SERVER_JAR%
echo Java路径: %JAVA_PATH%
echo 内存设置: %JAVA_OPTS%
echo =========================================

set /p "choice=请选择操作 [a-c]: "

if /i "!choice!"=="a" goto :option_a
if /i "!choice!"=="b" goto :option_b
if /i "!choice!"=="c" goto :option_c

echo 无效选择，请重新输入
timeout /t 2 /nobreak >nul
goto :main_menu

:option_a
echo 启动服务器...
call :start_server
goto :main_menu

:option_b
echo 正在检查Java版本...
%JAVA_PATH% -version 2>&1
echo.
echo Java路径: %JAVA_PATH%
pause
goto :main_menu

:option_c
echo 关闭脚本...
exit /b 0

:start_server
:: 检查服务器核心是否存在
if not exist "%SERVER_JAR%" (
    echo 错误: 服务器核心文件不存在 - %SERVER_JAR%
    pause
    exit /b 1
)

:: 检查服务器是否已经在运行
tasklist /fi "imagename eq java.exe" | find /i "java.exe" >nul
if not errorlevel 1 (
    echo 服务器已经在运行中!
    pause
    exit /b 1
)

:: 启动服务器
echo 正在启动Minecraft服务器...
echo 使用核心: %SERVER_JAR%
echo Java参数: %JAVA_OPTS%

start "Minecraft Server" %JAVA_PATH% %JAVA_OPTS% -jar "%SERVER_JAR%" nogui

:: 检测EULA文件
echo 正在检测EULA文件...
:eula_check
if not exist "eula.txt" (
    timeout /t 3 /nobreak >nul
    goto :eula_check
)

:: 检查eula.txt内容
set "eula_accepted=false"
set "line_number=0"
for /f "usebackq delims=" %%i in ("eula.txt") do (
    set /a "line_number+=1"
    if !line_number! equ 3 (
        if "%%i"=="eula=false" (
            set "eula_accepted=false"
        ) else if "%%i"=="eula=true" (
            set "eula_accepted=true"
        )
    )
)

if "!eula_accepted!"=="false" (
    echo 检测到eula=false，正在自动同意EULA...
    (for /f "tokens=1* delims=:" %%a in ('findstr /n "^" "eula.txt"') do (
        if "%%a"=="3" (
            echo eula=true
        ) else (
            echo(%%b
        )
    )) > "%temp%\eula_new.txt"
    move /y "%temp%\eula_new.txt" "eula.txt" >nul
    echo 已同意EULA(eula=true)
)

:: 启动服务器
echo 正在启动Minecraft服务器...
echo 使用核心: %SERVER_JAR%
echo Java参数: %JAVA_OPTS%

start "Minecraft Server" %JAVA_PATH% %JAVA_OPTS% -jar "%SERVER_JAR%" nogui

echo 服务器已启动!
echo 注意: 您需要在服务器控制台中输入 'stop' 来正常关闭服务器
pause
goto :eof
