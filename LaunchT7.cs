using System;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;
using System.Drawing;
using System.Text.RegularExpressions;
using System.Threading;
using Microsoft.Win32;

[assembly: System.Reflection.AssemblyTitle("T7 Patch Launcher")]
[assembly: System.Reflection.AssemblyDescription("Secure Launch Helper for Call of Duty: Black Ops III")]
[assembly: System.Reflection.AssemblyCompany("T7 Security Group")]
[assembly: System.Reflection.AssemblyProduct("T7 Patch Launcher")]
[assembly: System.Reflection.AssemblyCopyright("Copyright (c) 2026")]
[assembly: System.Reflection.AssemblyVersion("3.0.3.0")]
[assembly: System.Reflection.AssemblyFileVersion("3.0.3.0")]

namespace T7Launcher {
    static class Program {
        [STAThread]
        static void Main(string[] args) {
            // Check if installer is running the setup routine
            if (args.Length > 0 && args[0] == "--setup") {
                RunSetup();
                return;
            }

            // Check if installer is requesting to open the readme file on exit
            if (args.Length > 0 && args[0] == "--openreadme") {
                try {
                    string readmePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "README.txt");
                    if (File.Exists(readmePath)) {
                        Process.Start(readmePath);
                    }
                } catch {}
                return;
            }

            string t7Dir = AppDomain.CurrentDomain.BaseDirectory;
            string jsonPath = Path.Combine(t7Dir, "settings.json");
            string iniPath = Path.Combine(t7Dir, "t7patch.conf");

            string activePassword = "";
            string activeUsername = "";
            bool activeFriendsOnly = true;

