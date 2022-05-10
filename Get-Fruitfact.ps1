﻿$MaxFruit = 6
$ID = Get-Random -Minimum 1 -Maximum $MaxFruit

Add-Type -AssemblyName System.Speech 
$Speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$Fruit = (Invoke-WebRequest https://www.fruityvice.com/api/fruit/$ID).content | ConvertFrom-Json