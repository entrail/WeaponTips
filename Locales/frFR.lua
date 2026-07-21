local ADDON_NAME, ns = ...
if GetLocale() ~= "frFR" then return end
local L = ns.L

L["You can use this weapon (%d/%d)."] = "Vous pouvez utiliser cette arme (%d/%d)."
L["Can be trained in: %s"] = "Peut être appris à : %s"
L["Training cost: %s"] = "Coût d'entraînement : %s"
L["Training cost: %s (from level %d)"] = "Coût d'entraînement : %s (à partir du niveau %d)"
L["Requires the shaman talent 'Two-Handed Axes and Maces'."] = "Nécessite le talent de chaman « Haches et masses à deux mains »."
L["Your class cannot use this type of weapon."] = "Votre classe ne peut pas utiliser ce type d'arme."

L["Weapon Tooltips"] = "Info-bulles d'armes"
L["Show usable weapons"] = "Afficher les armes utilisables"
L["Green line when you already have the weapon skill, including your current and maximum skill level."] = "Ligne verte quand vous possédez déjà la compétence d'arme, avec votre niveau actuel et maximum."
L["Show trainable weapons"] = "Afficher les armes apprenables"
L["Yellow line when your class can learn this weapon type but has not yet, listing the cities with a weapon master that teaches it."] = "Ligne jaune quand votre classe peut apprendre ce type d'arme mais ne le maîtrise pas encore, avec les villes dont le maître d'armes l'enseigne."
L["Show unusable weapons"] = "Afficher les armes inutilisables"
L["Red line when your class can never use this weapon type."] = "Ligne rouge quand votre classe ne pourra jamais utiliser ce type d'arme."
