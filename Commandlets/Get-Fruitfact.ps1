$MaxFruit = 6
$ID = Get-Random -Minimum 1 -Maximum $MaxFruit

Add-Type -AssemblyName System.Speech 
$Speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$Fruit = (Invoke-WebRequest https://www.fruityvice.com/api/fruit/$ID).content | ConvertFrom-Json$Speak.Speak(("Did you know this about the " + $Fruit.name + "?")) $Speak.Speak(("The "+ $Fruit.name +"'s official name is " +$Fruit.genus `    + $Fruit.family + ". It provides " +$Fruit.nutritions.calories + " Calories, In 100 Grams," `    + $Fruit.nutritions.sugar + "% is Sugar, " `    + $Fruit.nutritions.carbohydrates + "% are carbohydrates, " `    + $Fruit.nutritions.Fat + "% is fat and it has "`    + $Fruit.nutritions.protein + "% worth of Proteins."))