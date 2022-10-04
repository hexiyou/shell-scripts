'Cygwin文件夹不存在时直接跳过，不弹出报错窗口！
Dim Wsh,ScriptPath,CygwinInstallPath,CygwinInstallDrive,BashPath,ArgumentParamter

ArgumentParamter=""

'Wscript.Echo "参数个数：" & Wscript.Arguments.Count
IF Wscript.Arguments.Count >0 Then
	For i=0 To Wscript.Arguments.Count-1 
		ArgumentParamter=ArgumentParamter & Space(1) & Wscript.Arguments(i)
	Next
End If
'Msgbox ArgumentParamter
'Wscript.Quit

Set Fso=CreateObject("Scripting.FileSystemObject")
ScriptPath=Fso.GetFile(Wscript.ScriptFullName).ParentFolder.Path
Set Conf=Fso.OpenTextFile(ScriptPath & "\cygwin_installion_path.txt",1,false)
CygwinInstallPath=Conf.ReadAll()
Set Folder=Fso.GetFolder(CygwinInstallPath)
CygwinInstallDrive=Folder.Drive

BashPath=CygwinInstallDrive & "\cygwin64\bin\bash.exe"

'Wscript.Echo BashPath & " --login -i -c '" & ArgumentParamter & ";bash'"


Set Wsh=CreateObject("Wscript.Shell")
'注意：如果参数中含有中文，则必须在UTF-8的窗口中运行命令，比如在Cygwin窗口中执行 wscript //nologo bash-hide.vbs potplayertv 湖南卫视
'否则会报错，比如原生cmd窗口默认为 chcp 936编码，带中文参数调用此脚本就达不到预期的效果
If Fso.FileExists(BashPath) Then 'Cygwin64 Bash.exe文件路径存在时才执行命令
Wsh.run BashPath & " --login -i -c '" & ArgumentParamter & "'",vbHide
End If

'保持窗口可见，且不自动退出
'Wsh.run BashPath & " --login -i -c '" & ArgumentParamter & ";bash'"