on run
    repeat
        set robloxStatus to "Roblox Not Found"
        try
            do shell script "pgrep -x RobloxPlayer"
            set robloxStatus to "Roblox Detected"
        end try
        
        -- The UI with the X button (Cancel button)
        tell application "System Events"
            set dialogResult to display dialog "Status: " & robloxStatus & return & return & "Paste your script below:" default answer "require(14168421377).tyymenu(\"Tyuiss_RBLX\")" buttons {"X", "Clear", "Execute"} default button "Execute" cancel button "X" with icon note with title "Bozo Executer"
        end tell
        
        set buttonPressed to button returned of dialogResult
        
        if buttonPressed is "X" then
            exit repeat
        end if
        
        if buttonPressed is "Execute" then
            set userScript to text returned of dialogResult
            try
                do shell script "echo " & quoted form of userScript & " | nc -w 1 127.0.0.1 5599 &"
                display dialog "Executed successfully!" buttons {"OK"} default button "OK" with icon note
            on error errMsg
                display dialog "Connection failed. Is Roblox injected?" buttons {"OK"} default button "OK" with icon stop
            end try
        end if
        
        delay 5
    end repeat
end run
