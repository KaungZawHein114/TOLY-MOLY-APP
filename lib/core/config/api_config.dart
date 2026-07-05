//   Android emulator  →  http://10.0.2.2:8000
//   iOS simulator     →  http://127.0.0.1:8000
//   Physical phone    →  http://<your PC's LAN IP>:8000
//                        (run `ipconfig` on Windows, `ifconfig` on Mac/Linux)
//                        Phone and PC must be on the same Wi-Fi network.
//                        First-time Windows setup: open PowerShell as Admin and run:
//                        netsh advfirewall firewall add rule name="Django Dev" dir=in action=allow protocol=TCP localport=8000

const String apiBaseUrl = "http://10.0.2.2:8000";