            if (File.Exists(jsonPath)) {
                try {
                    string jsonContent = File.ReadAllText(jsonPath);
                    Match mPass = Regex.Match(jsonContent, @"""networkpassword""\s*:\s*""([^""\\]*(?:\\.[^""\\]*)*)""");
                    if (mPass.Success) activePassword = UnescapeJson(mPass.Groups[1].Value);
                    Match mUser = Regex.Match(jsonContent, @"""playername""\s*:\s*""([^""\\]*(?:\\.[^""\\]*)*)""");
                    if (mUser.Success) activeUsername = UnescapeJson(mUser.Groups[1].Value);
                    Match mFriends = Regex.Match(jsonContent, @"""isfriendsonly""\s*:\s*(true|false)", RegexOptions.IgnoreCase);
                    if (mFriends.Success) activeFriendsOnly = bool.Parse(mFriends.Groups[1].Value);
                } catch {}
            }

            string newUsername = activeUsername;
            string newPassword = activePassword;
            bool isFriendsOnly = activeFriendsOnly;
            bool isValidInput = false;

            do {
                using (Form form = new Form()) {
                    form.Text = "T7 Patch Configurator";
                    form.Size = new Size(420, 300);
                    form.BackColor = Color.FromArgb(30, 30, 30);
                    form.StartPosition = FormStartPosition.CenterScreen;
                    form.FormBorderStyle = FormBorderStyle.FixedDialog;
                    form.MaximizeBox = false;
                    form.MinimizeBox = false;
                    form.TopMost = true;

                    Label titleLabel = new Label {
                        Location = new Point(25, 12),
                        Size = new Size(350, 25),
                        Font = new Font("Segoe UI", 11, FontStyle.Bold),
                        ForeColor = Color.FromArgb(240, 240, 240),
                        Text = "T7 Patch Security Settings"
                    };
                    form.Controls.Add(titleLabel);

                    Label userLabel = new Label {
                        Location = new Point(25, 45),
                        Size = new Size(350, 20),
                        Font = new Font("Segoe UI", 9),
                        ForeColor = Color.FromArgb(160, 160, 160),
                        Text = "Player Username (can be left blank):"
                    };
                    form.Controls.Add(userLabel);

                    TextBox textBoxUser = new TextBox {
                        Location = new Point(25, 65),
                        Size = new Size(354, 25),
                        Font = new Font("Segoe UI", 9),
                        BackColor = Color.FromArgb(45, 45, 45),
                        ForeColor = Color.White,
                        BorderStyle = BorderStyle.FixedSingle,
                        Text = newUsername
                    };
                    form.Controls.Add(textBoxUser);

                    Label passLabel = new Label {
                        Location = new Point(25, 100),
                        Size = new Size(350, 20),
                        Font = new Font("Segoe UI", 9),
                        ForeColor = Color.FromArgb(160, 160, 160),
                        Text = "Network password (minimum 8 characters):"
                    };
                    form.Controls.Add(passLabel);

                    TextBox textBoxPass = new TextBox {
                        Location = new Point(25, 120),
                        Size = new Size(354, 25),
                        Font = new Font("Segoe UI", 9),
                        BackColor = Color.FromArgb(45, 45, 45),
                        ForeColor = Color.White,
                        BorderStyle = BorderStyle.FixedSingle,
                        Text = newPassword
                    };
                    form.Controls.Add(textBoxPass);

                    CheckBox checkBoxFriends = new CheckBox {
                        Location = new Point(25, 155),
                        Size = new Size(350, 24),
                        Font = new Font("Segoe UI", 9),
                        ForeColor = Color.FromArgb(200, 200, 200),
                        FlatStyle = FlatStyle.Flat,
                        Text = "Enable Friends Only Mode",
                        Checked = isFriendsOnly
                    };
                    form.Controls.Add(checkBoxFriends);

                    Button okButton = new Button {
                        Location = new Point(165, 200),
                        Size = new Size(100, 32),
                        Text = "Launch",
                        Font = new Font("Segoe UI", 9),
                        FlatStyle = FlatStyle.Flat,
                        BackColor = Color.FromArgb(0, 122, 204),
                        ForeColor = Color.White,
                        DialogResult = DialogResult.OK
                    };
                    okButton.FlatAppearance.BorderSize = 0;
                    form.AcceptButton = okButton;
                    form.Controls.Add(okButton);

                    Button cancelButton = new Button {
                        Location = new Point(279, 200),
                        Size = new Size(100, 32),
                        Text = "Cancel",
                        Font = new Font("Segoe UI", 9),
                        FlatStyle = FlatStyle.Flat,
                        BackColor = Color.FromArgb(60, 60, 60),
                        ForeColor = Color.FromArgb(220, 220, 220),
                        DialogResult = DialogResult.Cancel
                    };
                    cancelButton.FlatAppearance.BorderSize = 0;
                    form.CancelButton = cancelButton;
                    form.Controls.Add(cancelButton);

                    if (form.ShowDialog() == DialogResult.OK) {
                        newUsername = textBoxUser.Text;
                        newPassword = textBoxPass.Text;
                        isFriendsOnly = checkBoxFriends.Checked;

                        if (newPassword.Length < 8) {
                            MessageBox.Show("Error: The password must be at least 8 characters long.", "Password Too Short", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                        } else {
                            isValidInput = true;
                        }
                    } else {
                        return;
                    }
                }
            } while (!isValidInput);

            SyncJsonFile(jsonPath, newUsername, newPassword, isFriendsOnly);
            SyncIniFile(iniPath, newUsername, newPassword, isFriendsOnly);

            if (args.Length > 0) {
                try {
                    string bo3Dir = Path.GetDirectoryName(args[0]);
                    if (!string.IsNullOrEmpty(bo3Dir)) {
                        string gameIniPath = Path.Combine(bo3Dir, "t7patch.conf");
                        SyncIniFile(gameIniPath, newUsername, newPassword, isFriendsOnly);
                    }
                } catch {}
            }

            Thread.Sleep(2000);

            if (args.Length > 0) {
                try {
                    ProcessStartInfo bo3Info = new ProcessStartInfo();
                    bo3Info.FileName = args[0];
                    if (args.Length > 1) {
                        string[] remainingArgs = new string[args.Length - 1];
                        Array.Copy(args, 1, remainingArgs, 0, args.Length - 1);
                        bo3Info.Arguments = string.Join(" ", remainingArgs);
                    }
                    bo3Info.WorkingDirectory = Path.GetDirectoryName(args[0]);
                    bo3Info.UseShellExecute = false;
                    Process.Start(bo3Info);
                } catch (Exception ex) {
                    MessageBox.Show("Failed to launch Black Ops 3: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
            }

            Thread.Sleep(1500);

            try {
                ProcessStartInfo t7Info = new ProcessStartInfo();
                t7Info.FileName = Path.Combine(t7Dir, "t7dwidm_protect.exe");
                t7Info.WorkingDirectory = t7Dir;
                t7Info.Verb = "runas";
                t7Info.UseShellExecute = true;
                Process.Start(t7Info);
            } catch (Exception ex) {
                MessageBox.Show("Failed to launch T7 Patch: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            Thread.Sleep(10000);

            while (true) {
                Process[] bo3Processes = Process.GetProcessesByName("BlackOps3");
                Process[] t7Processes = Process.GetProcessesByName("t7dwidm_protect");

                if (bo3Processes.Length == 0 || t7Processes.Length == 0) {
                    foreach (var p in bo3Processes) { try { p.Kill(); } catch {} }
                    foreach (var p in t7Processes) { try { p.Kill(); } catch {} }
                    break;
                }
                Thread.Sleep(1000);
            }
        }

        static void RunSetup() {
            string t7Dir = AppDomain.CurrentDomain.BaseDirectory;

            // Generate instructions readme IMMEDIATELY at start of setup
            string instructionPath = Path.Combine(t7Dir, "README.txt");
            string instructionText = "=== BLACK OPS 3 T7 PATCH LAUNCHER INSTRUCTIONS ===\r\n\r\n" +
                                     "Please follow these steps\r\n\r\n" +
                                     "1. Open Steam and go to your Library.\r\n" +
                                     "2. Right-click on \"Call of Duty: Black Ops III\" and select \"Properties\".\r\n" +
                                     "3. In the \"General\" tab, scroll down to the \"Launch Options\" section at the bottom.\r\n" +
                                     "4. Copy and paste the exact command below into the text box (if you have other launch options like -dx11, just add this to the end of them with a space):\r\n\r\n" +
                                     "--------------------------------------------------\r\n" +
                                     "\"" + Path.Combine(t7Dir, "LaunchT7.exe") + "\" %command%\r\n" +
                                     "--------------------------------------------------\r\n\r\n" +
                                     "5. Close the Properties window and click PLAY on Steam.\r\n\r\n" +
                                     "--------------------------------------------------\r\n" +
                                     "Note: If the T7 Patch experiences an error on startup, just restart the game.\r\n";
            try {
                File.WriteAllText(instructionPath, instructionText);
            } catch {}

            string bo3Path = FindBO3Path();

            // Exit silently if BO3 is not found automatically (prevents installer custom action crash)
            if (string.IsNullOrEmpty(bo3Path) || !File.Exists(Path.Combine(bo3Path, "BlackOps3.exe"))) {
                return;
            }

            // Create initial configuration in game directory
            try {
                string gameConf = Path.Combine(bo3Path, "t7patch.conf");
                if (!File.Exists(gameConf)) {
                    File.WriteAllText(gameConf, "playername=Unknown Soldier\r\nisfriendsonly=1\r\nnetworkpassword=\r\n");
                }
            } catch {}

            // Configure Steam launch parameters
            try {
                ConfigureSteamLaunchOptions(Path.Combine(t7Dir, "LaunchT7.exe"));
            } catch {}
        }

        static string FindBO3Path() {
            string[] registryPaths = {
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 311210",
                @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 311210"
            };

            foreach (var rPath in registryPaths) {
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(rPath)) {
                    if (key != null) {
                        string installLocation = key.GetValue("InstallLocation") as string;
                        if (!string.IsNullOrEmpty(installLocation) && File.Exists(Path.Combine(installLocation, "BlackOps3.exe"))) {
                            return installLocation;
                        }
                    }
                }
            }

            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 311210")) {
                if (key != null) {
                    string installLocation = key.GetValue("InstallLocation") as string;
                    if (!string.IsNullOrEmpty(installLocation) && File.Exists(Path.Combine(installLocation, "BlackOps3.exe"))) {
                        return installLocation;
                    }
                }
            }

            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Valve\Steam")) {
                if (key != null) {
                    string steamPath = key.GetValue("SteamPath") as string;
                    if (!string.IsNullOrEmpty(steamPath)) {
                        string fallback = Path.Combine(steamPath, @"steamapps\common\Call of Duty Black Ops III");
                        if (File.Exists(Path.Combine(fallback, "BlackOps3.exe"))) {
                            return fallback;
                        }
                    }
                }
            }

            return null;
        }

        static void ConfigureSteamLaunchOptions(string launcherPath) {
            try {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Valve\Steam")) {
                    if (key == null) return;
                    string steamPath = key.GetValue("SteamPath") as string;
                    if (string.IsNullOrEmpty(steamPath)) return;

                    string userData = Path.Combine(steamPath, "userdata");
                    if (!Directory.Exists(userData)) return;

                    string launchStr = "\"" + launcherPath + "\" %command%";

                    foreach (string userDir in Directory.GetDirectories(userData)) {
                        string localConfig = Path.Combine(userDir, "localconfig.vdf");
                        if (File.Exists(localConfig)) {
                            File.Copy(localConfig, localConfig + ".bak", true);
                            string content = File.ReadAllText(localConfig);

                            if (content.Contains("\"311210\"")) {
                                string pattern = @"(?s)(""311210""\s*\{.*?\})";
                                Match m = Regex.Match(content, pattern);
                                if (m.Success) {
                                    string block = m.Value;
                                    string newBlock;
                                    if (block.Contains("\"LaunchOptions\"")) {
                                        if (!block.Contains("LaunchT7")) {
                                            newBlock = Regex.Replace(block, @"""LaunchOptions""\s*""([^""\\]*(?:\\.[^""\\]*)*)""", mOptions => {
                                                string existing = mOptions.Groups[1].Value;
                                                return ("\"LaunchOptions\"\t\t\"" + existing + " " + launchStr + "\"").Trim();
                                            });
                                            content = content.Replace(block, newBlock);
                                        }
                                    } else {
                                        newBlock = Regex.Replace(block, @"(\{\s*)", "$1\"LaunchOptions\"\t\t\"" + launchStr + "\"\r\n\t\t\t");
                                        content = content.Replace(block, newBlock);
                                    }
                                }
                            } else {
                                if (content.Contains("\"apps\"")) {
                                    string newAppBlock = "\"apps\"\r\n\t\t{\r\n\t\t\t\"311210\"\r\n\t\t\t{\r\n\t\t\t\t\"LaunchOptions\"\t\t\"" + launchStr + "\"\r\n\t\t\t}";
                                    content = content.Replace("\"apps\"", newAppBlock);
                                }
                            }
                            File.WriteAllText(localConfig, content);
                        }
                    }
                }
            } catch {}
        }

        static string UnescapeJson(string str) {
            str = Regex.Replace(str, @"\\u([0-9a-fA-F]{4})", m => {
                return ((char)Convert.ToInt32(m.Groups[1].Value, 16)).ToString();
            });
            str = str.Replace("\\\"", "\"").Replace("\\\\", "\\");
            return str;
        }

        static string EscapeJson(string str) {
            return str.Replace("\\", "\\\\").Replace("\"", "\\\"");
        }

        static void SyncJsonFile(string filePath, string username, string password, bool friendsOnly) {
            string defaultJson = "{\r\n  \"playername\": \"\",\r\n  \"isfriendsonly\": true,\r\n  \"ismtlpatchenabled\": false,\r\n  \"networkpassword\": \"\"\r\n}";
            if (!File.Exists(filePath)) {
                File.WriteAllText(filePath, defaultJson);
            }

            string content = File.ReadAllText(filePath);
            string friendsOnlyVal = friendsOnly ? "true" : "false";

            content = Regex.Replace(content, @"""isfriendsonly""\s*:\s*(true|false)", "\"isfriendsonly\": " + friendsOnlyVal, RegexOptions.IgnoreCase);
            content = Regex.Replace(content, @"""networkpassword""\s*:\s*""[^""]*""", "\"networkpassword\": \"" + EscapeJson(password) + "\"");
            content = Regex.Replace(content, @"""playername""\s*:\s*""[^""]*""", "\"playername\": \"" + EscapeJson(username) + "\"");

            File.WriteAllText(filePath, content);
        }

        static void SyncIniFile(string filePath, string username, string password, bool friendsOnly) {
            string finalUsername = string.IsNullOrEmpty(username.Trim()) ? "Unknown Soldier" : username;
            string friendsOnlyVal = friendsOnly ? "1" : "0";

            if (!File.Exists(filePath)) {
                File.WriteAllText(filePath, "playername=" + finalUsername + "\r\nisfriendsonly=1\r\nnetworkpassword=\r\n");
            }

            string[] lines = File.ReadAllLines(filePath);
            bool foundUser = false, foundPass = false, foundFriends = false;

            for (int i = 0; i < lines.Length; i++) {
                string trimL = lines[i].Replace(" ", "").ToLower();
                if (trimL.StartsWith("playername=")) {
                    lines[i] = "playername=" + finalUsername;
                    foundUser = true;
                } else if (trimL.StartsWith("networkpassword=")) {
                    lines[i] = "networkpassword=" + password;
                    foundPass = true;
                } else if (trimL.StartsWith("isfriendsonly=")) {
                    lines[i] = "isfriendsonly=" + friendsOnlyVal;
                    foundFriends = true;
                }
            }

            var list = new System.Collections.Generic.List<string>(lines);
            if (!foundUser) list.Add("playername=" + finalUsername);
            if (!foundPass) list.Add("networkpassword=" + password);
            if (!foundFriends) list.Add("isfriendsonly=" + friendsOnlyVal);

            File.WriteAllLines(filePath, list.ToArray());
        }
    }
}
