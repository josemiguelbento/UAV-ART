extends RichTextLabel
# Este script exibe os novos números spawnados

var aux1 #salva o ultimo valor do contM
var aux2 #salva o ultimo valor do contN

func _ready():
	aux1 = SpawnerNumAs.contM1
	aux2 = SpawnerNumAs.contN1
func _process(delta): 
	if float(global.array2[9]) * 10  > ( InitialAlt.pinit * 10 + 9 * 10):
		var dialog = str(InitialAlt.pinit * 10 + aux1 * 10 + 10)
		set_visible_characters(4)
		set_bbcode(dialog)
	if float(global.array2[9]) * 10 < ( InitialAlt.pinit * 10 - 4 * 10):
		var dialog = str(InitialAlt.pinit * 10 -((aux2)) * 10) 
		set_visible_characters(4)
		set_bbcode(dialog)
