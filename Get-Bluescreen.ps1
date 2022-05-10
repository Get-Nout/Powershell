
. '\\ithost.local\ithost$\techdata\Scripts\Commandlets\New-WPFMessageBox.ps1'

Add-Type -AssemblyName presentationframework, presentationcore

$Source = "https://i.imgur.com/igf204x.png"
$Image = New-Object System.Windows.Controls.Image
$Image.Source = $Source
$Image.Height = 201 /2
$Image.Width = 321 /2
  
$StackPanel = New-Object System.Windows.Controls.StackPanel
$StackPanel.AddChild($Image)


$TextBlock = New-Object System.Windows.Controls.Label
$TextBlock.Content = "
This PC ran into a problem!

Have you tried turning it off and on again?

0x80051337"

$TextBlock.FontSize = "18"
$TextBlock.HorizontalAlignment = "Center"
$TextBlock.FontFamily = 'Verdana'
$TextBlock.Foreground = 'white'
$StackPanel.AddChild($TextBlock)
$StackPanel.Margin = "10,0,10,0"

New-WPFMessageBox $StackPanel `
    -Title ":(" -TitleBackground "SteelBlue" -TitleFontSize 80 -TitleTextForeground "White"`
    -ContentBackground "SteelBlue" -ContentTextForeground "White"  `
    -ButtonType OK -ButtonTextForeground 'White'