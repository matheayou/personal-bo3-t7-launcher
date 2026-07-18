; T7Launcher.iss
; Compile this file in Inno Setup to generate a professional setup wizard.

[Setup]
AppName=T7 Patch Launcher
AppVersion=3.03
DefaultDirName={localappdata}\T7PatchLauncher
; Allows your friends to manually choose where they want the launcher and T7 patch to go
DisableDirPage=no
DefaultGroupName=T7 Patch Launcher
DisableProgramGroupPage=yes
OutputDir=.\Output
OutputBaseFilename=T7LauncherSetup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Run]
; Silent background script execution
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -WindowStyle Hidden -File ""{tmp}\install_helper.ps1"" -InstallDir ""{app}"" -BO3Path ""{code:GetBO3Path}"""; Flags: runhidden; StatusMsg: "Configuring security patches and Steam settings..."
; Opens the instructions text file automatically when they click Finish
Filename: "{app}\LaunchOptionsInstruction.txt"; Description: "View manual Steam Launch Options instructions"; Flags: postinstall shellexec skipifsilent

[Code]
var
  BO3DirPage: TInputDirWizardPage;

// Generates the PowerShell installer logic dynamically during installation
procedure CreateInstallHelper;
var
  HelperCode: TStringList;
begin
  HelperCode := TStringList.Create;
  try
    HelperCode.Add('param(');
    HelperCode.Add('    [string]$InstallDir,');
    HelperCode.Add('    [string]$BO3Path');
    HelperCode.Add(')');
    HelperCode.Add('');
    HelperCode.Add('# 1. VERIFY GAME BUILD VERSION');
    HelperCode.Add('$AcfPath = Join-Path $BO3Path "..\..\appmanifest_311210.acf"');
    HelperCode.Add('$AcfPath = [System.IO.Path]::GetFullPath($AcfPath)');
    HelperCode.Add('if (Test-Path $AcfPath) {');
    HelperCode.Add('    $AcfContent = Get-Content -Path $AcfPath -Raw');
    HelperCode.Add('    if ($AcfContent -match ''"buildid"\s*"(\d+)"'') {');
    HelperCode.Add('        $CurrentBuildId = [int]$Matches[1]');
    HelperCode.Add('        $RequiredBuildId = 21201493');
    HelperCode.Add('        if ($CurrentBuildId -lt $RequiredBuildId) {');
    HelperCode.Add('            Add-Type -AssemblyName PresentationFramework');
    HelperCode.Add('            [System.Windows.MessageBox]::Show(');
    HelperCode.Add('                "Your Black Ops 3 installation is out of date (Current Build: $CurrentBuildId).`n`nThe patch requires Build $RequiredBuildId (released Feb 19, 2026) or newer.`n`nPlease update your game on Steam before continuing.",');
    HelperCode.Add('                "Game Update Required",');
    HelperCode.Add('                "OK",');
    HelperCode.Add('                "Error"');
    HelperCode.Add('            )');
    HelperCode.Add('            exit 1');
    HelperCode.Add('        }');
    HelperCode.Add('    }');
    HelperCode.Add('}');
    HelperCode.Add('');
    HelperCode.Add('# 2. DEFINE INSTALL PATHS');
    HelperCode.Add('$SubFolder = "t7patch_3.03.Windows.Only"');
    HelperCode.Add('$T7Dir = Join-Path $InstallDir $SubFolder');
    HelperCode.Add('if (!$T7Dir.EndsWith("\")) { $T7Dir += "\" }');
    HelperCode.Add('$T7ZipPath = Join-Path $env:TEMP "t7patch.zip"');
    HelperCode.Add('$CsPath = Join-Path $T7Dir "LaunchT7.cs"');
    HelperCode.Add('$ExePath = Join-Path $T7Dir "LaunchT7.exe"');
    HelperCode.Add('if (!(Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir | Out-Null }');
    HelperCode.Add('');
    HelperCode.Add('# 3. DOWNLOAD STATIC T7 PATCH ZIP (v3.03)');
    HelperCode.Add('try {');
    HelperCode.Add('    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12');
    HelperCode.Add('    $T7DownloadUrl = "https://github.com/Scroptss/T7Patch/releases/download/v3.03/t7patch_3.03.Windows.Only.zip"');
    HelperCode.Add('    Invoke-WebRequest -Uri $T7DownloadUrl -OutFile $T7ZipPath -UseBasicParsing');
    HelperCode.Add('    Expand-Archive -Path $T7ZipPath -DestinationPath $InstallDir -Force');
    HelperCode.Add('    Remove-Item $T7ZipPath -ErrorAction SilentlyContinue');
    HelperCode.Add('} catch {');
    HelperCode.Add('    Add-Type -AssemblyName PresentationFramework');
    HelperCode.Add('    [System.Windows.MessageBox]::Show(');
    HelperCode.Add('        "Failed to download the patch automatically.`n`nError: $_",');
    HelperCode.Add('        "Download Error",');
    HelperCode.Add('        "OK",');
    HelperCode.Add('        "Error"');
    HelperCode.Add('    )');
    HelperCode.Add('    exit 1');
    HelperCode.Add('}');
    HelperCode.Add('');
    HelperCode.Add('# 4. GENERATE THE NATIVE C# LAUNCHER SOURCE CODE');
    HelperCode.Add('$VbsT7Dir = $T7Dir.Replace("\", "\\")');
    HelperCode.Add('$VbsConfigIniGame = (Join-Path $BO3Path "t7patch.conf").Replace("\", "\\")');
    HelperCode.Add('');
    HelperCode.Add('$CsTemplate = @"');
    HelperCode.Add('using System;');
    HelperCode.Add('using System.IO;');
    HelperCode.Add('using System.Diagnostics;');
    HelperCode.Add('using System.Windows.Forms;');
    HelperCode.Add('using System.Drawing;');
    HelperCode.Add('using System.Text.RegularExpressions;');
    HelperCode.Add('using System.Threading;');
    HelperCode.Add('');
    HelperCode.Add('// Assembly metadata to establish static developer signature for ML/Heuristics scanners');
    HelperCode.Add('[assembly: System.Reflection.AssemblyTitle("T7 Patch Launcher")]');
    HelperCode.Add('[assembly: System.Reflection.AssemblyDescription("Secure Launch Helper for Call of Duty: Black Ops III")]');
    HelperCode.Add('[assembly: System.Reflection.AssemblyCompany("T7 Security Group")]');
    HelperCode.Add('[assembly: System.Reflection.AssemblyProduct("T7 Patch Launcher")]');
    HelperCode.Add('[assembly: System.Reflection.AssemblyCopyright("Copyright (c) 2026")]');
    HelperCode.Add('[assembly: System.Reflection.AssemblyVersion("3.0.3.0")]');
    HelperCode.Add('[assembly: System.Reflection.AssemblyFileVersion("3.0.3.0")]');
    HelperCode.Add('');
    HelperCode.Add('namespace T7Launcher {');
    HelperCode.Add('    static class Program {');
    HelperCode.Add('        [STAThread]');
    HelperCode.Add('        static void Main(string[] args) {');
    HelperCode.Add('            string t7Dir = AppDomain.CurrentDomain.BaseDirectory;');
    HelperCode.Add('            string jsonPath = Path.Combine(t7Dir, "settings.json");');
    HelperCode.Add('            string iniPath = Path.Combine(t7Dir, "t7patch.conf");');
    HelperCode.Add('');
    HelperCode.Add('            string activePassword = "";');
    HelperCode.Add('            string activeUsername = "";');
    HelperCode.Add('            bool activeFriendsOnly = true;');
    HelperCode.Add('');
    HelperCode.Add('            if (File.Exists(jsonPath)) {');
    HelperCode.Add('                try {');
    HelperCode.Add('                    string jsonContent = File.ReadAllText(jsonPath);');
    HelperCode.Add('                    Match mPass = Regex.Match(jsonContent, @"""networkpassword""\s*:\s*""([^""\\]*(?:\\.[^""\\]*)*)""");');
    HelperCode.Add('                    if (mPass.Success) activePassword = UnescapeJson(mPass.Groups[1].Value);');
    HelperCode.Add('                    Match mUser = Regex.Match(jsonContent, @"""playername""\s*:\s*""([^""\\]*(?:\\.[^""\\]*)*)""");');
    HelperCode.Add('                    if (mUser.Success) activeUsername = UnescapeJson(mUser.Groups[1].Value);');
    HelperCode.Add('                    Match mFriends = Regex.Match(jsonContent, @"""isfriendsonly""\s*:\s*(true|false)", RegexOptions.IgnoreCase);');
    HelperCode.Add('                    if (mFriends.Success) activeFriendsOnly = bool.Parse(mFriends.Groups[1].Value);');
    HelperCode.Add('                } catch {}');
    HelperCode.Add('            }');
    HelperCode.Add('');
    HelperCode.Add('            string newUsername = activeUsername;');
    HelperCode.Add('            string newPassword = activePassword;');
    HelperCode.Add('            bool isFriendsOnly = activeFriendsOnly;');
    HelperCode.Add('            bool isValidInput = false;');
    HelperCode.Add('');
    HelperCode.Add('            do {');
    HelperCode.Add('                using (Form form = new Form()) {');
    HelperCode.Add('                    form.Text = "T7 Patch Configurator";');
    HelperCode.Add('                    form.Size = new Size(420, 300);');
    HelperCode.Add('                    form.BackColor = Color.FromArgb(30, 30, 30);');
    HelperCode.Add('                    form.StartPosition = FormStartPosition.CenterScreen;');
    HelperCode.Add('                    form.FormBorderStyle = FormBorderStyle.FixedDialog;');
    HelperCode.Add('                    form.MaximizeBox = false;');
    HelperCode.Add('                    form.MinimizeBox = false;');
    HelperCode.Add('                    form.TopMost = true;');
    HelperCode.Add('');
    HelperCode.Add('                    Label titleLabel = new Label {');
    HelperCode.Add('                        Location = new Point(25, 12),');
    HelperCode.Add('                        Size = new Size(350, 25),');
    HelperCode.Add('                        Font = new Font("Segoe UI", 11, FontStyle.Bold),');
    HelperCode.Add('                        ForeColor = Color.FromArgb(240, 240, 240),');
    HelperCode.Add('                        Text = "T7 Patch Security Settings"');
    HelperCode.Add('                    };');
    HelperCode.Add('                    form.Controls.Add(titleLabel);');
    HelperCode.Add('');
    HelperCode.Add('                    Label userLabel = new Label {');
    HelperCode.Add('                        Location = new Point(25, 45),');
    HelperCode.Add('                        Size = new Size(350, 20),');
    HelperCode.Add('                        Font = new Font("Segoe UI", 9),');
    HelperCode.Add('                        ForeColor = Color.FromArgb(160, 160, 160),');
    HelperCode.Add('                        Text = "Player Username (can be left blank):"');
    HelperCode.Add('                    };');
    HelperCode.Add('                    form.Controls.Add(userLabel);');
    HelperCode.Add('');
    HelperCode.Add('                    TextBox textBoxUser = new TextBox {');
    HelperCode.Add('                        Location = new Point(25, 65),');
    HelperCode.Add('                        Size = new Size(354, 25),');
    HelperCode.Add('                        Font = new Font("Segoe UI", 9),');
    HelperCode.Add('                        BackColor = Color.FromArgb(45, 45, 45),');
    HelperCode.Add('                        ForeColor = Color.White,');
    HelperCode.Add('                        BorderStyle = BorderStyle.FixedSingle,');
    HelperCode.Add('                        Text = newUsername');
    HelperCode.Add('                    };');
    HelperCode.Add('                    form.Controls.Add(textBoxUser);');
    HelperCode.Add('');
    HelperCode.Add('                    Label passLabel = new Label {');
    HelperCode.Add('                        Location = new Point(25, 100),');
    HelperCode.Add('                        Size = new Size(350, 20),');
    HelperCode.Add('                        Font = new Font("Segoe UI", 9),');
    HelperCode.Add('                        ForeColor = Color.FromArgb(160, 160, 160),');
    HelperCode.Add('                        Text = "Network password (minimum 8 characters):"');
    HelperCode.Add('                    };');
    HelperCode.Add('                    form.Controls.Add(passLabel);');
    HelperCode.Add('');
    HelperCode.Add('                    TextBox textBoxPass = new TextBox {');
    HelperCode.Add('                        Location = new Point(25, 120),');
    HelperCode.Add('                        Size = new Size(354, 25),');
    HelperCode.Add('                        Font = new Font("Segoe UI", 9),');
    HelperCode.Add('                        BackColor = Color.FromArgb(45, 45, 45),');
    HelperCode.Add('                        ForeColor = Color.White,');
    HelperCode.Add('                        BorderStyle = BorderStyle.FixedSingle,');
    HelperCode.Add('                        Text = newPassword');
    HelperCode.Add('                    };');
    HelperCode.Add('                    form.Controls.Add(textBoxPass);');
    HelperCode.Add('');
    HelperCode.Add('                    CheckBox checkBoxFriends = new CheckBox {');
    HelperCode.Add('                        Location = new Point(25, 155),');
    HelperCode.Add('                        Size = new Size(350, 24),');
    HelperCode.Add('                        Font = new Font("Segoe UI", 9),');
    HelperCode.Add('                        ForeColor = Color.FromArgb(200, 200, 200),');
    HelperCode.Add('                        FlatStyle = FlatStyle.Flat,');
    HelperCode.Add('                        Text = "Enable Friends Only Mode",');
    HelperCode.Add('                        Checked = isFriendsOnly');
    HelperCode.Add('                    };');
    HelperCode.Add('                    form.Controls.Add(checkBoxFriends);');
    HelperCode.Add('');
    HelperCode.Add('                    Button okButton = new Button {');
    HelperCode.Add('                        Location = new Point(165, 200),');
    HelperCode.Add('                        Size = new Size(100, 32),');
    HelperCode.Add('                        Text = "Launch",');
    HelperCode.Add('                        Font = new Font("Segoe UI", 9),');
    HelperCode.Add('                        FlatStyle = FlatStyle.Flat,');
    HelperCode.Add('                        BackColor = Color.FromArgb(0, 122, 204),');
    HelperCode.Add('                        ForeColor = Color.White,');
    HelperCode.Add('                        DialogResult = DialogResult.OK');
    HelperCode.Add('                    };');
    HelperCode.Add('                    okButton.FlatAppearance.BorderSize = 0;');
    HelperCode.Add('                    form.AcceptButton = okButton;');
    HelperCode.Add('                    form.Controls.Add(okButton);');
    HelperCode.Add('');
    HelperCode.Add('                    Button cancelButton = new Button {');
    HelperCode.Add('                        Location = new Point(279, 200),');
    HelperCode.Add('                        Size = new Size(100, 32),');
    HelperCode.Add('                        Text = "Cancel",');
    HelperCode.Add('                        Font = new Font("Segoe UI", 9),');
    HelperCode.Add('                        FlatStyle = FlatStyle.Flat,');
    HelperCode.Add('                        BackColor = Color.FromArgb(60, 60, 60),');
    HelperCode.Add('                        ForeColor = Color.FromArgb(220, 220, 220),');
    HelperCode.Add('                        DialogResult = DialogResult.Cancel');
    HelperCode.Add('                    };');
    HelperCode.Add('                    cancelButton.FlatAppearance.BorderSize = 0;');
    HelperCode.Add('                    form.CancelButton = cancelButton;');
    HelperCode.Add('                    form.Controls.Add(cancelButton);');
    HelperCode.Add('');
    HelperCode.Add('                    if (form.ShowDialog() == DialogResult.OK) {');
    HelperCode.Add('                        newUsername = textBoxUser.Text;');
    HelperCode.Add('                        newPassword = textBoxPass.Text;');
    HelperCode.Add('                        isFriendsOnly = checkBoxFriends.Checked;');
    HelperCode.Add('');
    HelperCode.Add('                        if (newPassword.Length < 8) {');
    HelperCode.Add('                            MessageBox.Show("Error: The password must be at least 8 characters long. You entered " + newPassword.Length + " characters.", "Password Too Short", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);');
    HelperCode.Add('                        } else {');
    HelperCode.Add('                            isValidInput = true;');
    HelperCode.Add('                        }');
    HelperCode.Add('                    } else {');
    HelperCode.Add('                        return;');
    HelperCode.Add('                    }');
    HelperCode.Add('                }');
    HelperCode.Add('            } while (!isValidInput);');
    HelperCode.Add('');
    HelperCode.Add('            SyncJsonFile(jsonPath, newUsername, newPassword, isFriendsOnly);');
    HelperCode.Add('            SyncIniFile(iniPath, newUsername, newPassword, isFriendsOnly);');
    HelperCode.Add('');
    HelperCode.Add('            Thread.Sleep(2000);');
    HelperCode.Add('');
    HelperCode.Add('            if (args.Length > 0) {');
    HelperCode.Add('                try {');
    HelperCode.Add('                    ProcessStartInfo bo3Info = new ProcessStartInfo();');
    HelperCode.Add('                    bo3Info.FileName = args[0];');
    HelperCode.Add('                    if (args.Length > 1) {');
    HelperCode.Add('                        string[] remainingArgs = new string[args.Length - 1];');
    HelperCode.Add('                        Array.Copy(args, 1, remainingArgs, 0, args.Length - 1);');
    HelperCode.Add('                        bo3Info.Arguments = string.Join(" ", remainingArgs);');
    HelperCode.Add('                    }');
    HelperCode.Add('                    bo3Info.WorkingDirectory = Path.GetDirectoryName(args[0]);');
    HelperCode.Add('                    bo3Info.UseShellExecute = false;');
    HelperCode.Add('                    Process.Start(bo3Info);');
    HelperCode.Add('                } catch (Exception ex) {');
    HelperCode.Add('                    MessageBox.Show("Failed to launch Black Ops 3: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);');
    HelperCode.Add('                    return;');
    HelperCode.Add('                }');
    HelperCode.Add('            }');
    HelperCode.Add('');
    HelperCode.Add('            // Pause 1.5 seconds to let short-lived graphics/Steam overlay startup threads stabilize');
    HelperCode.Add('            Thread.Sleep(1500);');
    HelperCode.Add('');
    HelperCode.Add('            // Start T7 Patch securely next (prompts for Admin)');
    HelperCode.Add('            try {');
    HelperCode.Add('                ProcessStartInfo t7Info = new ProcessStartInfo();');
    HelperCode.Add('                t7Info.FileName = Path.Combine(t7Dir, "t7dwidm_protect.exe");');
    HelperCode.Add('                t7Info.WorkingDirectory = t7Dir;');
    HelperCode.Add('                t7Info.Verb = "runas";');
    HelperCode.Add('                t7Info.UseShellExecute = true;');
    HelperCode.Add('                Process.Start(t7Info);');
    HelperCode.Add('            } catch (Exception ex) {');
    HelperCode.Add('                MessageBox.Show("Failed to launch T7 Patch: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);');
    HelperCode.Add('                return;');
    HelperCode.Add('            }');
    HelperCode.Add('');
    HelperCode.Add('            Thread.Sleep(10000);');
    HelperCode.Add('');
    HelperCode.Add('            while (true) {');
    HelperCode.Add('                Process[] bo3Processes = Process.GetProcessesByName("BlackOps3");');
    HelperCode.Add('                Process[] t7Processes = Process.GetProcessesByName("t7dwidm_protect");');
    HelperCode.Add('');
    HelperCode.Add('                if (bo3Processes.Length == 0 || t7Processes.Length == 0) {');
    HelperCode.Add('                    foreach (var p in bo3Processes) { try { p.Kill(); } catch {} }');
    HelperCode.Add('                    foreach (var p in t7Processes) { try { p.Kill(); } catch {} }');
    HelperCode.Add('                    break;');
    HelperCode.Add('                }');
    HelperCode.Add('                Thread.Sleep(1000);');
    HelperCode.Add('            }');
    HelperCode.Add('        }');
    HelperCode.Add('');
    HelperCode.Add('        static string UnescapeJson(string str) {');
    HelperCode.Add('            str = Regex.Replace(str, @"\\u([0-9a-fA-F]{4})", m => {');
    HelperCode.Add('                return ((char)Convert.ToInt32(m.Groups[1].Value, 16)).ToString();');
    HelperCode.Add('            });');
    HelperCode.Add('            str = str.Replace("\\\"", "\"").Replace("\\\\", "\\");');
    HelperCode.Add('            return str;');
    HelperCode.Add('        }');
    HelperCode.Add('');
    HelperCode.Add('        static string EscapeJson(string str) {');
    HelperCode.Add('            return str.Replace("\\", "\\\\").Replace("\"", "\\\"");');
    HelperCode.Add('        }');
    HelperCode.Add('');
    HelperCode.Add('        static void SyncJsonFile(string filePath, string username, string password, bool friendsOnly) {');
    HelperCode.Add('            string defaultJson = "{\r\n  \"playername\": \"\",\r\n  \"isfriendsonly\": true,\r\n  \"ismtlpatchenabled\": false,\r\n  \"networkpassword\": \"\"\r\n}";');
    HelperCode.Add('            if (!File.Exists(filePath)) {');
    HelperCode.Add('                File.WriteAllText(filePath, defaultJson);');
    HelperCode.Add('            }');
    HelperCode.Add('');
    HelperCode.Add('            string content = File.ReadAllText(filePath);');
    HelperCode.Add('            string friendsOnlyVal = friendsOnly ? "true" : "false";');
    HelperCode.Add('');
    HelperCode.Add('            content = Regex.Replace(content, @"""isfriendsonly""\s*:\s*(true|false)", "\"isfriendsonly\": " + friendsOnlyVal, RegexOptions.IgnoreCase);');
    HelperCode.Add('            content = Regex.Replace(content, @"""networkpassword""\s*:\s*""[^""]*""", "\"networkpassword\": \"" + EscapeJson(password) + "\"");');
    HelperCode.Add('            content = Regex.Replace(content, @"""playername""\s*:\s*""[^""]*""", "\"playername\": \"" + EscapeJson(username) + "\"");');
    HelperCode.Add('');
    HelperCode.Add('            File.WriteAllText(filePath, content);');
    HelperCode.Add('        }');
    HelperCode.Add('');
    HelperCode.Add('        static void SyncIniFile(string filePath, string username, string password, bool friendsOnly) {');
    HelperCode.Add('            string finalUsername = string.IsNullOrEmpty(username.Trim()) ? "Unknown Soldier" : username;');
    HelperCode.Add('            string friendsOnlyVal = friendsOnly ? "1" : "0";');
    HelperCode.Add('');
    HelperCode.Add('            if (!File.Exists(filePath)) {');
    HelperCode.Add('                File.WriteAllText(filePath, "playername=" + finalUsername + "\r\nisfriendsonly=1\r\nnetworkpassword=\r\n");');
    HelperCode.Add('            }');
    HelperCode.Add('');
    HelperCode.Add('            string[] lines = File.ReadAllLines(filePath);');
    HelperCode.Add('            bool foundUser = false, foundPass = false, foundFriends = false;');
    HelperCode.Add('');
    HelperCode.Add('            for (int i = 0; i < lines.Length; i++) {');
    HelperCode.Add('                string trimL = lines[i].Replace(" ", "").ToLower();');
    HelperCode.Add('                if (trimL.StartsWith("playername=")) {');
    HelperCode.Add('                    lines[i] = "playername=" + finalUsername;');
    HelperCode.Add('                    foundUser = true;');
    HelperCode.Add('                } else if (trimL.StartsWith("networkpassword=")) {');
    HelperCode.Add('                    lines[i] = "networkpassword=" + password;');
    HelperCode.Add('                    foundPass = true;');
    HelperCode.Add('                } else if (trimL.StartsWith("isfriendsonly=")) {');
    HelperCode.Add('                    lines[i] = "isfriendsonly=" + friendsOnlyVal;');
    HelperCode.Add('                    foundFriends = true;');
    HelperCode.Add('                }');
    HelperCode.Add('            }');
    HelperCode.Add('');
    HelperCode.Add('            var list = new System.Collections.Generic.List<string>(lines);');
    HelperCode.Add('            if (!foundUser) list.Add("playername=" + finalUsername);');
    HelperCode.Add('            if (!foundPass) list.Add("networkpassword=" + password);');
    HelperCode.Add('            if (!foundFriends) list.Add("isfriendsonly=" + friendsOnlyVal);');
    HelperCode.Add('');
    HelperCode.Add('            File.WriteAllLines(filePath, list.ToArray());');
    HelperCode.Add('        }');
    HelperCode.Add('    }');
    HelperCode.Add('}');
    HelperCode.Add('"@');
    HelperCode.Add('');
    HelperCode.Add('$CsTemplate | Out-File -FilePath $CsPath -Encoding utf8 -Force');
    HelperCode.Add('');
    HelperCode.Add('# 5. NATIVELY COMPILE THE C# LAUNCHER SOURCE TO EXE');
    HelperCode.Add('$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"');
    HelperCode.Add('if (Test-Path $csc) {');
    HelperCode.Add('    Start-Process -FilePath $csc -ArgumentList "/target:winexe", "/out:`"$ExePath`"", "/reference:System.Windows.Forms.dll", "/reference:System.Drawing.dll", "`"$CsPath`"" -NoNewWindow -Wait');
    HelperCode.Add('    Remove-Item $CsPath -ErrorAction SilentlyContinue');
    HelperCode.Add('}');
    HelperCode.Add('');
    HelperCode.Add('# 6. GENERATE LAUNCH OPTIONS INSTRUCTION FILE');
    HelperCode.Add('$InstructionPath = Join-Path $InstallDir "LaunchOptionsInstruction.txt"');
    HelperCode.Add('$InstructionText = @"');
    HelperCode.Add('=== BLACK OPS 3 T7 PATCH LAUNCHER INSTRUCTIONS ===');
    HelperCode.Add('');
    HelperCode.Add('If your game is launching standard instead of prompting for security settings, ');
    HelperCode.Add('Steam failed to automatically apply the launch command. ');
    HelperCode.Add('');
    HelperCode.Add('Please follow these simple steps to manually set it up:');
    HelperCode.Add('');
    HelperCode.Add('1. Open Steam and go to your Library.');
    HelperCode.Add('2. Right-click on "Call of Duty: Black Ops III" and select "Properties".');
    HelperCode.Add('3. In the "General" tab, scroll down to the "Launch Options" section at the bottom.');
    HelperCode.Add('4. Copy and paste the exact command below into the text box (if you have other launch options like -dx11, just add this to the end of them with a space):');
    HelperCode.Add('');
    HelperCode.Add('--------------------------------------------------');
    HelperCode.Add('"$ExePath" %command%');
    HelperCode.Add('--------------------------------------------------');
    HelperCode.Add('');
    HelperCode.Add('5. Close the Properties window and click PLAY on Steam.');
    HelperCode.Add('');
    HelperCode.Add('--------------------------------------------------');
    HelperCode.Add('Note: If the T7 Patch experiences an error on startup, just restart the game.');
    HelperCode.Add('"@');
    HelperCode.Add('$InstructionText | Out-File -FilePath $InstructionPath -Encoding utf8 -Force');
    HelperCode.Add('');
    HelperCode.Add('# 7. AUTOMATICALLY ADD TO STEAM LAUNCH OPTIONS');
    HelperCode.Add('if ($SteamPath) {');
    HelperCode.Add('    $UserDataDir = Join-Path $SteamPath "userdata"');
    HelperCode.Add('    if (Test-Path $UserDataDir) {');
    HelperCode.Add('        $VdfFiles = Get-ChildItem -Path $UserDataDir -Filter "localconfig.vdf" -Recurse');
    HelperCode.Add('        $LaunchOptionStr = "`"$ExePath`" %command%"');
    HelperCode.Add('        foreach ($VdfFile in $VdfFiles) {');
    HelperCode.Add('            $FilePath = $VdfFile.FullName');
    HelperCode.Add('            Copy-Item -Path $FilePath -Destination "$FilePath.bak" -Force');
    HelperCode.Add('            $Content = Get-Content -Path $FilePath -Raw');
    HelperCode.Add('            ');
    HelperCode.Add('            # Improved Regex: Checks if App ID "311210" config block exists');
    HelperCode.Add('            if ($Content -match ''"311210"\s*\{'') {');
    HelperCode.Add('                $BlockPattern = ''(?s)("311210"\s*\{.*?\})''');
    HelperCode.Add('                if ($Content -match $BlockPattern) {');
    HelperCode.Add('                    $Block = $Matches[1]');
    HelperCode.Add('                    if ($Block -match ''"LaunchOptions"\s*"([^"]*)"'') {');
    HelperCode.Add('                        $ExistingOptions = $Matches[1]');
    HelperCode.Add('                        if ($ExistingOptions -notlike "*LaunchT7*") {');
    HelperCode.Add('                            $CombinedOptions = "$ExistingOptions $LaunchOptionStr".Trim()');
    HelperCode.Add('                            $NewBlock = $Block -replace ''"LaunchOptions"\s*"[^"]*"'', "`"LaunchOptions`"`t`"$CombinedOptions`""');
    HelperCode.Add('                            $Content = $Content.Replace($Block, $NewBlock)');
    HelperCode.Add('                        }');
    HelperCode.Add('                    } else {');
    HelperCode.Add('                        $NewBlock = $Block -replace ''(\{\s*)'', "`$1`"LaunchOptions`"`t`"$LaunchOptionStr`"`r`n`t`t"');
    HelperCode.Add('                        $Content = $Content.Replace($Block, $NewBlock)');
    HelperCode.Add('                    }');
    HelperCode.Add('                }');
    HelperCode.Add('            } else {');
    HelperCode.Add('                # If App ID block does not exist, find "apps" section and inject a fresh one');
    HelperCode.Add('                if ($Content -match ''"apps"\s*\{'') {');
    HelperCode.Add('                    $NewAppBlock = "`"apps`"`r`n`t`t{`r`n`t`t`t`"311210`"`r`n`t`t`t{`r`n`t`t`t`t`"LaunchOptions`"`t`"$LaunchOptionStr`"`r`n`t`t`t}"');
    HelperCode.Add('                    $Content = $Content -replace ''"apps"\s*\{'', $NewAppBlock');
    HelperCode.Add('                }');
    HelperCode.Add('            }');
    HelperCode.Add('            Set-Content -Path $FilePath -Value $Content -Encoding UTF8 -Force');
    HelperCode.Add('        }');
    HelperCode.Add('    }');
    HelperCode.Add('}');

    HelperCode.SaveToFile(ExpandConstant('{tmp}\install_helper.ps1'));
  finally
    HelperCode.Free;
  end;
