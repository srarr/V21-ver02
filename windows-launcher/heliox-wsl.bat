@echo off
:: Heliox ATLAS v21 - Open WSL Terminal with Project

:: Open WSL terminal and run startup script
wsl -e bash -l -c "cd '/mnt/c/New Claude Code/V21 Ver01' && ./start-heliox.sh; exec bash"

:: Alternative if aliases are setup:
:: wsl -e bash -l -c "heliox-start; exec bash"