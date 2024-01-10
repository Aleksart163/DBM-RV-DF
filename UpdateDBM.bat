set OWNER=Aleksart163
set REPO=DBM-RV-DF
set BRANCH=main
curl -L -O https://github.com/%OWNER%/%REPO%/archive/refs/heads/%BRANCH%.zip
tar zxf %BRANCH%.zip
del %REPO%-%BRANCH%\README.md
xcopy /c /e /h /r /y /i /k  %REPO%-%BRANCH%\* . && rd /s /q %REPO%-%BRANCH%
del %BRANCH%.zip