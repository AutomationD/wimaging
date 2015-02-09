. '..\_config.ps1'

$file_name = $(Join-Path $env:TEMP 'wuinstall.zip')
$user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.95 Safari/537.36'
$accept_content = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
$accept_encoding = 'gzip, deflate, sdch'
$url = 'http://www.wuinstall.com/index.php/component/wuinstallcalc/?Itemid=108'
$url_download = 'http://license.wuinstall.com/trial.php'



[net.httpWebRequest] $req = [net.webRequest]::create($url)
$req.method = "GET"
$req.Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
$req.UserAgent = $user_agent

$req.AllowAutoRedirect = $true
$req.TimeOut = 50000
$req.KeepAlive = $true
$req.Headers.Add("Keep-Alive: 300");

[net.httpWebResponse] $res = $req.getResponse()
$resst = $res.getResponseStream()
$sr = new-object IO.StreamReader($resst)
$result = $sr.ReadToEnd()
$res.close()
$cookies = $res.Headers['Set-Cookie']


$web = new-object net.webclient
#Write-Host $cookies
$web.Headers.add("Cookie", $cookies)
$web.Headers.add("Accept", $accept_content)
$web.Headers.add("User-Agent",$user_agent)
$web.Headers.Add("Referrer",$url)
$web.Headers.Add("Accept-Encoding", $accept_encoding)


$web.DownloadFile($url_download, $file_name)

$command = "& ""$sevenZip""" + " e " + $file_name + " -o" + $utilsRoot + " -y"
Invoke-Expression $command

Write-Host "Deleting $file_name"
Remove-Item $file_name -confirm:$false

