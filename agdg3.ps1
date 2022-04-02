param($agdgUrl)
function GetJsonFromUrl { param ($urljson)
	$sujo = Invoke-WebRequest -Uri $urljson 
	$limpo = $sujo.Content | ConvertFrom-Json
	return $limpo
}

function CreateThread { param($boardTag)
	$postURL = "$agdgUrl/post/"
	$body = @{
		tag = $boardTag
		message = "Salve"
	}
	$body.message = Read-Host "Message"
	Invoke-WebRequest -Uri $postURL -Method Post -Form $body

	PrintBoard -boardTag $boardTag
}
function ReplyThread { param ($boardTag,$postId)
	$replyUrl = "$agdgUrl/$boardTag/$postId/"
	$body = @{
		message = ""
	}
	$body.message = Read-Host "Message"
	Invoke-WebRequest -Uri $replyUrl -Method Post -Form $body

	PrintThread -boardTag $boardTag -postId $postId
}

function WriteAllWidth { param ($char,$foregroundColor)
	$size = (Get-Host).UI.RawUI.WindowSize.Width
	$output = ""
	for ($i = 0; $i -lt $size; $i++) {
		$output += $char
	}
	Write-Host $output -ForegroundColor $foregroundColor

	
}
function PrintThread { param ($boardTag,$postId)
	Clear-Host
	$url = "$agdgUrl/$boardTag/$postId/"
	$thread = GetJsonFromUrl -urljson $url 
	Write-Host $boardTag "#" $postId -BackgroundColor Red

	PrintReply -reply $thread.op
	WriteAllWidth -char "=" -foregroundColor Red

	for ($i = 0; $i -lt $thread.replies.Count; $i++) {
		PrintReply -reply $thread.replies[$i]

		WriteAllWidth -char "-" -foregroundColor Red
	}

	Write-Host " Reply thread: new | back to board: up"
	$op = Read-Host 
	if($op -eq "up")
	{
		PrintBoard -boardTag $boardTag
	}
	elseif($op -eq "new")
	{
		try {
			# CreateThread -boardTag $boardTag
			ReplyThread -boardTag $boardTag -postId $postId
		}
		catch {
			"Error."
			PrintThread -boardTag $boardTag -postId $postId
		}
	}

}
function PrintReply{ param($reply)
	Write-Host $reply.name -NoNewline -ForegroundColor Green
	Write-Host " #" $reply.id 
	Write-Host $reply.text
	
}
function PrintBoard{ param($boardTag)
	Clear-Host

	$url = "$agdgUrl/$boardTag"
	$threads = GetJsonFromUrl -urljson $url

	Write-Host $threads.topic -BackgroundColor Red
	WriteAllWidth -char "#" -foregroundColor DarkRed

	# for ($i = $threads.threads.Count - 1; $i -ge 0 ; $i--) {
	# 	PrintReply -reply $threads.threads[$i].op
	# }
	for ($i = 0; $i -lt $threads.threads.Count; $i++) {
		PrintReply -reply $threads.threads[$i].op
		Write-Host "replies:" $threads.threads[$i].replies.length -ForegroundColor DarkGray

		WriteAllWidth -char "-" -foregroundColor Red
	}
	
	Write-Host "Open thread: num | create thread: new | back to menu: up"
	$op = Read-Host 
	if($op -eq "up")
	{
		Menu
	}
	elseif($op -eq "new")
	{
		try {
			CreateThread -boardTag $boardTag
		}
		catch {
			"Error."
			PrintBoard -boardTag $boardTag
		}
	}
	else {
		try {
			PrintThread -boardTag $boardTag -postId $op
		}
		catch {
			"Error."
			PrintBoard -boardTag $boardTag
		}
	}
}
function Overboard { 
	$j = GetJsonFromUrl -urljson $agdgUrl
	foreach($board in $j)
	{
		Write-Host $board.name "|" $board.topic
	}
}
function Menu {
	Clear-Host
	Write-Host "Welcome to agdg3-cli" -BackgroundColor Red
	Overboard
	# Write-Host "ex: art"
	$op = Read-Host "Select a board"
	try {
		PrintBoard -boardTag $op
	}
	catch {
		Write-Host "Wrong option."
		Menu
	}
	
}

try {
	Menu
}
catch {
	Write-Host "Wrong url. Did you forget to add '/agdg' ?" -ForegroundColor Red
	Write-Host "example url: https://localhost:7077/agdg"
}