end;

// Helper function to search for Black Ops III folder via Steam Registry Uninstall Keys
function FindBO3Path: String;
var
  Path: String;
begin
  Result := '';
  // 1. Check 64-bit Local Machine Registry
  if RegQueryStringValue(HKLM64, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 311210', 'InstallLocation', Path) then
  begin
    if FileExists(Path + '\BlackOps3.exe') then
    begin
      Result := Path;
      Exit;
    end;
  end;

  // 2. Check 32-bit Local Machine Registry
  if RegQueryStringValue(HKLM32, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 311210', 'InstallLocation', Path) then
  begin
    if FileExists(Path + '\BlackOps3.exe') then
    begin
      Result := Path;
      Exit;
    end;
  end;

  // 3. Check Current User Registry
  if RegQueryStringValue(HKCU, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 311210', 'InstallLocation', Path) then
  begin
    if FileExists(Path + '\BlackOps3.exe') then
    begin
      Result := Path;
      Exit;
    end;
  end;

  // 4. Fallback: Search the primary Steam Path
  if RegQueryStringValue(HKCU, 'Software\Valve\Steam', 'SteamPath', Path) then
  begin
    Path := Path + '\steamapps\common\Call of Duty Black Ops III';
    if FileExists(Path + '\BlackOps3.exe') then
    begin
      Result := Path;
      Exit;
    end;
  end;
end;

procedure InitializeWizard;
var
  DetectedPath: String;
begin
  // Create the PS1 script in the Temp directory dynamically
  CreateInstallHelper;

  // Search Windows uninstall registry database for game installation folder
  DetectedPath := FindBO3Path;

  // Custom configuration page inside Setup Wizard
  BO3DirPage := CreateInputDirPage(wpSelectDir,
    'Select Black Ops III Installation Folder',
    'Where is Call of Duty: Black Ops III installed?',
    'The setup program needs to find your Black Ops III folder to configure launch options and sync settings.',
    False, '');
  
  BO3DirPage.Add('Folder:');
  
  if DetectedPath <> '' then
    BO3DirPage.Values[0] := DetectedPath
  else
    BO3DirPage.Values[0] := 'C:\Program Files (x86)\Steam\steamapps\common\Call of Duty Black Ops III';
end;

function GetBO3Path(Param: String): String;
begin
  Result := BO3DirPage.Values[0];
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = BO3DirPage.ID then
  begin
    if not FileExists(BO3DirPage.Values[0] + '\BlackOps3.exe') then
    begin
      MsgBox('BlackOps3.exe was not found in the selected folder.' #13#13 'Please select the correct "Call of Duty Black Ops III" directory.', mbError, MB_OK);
      Result := False;
    end;
  end;
end;