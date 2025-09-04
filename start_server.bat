@echo off
setlocal enabledelayedexpansion

chcp 65001 >nul
title Minecraft服务器控制面板

set CONFIG_FILE=server.conf
set SERVER_JAR=
set RESTART_COUNT=0
set MAX_RESTARTS=0

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
:check_java
where java >nul 2>nul
if errorlevel 1 (
    echo 未找到Java安装!
    echo 请安装Java后继续，将打开Java下载页面...
    timeout /t 5 /nobreak >nul
    start "" "https://www.azul.com/downloads/"
    pause
    goto check_java
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
echo a) 启动服务器 (单次运行)
echo b) 启动服务器 (带自动重启)
echo c) 检查Java版本
echo d) 关闭脚本
echo =========================================
echo 服务器核心: %SERVER_JAR%
echo Java路径: %JAVA_PATH%
echo 内存设置: %JAVA_OPTS%
echo =========================================

set /p "choice=请选择操作 [a-d]: "

if "!choice!"=="a" goto :option_a
if "!choice!"=="A" goto :option_a
if "!choice!"=="b" goto :option_b
if "!choice!"=="B" goto :option_b
if "!choice!"=="c" goto :option_c
if "!choice!"=="C" goto :option_c
if "!choice!"=="d" goto :option_d
if "!choice!"=="D" goto :option_d

echo 无效选择，请重新输入
timeout /t 2 /nobreak >nul
goto :main_menu

:option_a
echo 启动服务器 (单次运行)...
set MAX_RESTARTS=0
call :start_server
pause
goto :main_menu

:option_b
set /p "MAX_RESTARTS=请输入最大重启次数: "
echo 启动服务器 (最多重启 !MAX_RESTARTS! 次)...
set RESTART_COUNT=0
call :start_server
pause
goto :main_menu

:option_c
call :check_java_version
pause
goto :main_menu

:option_d
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
set "server_running=false"
for /f "tokens=2 delims= " %%i in ('tasklist /fi "imagename eq java.exe" /fo table /nh ^| find /i "java.exe"') do (
    set "server_running=true"
)

if "!server_running!"=="true" (
    echo 服务器已经在运行中!
    pause
    exit /b 1
)

echo 正在启动Minecraft服务器...
echo 使用核心: %SERVER_JAR%
echo Java参数: %JAVA_OPTS%

:: 启动服务器
start "Minecraft Server" %JAVA_PATH% %JAVA_OPTS% -jar "%SERVER_JAR%" nogui

echo 服务器已启动，请查看服务器窗口...
timeout /t 3 /nobreak >nul

:: 如果设置了重启次数，则进入监控循环
if !MAX_RESTARTS! gtr 0 (
    :monitor_loop
    timeout /t 5 /nobreak >nul
    
    :: 检查服务器是否仍在运行
    set "server_running=false"
    for /f "tokens=2 delims= " %%i in ('tasklist /fi "imagename eq java.exe" /fo table /nh ^| find /i "java.exe"') do (
        set "server_running=true"
    )
    
    if "!server_running!"=="false" (
        echo 服务器已停止运行
        set /a RESTART_COUNT+=1
        
        if !RESTART_COUNT! leq !MAX_RESTARTS! (
            echo 正在重启服务器 (!RESTART_COUNT!/!MAX_RESTARTS!)...
            title Minecraft服务器 - 重启中 (!RESTART_COUNT!/!MAX_RESTARTS!)
            start "Minecraft Server" %JAVA_PATH% %JAVA_OPTS% -jar "%SERVER_JAR%" nogui
            goto :monitor_loop
        ) else (
            echo 已达到最大重启次数 (!MAX_RESTARTS!)
            title Minecraft服务器 - 已停止 (达到最大重启次数)
        )
    ) else (
        title Minecraft服务器 - 运行中 (!RESTART_COUNT!/!MAX_RESTARTS! 次重启)
        goto :monitor_loop
    )
)

:: 恢复默认标题
title Minecraft服务器控制面板
goto :eof

:check_java_version
echo 正在检查Java版本...
%JAVA_PATH% -version 2>&1 | findstr /i "version"
echo Java路径: %JAVA_PATH%
goto :eof
