Set WshShell = CreateObject("WScript.Shell")
Set WshEnv = WshShell.Environment("Process")
WshEnv.Item("HTTPS_PROXY") = "http://127.0.0.1:7890"
WshEnv.Item("HTTP_PROXY") = "http://127.0.0.1:7890"
WshEnv.Item("NO_PROXY") = "localhost,127.0.0.1"
WshShell.Run """C:\Users\username\.local\share\workbuddy-gpt-gemini-bridge\bin\cli-proxy-api.exe"" --config ""C:\Users\dongdong\.cli-proxy-api\config.yaml""", 0, False
