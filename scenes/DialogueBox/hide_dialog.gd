extends RichTextLabel
@onready var dialog_icon_berries: TextureRect = $"../DialogIconBerries"
@onready var dialog_icon_lantern: TextureRect = $"../DialogIconLantern"
@onready var dialog_icon_book: TextureRect = $"../DialogIconBook"
@onready var dialog_icon_sword: TextureRect = $"../DialogIconSword"
@onready var dialog_icon_wreckage: TextureRect = $"../DialogIconWreckage"
@onready var dialog_icon_skull: TextureRect = $"../DialogIconSkull"
@onready var dialog_icon_pillow: TextureRect = $"../DialogIconPillow"
@onready var dialog_icon_tea_pot: TextureRect = $"../DialogIconTeaPot"
@onready var dialog_icon_tap: TextureRect = $"../DialogIconTap"
@onready var dialog_icon_doll: TextureRect = $"../DialogIconDoll"

func _process(_delta) ->void:
	if text.is_empty():
		hide()
	else:
		show()
	
	if get_tree().paused:
		##BOOK
		var book1 = "Long before we Shadowtail stormed this fortress, had I wished to visit here. The Great King of the Pawsticks had uncovered one of the manuals of the ancient world. A book that explained the inner workings of the mechanisms in this place which divert, and clean the water."
		var book2 = "It is a great regret of my life that my only journey into this place was to be struck down by the defilement of its original purpose. *Dismantling the brick work to expose the earth and form deadly pits.* What a grotesque use of such a technical feat that this structure once was."
		var book3 = "I cannot read the book now, but my connection to the longing for its knowledge will have turned it into an Artifact, and it will unlock the Spirit Cage doors of any of the ghosts herein."
		if (text == book1 || text == book2 || text == book3):
			dialog_icon_book.show()
		else:
			dialog_icon_book.hide()
			
		##BERRIES
		var berries1 = "It is an ingulgeance... to even speak of this, I yearn to hide my face in shame. But the Bantombolds, the fiercome Racoon warriors you see patrolling these halls. They have the best snacks."
		var berries2 = "I had not tasted berries this good in my entire lifetime. The Chipmunks -the Burrowbrood Chipmunk clan, used to keep us all in great fruits every year. But nothing a Burrowbrood produced was ever half as good as these berries..."
		var berries3 = "Bring a handful of berries to any ghost, and it will unlock a Spirit Cage door."
		if (text == berries1 || text == berries2 || text == berries3):
			dialog_icon_berries.show()
		else:
			dialog_icon_berries.hide()
			
		##LANTERN
		var lantern1 = "In this dungeon you will find many lanterns which you can use to your advantage. They will help you cross chasms (by whipping your tail at them) and putting out the lanterns with your shuriken will make you harder to spot."
		var lantern2 = "But should you find a cracked lantern -not a lantern affixed to the ground, but a belt lantern, designed to be worn for portable light- should you find my broken belt lantern, it will open a Spirit Cage door."
		if (text == lantern1 || text == lantern2):
			dialog_icon_lantern.show()
		else:
			dialog_icon_lantern.hide()
			
		##SWORD
		var sword1 = "GET IT! GET MY SWORD BACK!"
		var sword2 = "IT WAS A NICE SWORD!!!!"
		if (text == sword1 || text == sword2):
			dialog_icon_sword.show()
		else:
			dialog_icon_sword.hide()
		
		##SKULL
		var skull1 = "SOMEONE other than the Shadowtail HAVE TO HAVE DIED IN THIS PLACE IT IS SOOOO DEADLY!!!"
		var skull2 = "If you can find an intact skull of any of our enemies who perished in this place... yes... that would bring me MUCH peace......."
		if (text == skull1 || text == skull2):
			dialog_icon_skull.show()
		else:
			dialog_icon_skull.hide()
		
		##WRECKAGE
		var wreckage1 = "I DIED MESSING UP ONE OF THEIR TRAPS AHAHAHAHA! TAKE THAT YOU FINAL AQUEDUCT!! I RUINED YOU!!"
		var wreckage2 = "YOU MIGHT HAVE KILLED ME BUT I BROKE YOU FIRST!!! AHAHAHAHAHAHA!"
		var wreckage3 = "Find it."
		var wreckage4 = "Find the wreckage I created."
		var wreckage5 = "It is a great trophy to us now."
		if (text == wreckage1 || text == wreckage2 || text == wreckage3 || text == wreckage4 || text == wreckage5):
			dialog_icon_wreckage.show()
		else:
			dialog_icon_wreckage.hide()
			
		##TEAPOT
		var tea_pot1 = "For generations, the Chipmunks took great care of us woodland folk. -And we needed their help! Without a strong, sturdy structure like the one we're standing in, the winters are hard."
		var tea_pot2 = "-I just realized! You're the only one of us who is standing! Ho ho!"
		var tea_pot3 = "Anyhow! The Burrowbrood clan of Chipmunks toiled to provide us great feasts, in winter even! Can you believe that? We took them for granted..."
		var tea_pot4 = "I don't know which of them turned on us. But I know I'd have done things differently if I'd known how upset the Chipmunks had become. They call themselves Dartmunks now... Watch out for -you guessed it! Their DARTS! Ho ho! Took one to the side. Then another."
		var tea_pot5 = "They're powerful if you let them get on top of you."
		var tea_pot6 = "...Somewhere in this maze that the rodent clans lived in, I am so sure I saw one of those old Burrowbrood tea pots, from before... From a... From a happier time. What a nice tea pot it was..."
		if (text == tea_pot1 || text == tea_pot2 || text == tea_pot3 || text == tea_pot4 || text == tea_pot5 || text == tea_pot6):
			dialog_icon_tea_pot.show()
		else:
			dialog_icon_tea_pot.hide()
		
		##TAP
		var tap1 = "I've seen hints that before this place was turned into a fortress for the rodent folk to live in, the Ancients took great care in making this place beautiful."
		var tap2 = "Somewhere in here is one of their old water spouts - but it's not like a tap that you or I might make. This has decorations along it and two wings on top. The Ancients seemed to think even a water tap was worth making artfully. I admire that."
		if (text == tap1 || text == tap2):
			dialog_icon_tap.show()
		else:
			dialog_icon_tap.hide()
		
		##PILLOW
		var pillow1 = "The Rat king of the Pawsticks once sat on a VERY comfortable looking throne."
		var pillow2 = "The Chipmunks threw out all of the old reminders of the Pawsticks' opulence when they took over."
		var pillow3 = "But Shadowtail, I believe one of those comfy cushions... might just be around here still. I know that I cannot feel pain anymore, so I can't benefit from that cushion... but it sure seems a shame to let such a comfy pillow go to waste!"
		if (text == pillow1 || text == pillow2 || text == pillow3):
			dialog_icon_pillow.show()
		else:
			dialog_icon_pillow.hide()
			
		##DOLL
		var doll1 = "I heard one of the guards saying that they got a shipment OF RATRICK DOLLS!! Can you believe it?? A real Ratrick doll somewhere in this place... Wow..."
		if text == doll1:
			dialog_icon_doll.show()
		else:
			dialog_icon_doll.hide()
			
