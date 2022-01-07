###############################################################################
# Function POP3User
#
# POP's the users mailbox and returns the size of the Inbox in Bytes
#
# Pass the POP Server IP, Username and Password
###############################################################################
#$servername = $args[0]
#$username = $args[1] 
#$password = $args[2]


$servername = "mail.domain.nl"
$username = "ba@sfdsdf"
$password = "!"


POP3User

function POP3User([string] $ServerName, [string] $UserName, [string] $Password) {	
	function readResponse {
		$strStream = ""
		while ($stream.DataAvailable) {  
			$read = $stream.Read($buffer, 0, 1024)    
			$strStream += ($encoding.GetString($buffer, 0, $read))  
		} 
		return $strStream
	}

	$port = 110 

	try {
		$socket = new-object System.Net.Sockets.TcpClient($ServerName, $port) 
	}
	catch {
		return "ERRORRRR"
	}

	$stream = $socket.GetStream() 
	$writer = new-object System.IO.StreamWriter($stream) 
	$buffer = new-object System.Byte[] 1024 
	$encoding = new-object System.Text.AsciiEncoding 
	$strStream = readResponse($stream)

	$command = "USER $UserName"
	$writer.WriteLine($command) 
	$writer.Flush()
	$strStream += readResponse($stream)


	$command = "PASS $Password"
	$writer.WriteLine($command) 
	$writer.Flush()
	$strStream += readResponse($stream)

	$command = "STAT" 
	$writer.WriteLine($command) 
	$writer.Flush()
	$strStream += readResponse($stream)

	$command = "QUIT" 
	$writer.WriteLine($command) 
	$writer.Flush()

	$strStream += readResponse($stream)

	$loop = 0;

	while ( !($strStream.contains("signing off")) -and ($loop -lt 101) ) {
		start-sleep -m  50
		
		$strStream += readResponse($stream)
		$loop++

		if ($loop -eq 100) {
			Write-LogFile $logFile "`tERROR: Could not POP User - TIMEOUT"

			## Close the streams 	
			$writer.Close() 
			$stream.Close() 

			return "ERROtttttR"
		}
	} 
	
	## Close the streams 	
	$writer.Close() 
	$stream.Close() 

	if ($strStream.contains("-ERR")) {
		return "Could not POP User - Usually Auth Error"
	}
	else {
		$arrStream = $strStream.split("`n")

		#Messages: $arrStream[3].split(" ")[1]
		#Size (B): $arrStream[3].split(" ")[2]
		
		#Return inbox size
		return $arrStream[3].split(" ")[2]
	}

}